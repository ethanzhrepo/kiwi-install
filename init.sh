#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1"
}

print_success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"
}

print_warning() {
    printf "${YELLOW}[WARNING]${NC} %s\n" "$1"
}

print_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

# Function to read password securely
read_password() {
    local prompt="$1"
    local password
    printf "%s" "$prompt"
    read -s password
    echo
    echo "$password"
}

# Function to validate RSA public key format
validate_rsa_public_key() {
    local key="$1"
    # Check if it starts with -----BEGIN PUBLIC KEY----- or -----BEGIN RSA PUBLIC KEY-----
    if [[ "$key" =~ ^-----BEGIN\ (RSA\ )?PUBLIC\ KEY----- ]] && [[ "$key" =~ -----END\ (RSA\ )?PUBLIC\ KEY-----$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to test database connection
test_database() {
    local host="$1"
    local port="$2"
    local user="$3"
    local password="$4"
    
    print_info "Testing database connection..."
    if command -v mysql &> /dev/null; then
        if mysql -h "$host" -P "$port" -u "$user" -p"$password" -e "SELECT 1;" &> /dev/null; then
            print_success "Database connection successful"
            return 0
        else
            print_error "Database connection failed"
            return 1
        fi
    else
        print_warning "MySQL client not found, skipping database connection test"
        return 0
    fi
}

# Function to test Redis connection
test_redis() {
    local host="$1"
    local port="$2"
    local user="$3"
    local password="$4"
    
    print_info "Testing Redis connection..."
    if command -v redis-cli &> /dev/null; then
        local cmd="redis-cli -h $host -p $port"
        if [[ -n "$user" ]]; then
            cmd="$cmd --user $user"
        fi
        if [[ -n "$password" ]]; then
            cmd="$cmd -a $password"
        fi
        
        if $cmd ping &> /dev/null; then
            print_success "Redis connection successful"
            return 0
        else
            print_error "Redis connection failed"
            return 1
        fi
    else
        print_warning "Redis CLI not found, skipping Redis connection test"
        return 0
    fi
}

# Display Kiwi ASCII logo and system introduction
display_intro() {
    clear
    printf "${GREEN}"
    cat << "EOF"
    ██╗  ██╗██╗██╗    ██╗██╗    ██████╗  █████╗ ██╗   ██╗███╗   ███╗███████╗███╗   ██╗████████╗
    ██║ ██╔╝██║██║    ██║██║    ██╔══██╗██╔══██╗╚██╗ ██╔╝████╗ ████║██╔════╝████╗  ██║╚══██╔══╝
    █████╔╝ ██║██║ █╗ ██║██║    ██████╔╝███████║ ╚████╔╝ ██╔████╔██║█████╗  ██╔██╗ ██║   ██║   
    ██╔═██╗ ██║██║███╗██║██║    ██╔═══╝ ██╔══██║  ╚██╔╝  ██║╚██╔╝██║██╔══╝  ██║╚██╗██║   ██║   
    ██║  ██╗██║╚███╔███╔╝██║    ██║     ██║  ██║   ██║   ██║ ╚═╝ ██║███████╗██║ ╚████║   ██║   
    ╚═╝  ╚═╝╚═╝ ╚══╝╚══╝ ╚═╝    ╚═╝     ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝   
EOF
    printf "${NC}"
    echo
    print_info "Welcome to Kiwi Payment System Installation Script"
    echo
}

# Handle EVM Pull Payment contract address
handle_contract_address() {
    echo
    print_info "=== EVM Pull Payment Contract Configuration ==="
    while true; do
        printf "Do you already have an EVM Pull Payment contract address? (y/n): "
        read -r has_contract
        case $has_contract in
            [Yy]*)
                printf "Please enter the contract address: "
                read -r contract_address
                if [[ -n "$contract_address" ]]; then
                    print_success "Contract address set: $contract_address"
                    export PULL_PAYMENT_CONTRACT_ADDRESS="$contract_address"
                    
                    # Handle contract signature
                    echo
                    print_info "=== Contract Signature Configuration ==="
                    print_info "You need to provide the RSA digital signature of the contract address"
                    print_info "This signature should be signed with the admin private key"
                    print_info "You can generate this signature using the CLI command:"
                    printf "${GREEN}go run main.go admin rsa-sign -d ${contract_address} -p google --encrypted-private-key-file /kiwi/admin.private.pem.encrypted.json${NC}\n"
                    echo
                    
                    while true; do
                        printf "Please enter the contract signature: "
                        read -r contract_signature
                        if [[ -n "$contract_signature" ]]; then
                            print_success "Contract signature set"
                            export SUBSCRIBE_CHARGE_CONTRACT_SIGNATURE="$contract_signature"
                            break
                        else
                            print_error "Contract signature cannot be empty"
                        fi
                    done
                    
                    break
                else
                    print_error "Contract address cannot be empty"
                fi
                ;;
            [Nn]*)
                print_info "Please run the create_pull_payment_contract.sh script to create a contract"
                print_info "After creation, please run this script again"
                exit 0
                ;;
            *)
                print_error "Please enter y or n"
                ;;
        esac
    done
}

