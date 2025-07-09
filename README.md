# Kiwi Payment System

A comprehensive cryptocurrency payment processing system with subscription billing capabilities, multi-chain support, and advanced collection features.

## System Overview

The Kiwi Payment System consists of three main components:

1. **CLI Tool** - Command-line interface for system management and operations
2. **API Server** - Backend payment processing engine 
3. **Web UI** - Frontend dashboard for merchants and administrators

## Installation Guide

Follow these steps in order to set up a complete Kiwi Payment System:

### Prerequisites

- Go 1.21 or later
- Node.js 18+ and Yarn
- Docker and Docker Compose
- MySQL 8.0+ (for production)
- Redis 6.0+ (for production)
- OpenSSL (for signature verification)

---

## Step 1: CLI Installation and Setup

The CLI tool is required for system administration and key management.

### 1.1 Build and Install CLI

```bash
# Clone the repository
git clone https://github.com/ethanzhrepo/kiwi-cli.git

# Install dependencies
go mod download

# Build the CLI
go build -o kiwi-cli

# (Optional) Install to system PATH
go install
```

### 1.2 Generate RSA Key Pairs

Before setting up the server, you must generate RSA key pairs for secure communication:

```bash
# Generate CLI RSA key pair
./kiwi-cli admin generate-cli-rsa

# Generate Admin RSA key pair  
./kiwi-cli admin generate-admin-rsa
```

**Important:** Save the generated public keys - you'll need them for server configuration.

### 1.3 Generate Contract Signature

If you have an EVM Pull Payment contract, generate its signature:

```bash
# Sign the contract address with admin private key
./kiwi-cli admin rsa-sign -d <contract_address> -p google --encrypted-private-key-file /path/to/admin.private.pem.encrypted.json
```

### 1.4 Configure CLI

```bash
# Set API server URL (after server setup)
./kiwi-cli config set api https://your-api-server.com
```

---

## Step 2: Server Installation and Configuration

### 2.1 Run Installation Script

Navigate to the project root and run the interactive installation script:

```bash
cd /path/to/kiwi
chmod +x install/init.sh
./install/init.sh
```

### 2.2 Installation Process

The installation script will guide you through:

#### A. EVM Pull Payment Contract Configuration
- Enter your contract address
- Provide the RSA digital signature (generated in Step 1.3)

#### B. Casher Private Keys Configuration
- Enter private keys for payment processing
- Supports 0x-prefixed and raw hex formats
- Add multiple keys as needed

#### C. RSA Key Pair Configuration
- Paste the CLI public key (from Step 1.2)
- Paste the Admin public key (from Step 1.2)

#### D. Environment Selection
- **Production**: API server with external database/Redis
- **Demo**: All-in-one setup with embedded database

#### E. Database Configuration (Production only)
- MySQL host, port, username, database name
- Secure password input
- Optional connection testing

#### F. Redis Configuration (Production only)
- Redis host, port, username (optional)
- Secure password input
- Optional connection testing

#### G. Optional Services
- **Telegram Bot**: For system notifications
- **Metrics Monitoring**: Prometheus-compatible metrics

#### H. Signature Verification
- Automatic verification of contract signature
- Uses the admin public key for validation

### 2.3 Start the Server

After successful configuration:

**For Production Environment:**
```bash
docker-compose -f docker-compose.yml up -d
```

**For Demo Environment:**
```bash
docker-compose -f docker-compose-demo.yml up -d
```

### 2.4 Docker Image Registry

The system uses the official image registry:
- **Registry**: `ghcr.io/ethanzhrepo/kiwi-api`
- **Tags**: `latest`, version-specific tags (e.g., `v1.0.0`)
- **Architectures**: `linux/amd64`, `linux/arm64`

To build and push custom images:
```bash
cd api
make docker-build-push VERSION=v1.0.0
```

### 2.5 Verify Installation

```bash
# Check server status
./cli/kiwi-cli system ping

# View server metrics
./cli/kiwi-cli system server-status
```

---

## Step 3: Frontend Deployment

### 3.1 Local Development Setup

```bash
cd ui
yarn install
yarn dev
```

### 3.2 Configure Environment Variables