# Function to validate private key format
validate_private_key() {
    local key="$1"
    # Remove any whitespace
    key=$(echo "$key" | tr -d '[:space:]')
    
    # Check if it's a valid hex string (64 characters for private key)
    if [[ ${#key} -eq 64 ]] && [[ "$key" =~ ^[0-9a-fA-F]+$ ]]; then
        return 0
    # Check if it starts with 0x and has 66 characters total
    elif [[ ${#key} -eq 66 ]] && [[ "$key" =~ ^0x[0-9a-fA-F]{64}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Handle casher private keys configuration
handle_casher_private_keys() {
    echo
    print_info "=== Casher Private Keys Configuration ==="
    print_info "Enter casher private keys one by one"
    
    CASHER_PRIVATE_KEYS=()
    key_count=0
    
    while true; do
        key_count=$((key_count + 1))
        
        # Input private key with validation loop
        while true; do
            printf "${BLUE}Casher #${key_count}:${NC} "
            casher_key=$(read_password "" | tr -d '\n')
            
            if [[ -n "$casher_key" ]]; then
                # Clean the key by removing any whitespace
                casher_key=$(echo "$casher_key" | tr -d '[:space:]')
                if validate_private_key "$casher_key"; then
                    CASHER_PRIVATE_KEYS+=("$casher_key")
                    print_success "Added casher private key #${key_count}"
                    break
                else
                    print_error "Invalid private key format. Please enter a valid 64-character hex string (with or without 0x prefix)"
                fi
            else
                print_error "Private key cannot be empty. Please enter a valid private key"
            fi
        done
        
        # Ask if user wants to continue
        printf "Do you want to add another casher private key? (Y/n): "
        read -r continue_input
        continue_input=${continue_input:-Y}
        
        case $continue_input in
            [Yy]*|"")
                continue
                ;;
            [Nn]*)
                break
                ;;
            *)
                print_error "Please enter Y or n"
                key_count=$((key_count - 1))  # Adjust count to retry this question
                ;;
        esac
    done
    
    if [[ ${#CASHER_PRIVATE_KEYS[@]} -eq 0 ]]; then
        print_warning "No casher private keys entered. Continuing with empty configuration."
    else
        print_success "Configured ${#CASHER_PRIVATE_KEYS[@]} casher private key(s)"
    fi
    
    export CASHER_PRIVATE_KEYS
}

# Function to verify RSA signature
verify_signature() {
    local contract_address="$1"
    local signature="$2"
    local public_key_file="$3"
    
    # Create temporary files for verification
    local temp_data=$(mktemp)
    local temp_sig=$(mktemp)
    
    # Write contract address to temp file
    echo -n "$contract_address" > "$temp_data"
    
    # Decode base64 signature and write to temp file
    echo "$signature" | base64 -d > "$temp_sig" 2>/dev/null
    
    # Verify signature using openssl
    if openssl dgst -sha256 -verify "$public_key_file" -signature "$temp_sig" "$temp_data" >/dev/null 2>&1; then
        rm -f "$temp_data" "$temp_sig"
        return 0
    else
        rm -f "$temp_data" "$temp_sig"
        return 1
    fi
}

# Handle CLI and admin key pairs
handle_key_pairs() {
    echo
    print_info "=== Key Pair Configuration ==="
    while true; do
        printf "Have you created CLI and Admin key pairs in the admin client? (y/n): "
        read -r has_keys
        case $has_keys in
            [Yy]*)
                # Get CLI public key
                while true; do
                    echo "Please enter the CLI public key (paste the complete PEM format key):"
                    echo "Press Enter on empty line when done:"
                    cli_public_key=""
                    while IFS= read -r line; do
                        if [[ -z "$line" ]]; then
                            break
                        fi
                        cli_public_key+="$line"$'\n'
                    done
                    
                    # Remove trailing newline
                    cli_public_key="${cli_public_key%$'\n'}"
                    
                    if validate_rsa_public_key "$cli_public_key"; then
                        print_success "CLI public key format is valid"
                        export CLI_PUBLIC_KEY="$cli_public_key"
                        break
                    else
                        print_error "Invalid CLI public key format. Please enter a valid PEM format RSA public key"
                    fi
                done
                
                # Get Admin public key
                while true; do
                    echo "Please enter the Admin public key (paste the complete PEM format key):"
                    echo "Press Enter on empty line when done:"
                    admin_public_key=""
                    while IFS= read -r line; do
                        if [[ -z "$line" ]]; then
                            break
                        fi
                        admin_public_key+="$line"$'\n'
                    done
                    
                    # Remove trailing newline
                    admin_public_key="${admin_public_key%$'\n'}"
                    
                    if validate_rsa_public_key "$admin_public_key"; then
                        print_success "Admin public key format is valid"
                        export ADMIN_PUBLIC_KEY="$admin_public_key"
                        break
                    else
                        print_error "Invalid Admin public key format. Please enter a valid PEM format RSA public key"
                    fi
                done
                
                print_success "Key pairs configured successfully"
                break
                ;;
            [Nn]*)
                print_info "Please first create key pairs in the client:"
                print_info "  - CLI key pair: cli admin generate-cli-rsa"
                print_info "  - Admin key pair: cli admin generate-admin-rsa"
                print_info "After creation, please run this script again"
                exit 0
                ;;
            *)
                print_error "Please enter y or n"
                ;;
        esac
    done
}

# Handle environment selection
handle_environment() {
    echo
    print_info "=== Environment Selection ==="
    while true; do
        echo "Please select the installation environment:"
        echo "1) Production Environment (API Server only)"
        echo "2) Demo Test Environment (API Server with embedded database)"
        printf "Please choose (1-2): "
        read -r env_choice
        
        case $env_choice in
            1)
                print_info "Production environment selected"
                export ENVIRONMENT="production"
                break
                ;;
            2)
                print_info "Demo test environment selected"
                export ENVIRONMENT="demo"
                break
                ;;
            *)
                print_error "Please enter a valid option (1-2)"
                ;;
        esac
    done
}

# Configure database for production
configure_database() {
    echo
    print_info "=== Database Configuration ==="
    
    while true; do
        printf "Database host (default: localhost): "
        read -r db_host
        db_host=${db_host:-localhost}
        
        printf "Database port (default: 3306): "
        read -r db_port
        db_port=${db_port:-3306}
        
        printf "Database username: "
        read -r db_user
        
        printf "Database name: "
        read -r db_name
        
        db_password=$(read_password "Database password: ")
        
        if [[ -n "$db_user" && -n "$db_password" && -n "$db_name" ]]; then
            export DB_HOST="$db_host"
            export DB_PORT="$db_port"
            export DB_USER="$db_user"
            export DB_NAME="$db_name"
            export DB_PASSWORD="$db_password"
            
            printf "Test database connection? (y/n): "
            read -r test_db
            case $test_db in
                [Yy]*)
                    if test_database "$db_host" "$db_port" "$db_user" "$db_password"; then
                        break
                    else
                        print_error "Database connection failed, please re-enter configuration"
                        continue
                    fi
                    ;;
                [Nn]*)
                    print_warning "Skipping database connection test"
                    break
                    ;;
                *)
                    print_error "Please enter y or n"
                    ;;
            esac
        else
            print_error "Database username, password, and name cannot be empty"
        fi
    done
}

# Configure Redis for production
configure_redis() {
    echo
    print_info "=== Redis Configuration ==="
    
    while true; do
        printf "Redis host (default: localhost): "
        read -r redis_host
        redis_host=${redis_host:-localhost}
        
        printf "Redis port (default: 6379): "
        read -r redis_port
        redis_port=${redis_port:-6379}
        
        printf "Redis username (default empty, press Enter): "
        read -r redis_user
        
        redis_password=$(read_password "Redis password: ")
        
        export REDIS_HOST="$redis_host"
        export REDIS_PORT="$redis_port"
        export REDIS_USER="$redis_user"
        export REDIS_PASSWORD="$redis_password"
        
        printf "Test Redis connection? (y/n): "
        read -r test_redis_conn
        case $test_redis_conn in
            [Yy]*)
                if test_redis "$redis_host" "$redis_port" "$redis_user" "$redis_password"; then
                    break
                else
                    print_error "Redis connection failed, please re-enter configuration"
                    continue
                fi
                ;;
            [Nn]*)
                print_warning "Skipping Redis connection test"
                break
                ;;
            *)
                print_error "Please enter y or n"
                ;;
        esac
    done
}

# Configure Telegram bot notifications
configure_telegram() {
    echo
    print_info "=== Telegram Bot Notification Configuration ==="
    
    while true; do
        printf "Enable Telegram Bot notifications? (y/n, default: n): "
        read -r enable_telegram
        enable_telegram=${enable_telegram:-n}
        
        case $enable_telegram in
            [Yy]*)
                printf "Please enter Telegram Bot Token: "
                read -r telegram_token
                printf "Please enter Chat ID: "
                read -r telegram_chat_id
                
                if [[ -n "$telegram_token" && -n "$telegram_chat_id" ]]; then
                    export TELEGRAM_BOT_TOKEN="$telegram_token"
                    export TELEGRAM_CHAT_ID="$telegram_chat_id"
                    export TELEGRAM_ENABLED="true"
                    print_success "Telegram Bot notifications configured"
                    break
                else
                    print_error "Telegram Bot Token and Chat ID cannot be empty"
                fi
                ;;
            [Nn]*)
                print_info "Skipping Telegram Bot notification configuration"
                export TELEGRAM_ENABLED="false"
                break
                ;;
            *)
                print_error "Please enter y or n"
                ;;
        esac
    done
}