Create `ui/.env` file:

```env
VITE_APP_NAME=Kiwi Billing
VITE_APP_COPYRIGHT=kiwi.wrb.ltd
VITE_APP_CORP_NAME=kiwi.wrb.ltd
VITE_APP_API_URL=https://your-api-server.com/pub/api/v1

VITE_APP_SUPPORT_EMAIL=support@wrb.tld
VITE_APP_SUPPORT_TWITTER=@example
VITE_APP_SUPPORT_TELEGRAM=telegramname
```

### 3.3 Production Build

```bash
cd ui
yarn build
```

### 3.4 Deployment Options

#### Option A: Cloudflare Pages

1. **Fork and Connect Repository**
   - Fork this repository to your GitHub/GitLab
   - Go to Cloudflare Dashboard → Workers & Pages
   - Create application → Pages → Connect to Git

2. **Configure Build Settings**
   - **Framework preset:** React
   - **Build command:** `yarn build`
   - **Build output directory:** `dist`
   - **Root directory:** `ui`

3. **Environment Variables in Cloudflare Pages**
   Set these in the Pages project settings:
   ```
   VITE_APP_NAME=Kiwi Billing
   VITE_APP_COPYRIGHT=kiwi.wrb.ltd
   VITE_APP_CORP_NAME=kiwi.wrb.ltd
   VITE_APP_API_URL=https://your-api-server.com/pub/api/v1
   VITE_APP_SUPPORT_EMAIL=support@wrb.tld
   VITE_APP_SUPPORT_TWITTER=@example
   VITE_APP_SUPPORT_TELEGRAM=telegramname
   ```

4. **Deploy**
   - Save and Deploy
   - Automatic deployments on git push

#### Option B: Self-Hosted (Nginx)

1. **Build and Upload**
   ```bash
   yarn build
   # Copy dist/* to /var/www/your-site/
   ```

2. **Nginx Configuration**
   ```nginx
   server {
       listen 80;
       server_name your-domain.com;
       root /var/www/your-site;
       index index.html;

       location / {
           try_files $uri $uri/ /index.html;
       }
   }
   ```

3. **Restart Nginx**
   ```bash
   sudo systemctl restart nginx
   ```

---

## Step 4: Address Pool Initialization

After the server is running, you need to initialize the address pool with deposit addresses for receiving payments.

### 4.1 Understanding Address Pool

The address pool is a collection of cryptocurrency addresses that the system uses to receive payments from customers. Each address is securely generated and stored with encrypted private keys.

### 4.2 Generate Address Pool

Use the CLI to generate a batch of deposit addresses:

```bash
# Generate 100 EVM addresses using filesystem provider
./kiwi-cli wallet add -n 100 -t EVM --provider fs

# Generate with custom batch name for organization
./kiwi-cli wallet add -n 200 -t EVM --provider fs --key-name "batch_001"

# Generate using different key storage providers
./kiwi-cli wallet add -n 100 -t EVM --provider google     # Google Drive
./kiwi-cli wallet add -n 100 -t EVM --provider dropbox    # Dropbox
./kiwi-cli wallet add -n 100 -t EVM --provider keychain   # macOS Keychain
```

**Important Security Notes:**
- Private keys are encrypted with AES and stored securely
- Each AES key is encrypted with the admin RSA public key
- Keys are never stored in plain text
- The admin RSA private key is required to decrypt and use these addresses

### 4.3 Verify Address Pool

Check the status of your address pool:

```bash
# View detailed statistics
./kiwi-cli wallet stat

# Query specific addresses
./kiwi-cli wallet get -a 0x1234...

# List all batches
./kiwi-cli wallet batch list
```

### 4.4 Address Pool Management

#### Enable/Disable Individual Addresses

```bash
# Disable a specific address (won't be used for new payments)
./kiwi-cli wallet disable -a 0x1234...

# Re-enable a disabled address
./kiwi-cli wallet enable -a 0x1234...
```

#### Batch Management

```bash
# Enable all addresses in a batch
./kiwi-cli wallet enable-batch -b batch_001

# Disable all addresses in a batch
./kiwi-cli wallet disable-batch -b batch_001
```