# Configure metrics monitoring
configure_metrics() {
    echo
    print_info "=== Metrics Monitoring Configuration ==="
    
    while true; do
        printf "Enable Metrics monitoring? (y/n, default: n): "
        read -r enable_metrics
        enable_metrics=${enable_metrics:-n}
        
        case $enable_metrics in
            [Yy]*)
                printf "Metrics port (default: 9090): "
                read -r metrics_port
                metrics_port=${metrics_port:-9090}
                
                printf "Metrics path (default: /metrics): "
                read -r metrics_path
                metrics_path=${metrics_path:-/metrics}
                
                export METRICS_PORT="$metrics_port"
                export METRICS_PATH="$metrics_path"
                export METRICS_ENABLED="true"
                print_success "Metrics monitoring configured"
                break
                ;;
            [Nn]*)
                print_info "Skipping Metrics monitoring configuration"
                export METRICS_ENABLED="false"
                break
                ;;
            *)
                print_error "Please enter y or n"
                ;;
        esac
    done
}

# Create .config directory and key files
create_config_directory() {
    print_info "Creating .config directory and key files..."
    
    # Create .config directory
    mkdir -p .config
    
    # Save CLI public key
    printf "%s" "$CLI_PUBLIC_KEY" > .config/cli.pub.pem
    print_success "CLI public key saved to .config/cli.pub.pem"
    
    # Save Admin public key
    printf "%s" "$ADMIN_PUBLIC_KEY" > .config/sign.pub.pem
    print_success "Admin public key saved to .config/sign.pub.pem"
}

# Generate YAML configuration file
generate_config() {
    echo
    print_info "=== Generating Configuration Files ==="
    
    # Create .config directory if it doesn't exist
    mkdir -p .config
    
    # Generate config.yml
    cat > .config/config.yml << EOF
# API Configuration
api:
  port: 8090
  host: "0.0.0.0"

EOF

    # Add database configuration for production environment
    if [[ "$ENVIRONMENT" == "production" ]]; then
        cat >> .config/config.yml << EOF
# Database Configuration
database:
  type: "mysql"
  url: "${DB_USER}:${DB_PASSWORD}@tcp(${DB_HOST}:${DB_PORT})/${DB_NAME}?charset=utf8mb4&parseTime=True&loc=Local"
  show_sql: false
  max_idle_conns: 10
  max_open_conns: 100
  conn_max_lifetime: "1h"
  conn_max_idle_time: "5m"
  auto_migrate: true

# Cache Configuration
cache:
  type: "redis"
  redis:
    host: "${REDIS_HOST}"
    port: ${REDIS_PORT}
    username: "${REDIS_USER}"
    password: "${REDIS_PASSWORD}"
    key_prefix: "kiwi_redis"
    database: 0
    max_retries: 3
    pool_size: 10

EOF
    fi

    # Add blockchain configuration
    cat >> .config/config.yml << EOF
# Blockchain Configuration
blockchain:
  chain_config_file: "./.config/evm_chains.json"
  evm_multicall: "0xbBc913B5027C87738524881E17D4D1bF6d5E1078"
  use_ethrpcx: true
  subscribe_charge_contract: "${PULL_PAYMENT_CONTRACT_ADDRESS}"
  subscribe_charge_contract_signature: "${SUBSCRIBE_CHARGE_CONTRACT_SIGNATURE}"
  debug_charge_address: false
  reconnect_from_cache_enabled: true
  max_reconnect_block_gap: 1000

# Subscription Payment Configuration
subscription:
  casher_private_keys:
EOF

    # Add casher private keys to the configuration
    if [[ ${#CASHER_PRIVATE_KEYS[@]} -gt 0 ]]; then
        for key in "${CASHER_PRIVATE_KEYS[@]}"; do
            echo "    - \"$key\"" >> .config/config.yml
        done
    else
        echo "    []" >> .config/config.yml
    fi
    
    cat >> .config/config.yml << EOF

# Security Configuration
security:
  admin_sign_public_key_pem: "/app/config/sign.pub.pem"
  admin_cli_public_key_pem: "/app/config/cli.pub.pem"

EOF

    # Add Telegram configuration
    cat >> .config/config.yml << EOF
# Telegram Bot Configuration
telegram:
  enabled: ${TELEGRAM_ENABLED}
EOF

    if [[ "$TELEGRAM_ENABLED" == "true" ]]; then
        cat >> .config/config.yml << EOF
  bot_token: "${TELEGRAM_BOT_TOKEN}"
  admin_group_chat_id: ${TELEGRAM_CHAT_ID}
  deposit_webhook: ""
  panic_webhook: ""
EOF
    fi

    # Add transaction signer configuration
    cat >> .config/config.yml << EOF

# Transaction Signer Configuration
transaction_signer:
  lock_timeout_seconds: 30
  queue_pop_timeout_seconds: 10
  gas_limit_default: 21000
  gas_price_buffer_percent: 10

# Logging Configuration
logging:
  level: "info"
  format: "text"
  output: "stdout"
  color: true
  service_name: "kiwi-api"
  service_version: "1.0.0"

# Node ID Configuration
node_id:
  strategy: "auto"
  use_hostname: true
  use_pod_name: false
  use_container: false

EOF

    # Add metrics configuration
    cat >> .config/config.yml << EOF
# Metrics Configuration
metrics:
  enabled: ${METRICS_ENABLED}
EOF

    if [[ "$METRICS_ENABLED" == "true" ]]; then
        cat >> .config/config.yml << EOF
  port: "${METRICS_PORT}"
  path: "${METRICS_PATH}"
EOF
    fi

    # Add jobs and workers configuration
    cat >> .config/config.yml << EOF

# Scheduled Jobs Configuration
jobs:
  # Notification processing job
  notify_job:
    enabled: true
    schedule: "*/30 * * * * *"  # Every 30 seconds
    batch_size: 100
    max_retries: 9
    retry_durations: 
      - "1m"
      - "5m" 
      - "10m"
      - "30m"
      - "1h"
      - "1h"
      - "1h"
      - "1h"
      - "1h"
    max_retry_duration: "24h"
  
  # Subscription charge balance job
  subscribe_charge_balance_job:
    enabled: true
    schedule: "0 0 */1 * * *"  # Every hour
  
  # Subscription charge onchain job  
  subscribe_charge_onchain_job:
    enabled: true
    schedule: "0 30 */1 * * *"  # Every hour 30 minutes
  
  # Subscription reset status job
  subscribe_reset_status_job:
    enabled: true
    schedule: "0 0 */4 * * *"  # Every 4 hours
  
  # Subscription handle overdue job
  subscribe_handle_over_due_job:
    enabled: true
    schedule: "0 */30 * * * *"  # Every 30 minutes
  
  # Deposit confirmation job
  deposit_confirm_job:
    enabled: true
    schedule: "*/10 * * * * *"  # Every 10 seconds
  
  # Payment check job
  payment_check_job:
    enabled: true
    schedule: "0 */5 * * * *"   # Every 5 minutes
  
  # Event recovery job  
  event_recovery_job:
    enabled: true
    schedule: "0 */30 * * * *"  # Every 30 minutes

# Worker Configuration
workers:
  # Notification worker
  notify_worker:
    enabled: true
    max_concurrent: 20
  
  # Payment subscriber worker
  payment_worker:
    enabled: true
  
  # Persistent event worker
  persistent_event_worker:
    enabled: true
    processing_delay: "5s"  # Process every 5 seconds
  
  # Telegram workers
  telegram_deposit_worker:
    enabled: true
  
  telegram_panic_worker:
    enabled: true
EOF

    print_success "Configuration file .config/config.yml has been generated"
    
    # Ask user if they want to verify the signature
    echo
    print_info "=== Signature Verification ==="
    printf "Do you want to verify the contract signature? (y/n, default: y): "
    read -r verify_sig
    verify_sig=${verify_sig:-y}
    
    case $verify_sig in
        [Yy]*)
            print_info "Verifying contract signature..."
            if verify_signature "$PULL_PAYMENT_CONTRACT_ADDRESS" "$SUBSCRIBE_CHARGE_CONTRACT_SIGNATURE" ".config/sign.pub.pem"; then
                print_success "✓ Contract signature verification passed"
            else
                print_error "✗ Contract signature verification failed"
                print_warning "Please check:"
                print_warning "1. The contract address is correct"
                print_warning "2. The signature was generated using the correct admin private key"
                print_warning "3. The signature is in base64 format"
                printf "Continue anyway? (y/n): "
                read -r continue_anyway
                case $continue_anyway in
                    [Yy]*)
                        print_warning "Continuing with unverified signature..."
                        ;;
                    *)
                        print_error "Setup cancelled. Please verify your signature and try again."
                        exit 1
                        ;;
                esac
            fi
            ;;
        [Nn]*)
            print_info "Skipping signature verification"
            ;;
        *)
            print_error "Please enter y or n"
            ;;
    esac
}

# Display startup instructions
display_startup_instructions() {
    echo
    print_success "=== Installation Complete ==="
    print_info "Configuration files have been saved to .config/ directory"
    print_info "Key files have been created:"
    print_info "  - .config/cli.pub.pem"
    print_info "  - .config/sign.pub.pem"
    print_info "  - .config/config.yml"
    
    echo
    print_info "=== Startup Instructions ==="
    
    if [[ "$ENVIRONMENT" == "demo" ]]; then
        print_info "To start the Demo environment, run:"
        printf "${GREEN}docker-compose -f docker-compose-demo.yml up -d${NC}\n"
    else
        print_info "To start the Production environment, run:"
        printf "${GREEN}docker-compose -f docker-compose.yml up -d${NC}\n"
    fi
    
    echo
    print_info "System initialization completed successfully!"
    print_info "Thank you for using Kiwi Payment!"
}

# Main function
main() {
    display_intro
    handle_contract_address
    handle_casher_private_keys
    handle_key_pairs
    handle_environment
    
    if [[ "$ENVIRONMENT" == "production" ]]; then
        configure_database
        configure_redis
    fi
    
    configure_telegram
    configure_metrics
    create_config_directory
    generate_config
    display_startup_instructions
}

# Run main function
main "$@"