### 4.5 Address Pool Best Practices

1. **Initial Pool Size**: Start with 100-500 addresses depending on expected transaction volume
2. **Batch Organization**: Use meaningful batch names for different purposes or time periods
3. **Regular Monitoring**: Check address pool statistics regularly
4. **Backup Strategy**: Ensure admin RSA private key is backed up securely
5. **Capacity Planning**: Add more addresses before the pool runs low

### 4.6 Storage Provider Options

The CLI supports multiple storage backends for managing keys:

- **`fs`**: Local file system (default, good for development)
- **`google`**: Google Drive (recommended for production)
- **`dropbox`**: Dropbox storage
- **`keychain`**: macOS Keychain (macOS only)

Example with Google Drive:
```bash
# First-time setup requires authentication
./kiwi-cli wallet add -n 100 -t EVM --provider google

# System will prompt for Google OAuth authentication
# Keys will be stored encrypted in your Google Drive
```

### 4.7 Address Pool Monitoring

```bash
# Check pool statistics
./kiwi-cli wallet stat

# Example output:
# Total addresses: 1000
# Available: 850
# Used: 150
# Disabled: 0
# Batches: 5
```

---

## System Management

### Wallet Management

```bash
# Add deposit addresses
./kiwi-cli wallet add -n 100 -t EVM --provider fs

# Check wallet statistics
./kiwi-cli wallet stat

# Enable/disable addresses
./kiwi-cli wallet enable -a 0x1234...
./kiwi-cli wallet disable -a 0x1234...
```

### Collection Operations

```bash
# Create collection task
./kiwi-cli collect collect-task create --threshold 0.01

# Execute collection
./kiwi-cli collect run --task-id 123 --to 0x... \
  --relayer-provider fs --relayer-file ./wallet.json \
  --encrypted-rsa-admin-key-file ./admin_rsa.pem.encrypted.json

# Gas airdrop before collection
./kiwi-cli tools airdrop --task-id 123 --provider fs --file ./wallet.json
```

### Merchant Management

```bash
# Add merchant
./kiwi-cli merchant add --name "My Store" --notify-url "https://store.com/webhook"

# List merchants
./kiwi-cli merchant list

# Reset API key
./kiwi-cli merchant reset-key --id merchant_id
```

## Configuration Files

After installation, key configuration files are located in `.config/`:

- **`config.yml`** - Main server configuration
- **`cli.pub.pem`** - CLI public key
- **`sign.pub.pem`** - Admin public key
- **`evm_chains.json`** - Blockchain network configurations
- **`evm_chains.test.sepolia.json`** - Test network configurations

**Environment Files:**
- **`.env`** - Environment variables (generated during installation)
- **`.env.example`** - Environment variable template

**Data Directories:**
- **`.data/mysql/`** - MySQL data directory
- **`.data/redis/`** - Redis data directory


## Security Considerations

1. **RSA Key Management**
   - Store private keys securely (encrypted)
   - Never commit private keys to version control
   - Use separate key pairs for different environments

2. **Database Security**
   - Use strong passwords
   - Enable SSL/TLS connections
   - Regular backups

3. **API Security**
   - Deploy behind reverse proxy with SSL
   - Use proper firewall rules
   - Monitor access logs

## Troubleshooting

### Common Issues

1. **Database Connection Failed**
   ```bash
   # Test connection manually
   mysql -h host -P port -u user -p database_name
   ```

2. **Redis Connection Failed**
   ```bash
   # Test Redis connection
   redis-cli -h host -p port ping
   ```

3. **Signature Verification Failed**
   - Verify contract address is correct
   - Check that signature was generated with correct admin private key
   - Ensure signature is in base64 format

4. **CLI Commands Fail**
   ```bash
   # Check CLI configuration
   ./kiwi-cli config list
   
   # Test server connectivity
   ./kiwi-cli system ping
   ```

## Support

- **Documentation:** Comprehensive CLI help via `./kiwi-cli --help`
- **System Status:** `./kiwi-cli system server-status`
- **Logs:** Check Docker logs with `docker-compose logs`

## License

MIT License - see individual component READMEs for details.