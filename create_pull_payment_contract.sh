#!/bin/bash

# salt 0x48da66d432a0bae096ff0c536ee59b2ef6e4b20deadeb745eef32e8375c75fb6

# Script to compute and create PullPayment contracts across multiple chains
# Requires Foundry's Cast tool to be installed
#
# Salt Generation Methods:
# 1. Using OpenSSL: openssl rand -hex 32 | sed 's/^/0x/'
# 2. Using Cast:    cast keccak "$(date +%s)"
#
# The salt is a 32-byte value used to control the generated contract address.
# Try different salt values to find a desirable contract address.

# Usage information
usage() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -o, --owner ADDRESS      Owner address of the contract"
  echo "  -c, --casher ADDRESS     Casher address(es) of the contract (comma-separated for multiple)"
  echo "  -t, --to ADDRESS         Recipient address of the contract"
  echo "  -s, --salt HEX           32-byte salt (hex string with 0x prefix)"
  echo "  -r, --rpc-url URL        RPC URL to use for the connection"
  echo "  -d, --deploy             Actually deploy the contract (without this flag, only address is computed)"
  echo "  -n, --network NETWORK    Target network (ethereum, base, bsc, polygon, arbitrum)"
  echo "  --only-address           Only compute and display the contract address"
  echo "  -h, --help               Show this help message"
  echo ""
  echo "Example:"
  echo "  $0 --owner 0x123... --casher 0x456... --to 0x789... --salt 0x000... --network ethereum"
  echo "  $0 --owner 0x123... --casher 0x456,0x789... --to 0xabc... --deploy --network ethereum"
  echo "  $0 --owner 0x123... --casher 0x456... --to 0x789... --salt 0x000... --only-address"
  echo ""
  echo "When deploying, you will be prompted to enter your private key securely."
  exit 1
}

# Check if cast is installed
if ! command -v cast &> /dev/null; then
  echo "Error: 'cast' command not found."
  echo "Please install Foundry toolkit: curl -L https://foundry.paradigm.xyz | bash && foundryup"
  exit 1
fi

# Default values - Updated factory address
FACTORY_ADDRESS="0x49d7AEd15cac2E92a00131FF0a3dF956bF1a8046"
DEPLOY=false
ONLY_ADDRESS=false

# Function to generate a random salt
generate_salt() {
  if command -v openssl &> /dev/null; then
    echo "0x$(openssl rand -hex 32)"
  elif command -v cast &> /dev/null; then
    cast keccak "$(date +%s)_$(head -c 32 /dev/urandom | base64)"
  else
    echo "Error: Cannot generate salt. Install openssl or cast."
    exit 1
  fi
}

# Function to format cashers array for cast command
format_cashers_array() {
  local cashers="$1"
  # Split by comma and format as array
  IFS=',' read -ra ADDR <<< "$cashers"
  local formatted="["
  for i in "${!ADDR[@]}"; do
    if [ $i -gt 0 ]; then
      formatted="$formatted,"
    fi
    formatted="$formatted${ADDR[$i]}"
  done
  formatted="$formatted]"
  echo "$formatted"
}

# RPC URLs for different networks
ETHEREUM_RPC="https://eth.llamarpc.com"
BASE_RPC="https://base.llamarpc.com"
BSC_RPC="https://bsc-dataseed.binance.org"
POLYGON_RPC="https://polygon.llamarpc.com"
ARBITRUM_RPC="https://arb1.arbitrum.io/rpc"
SEPOLIA_RPC="https://ethereum-sepolia-rpc.publicnode.com"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -o|--owner)
      OWNER="$2"
      shift 2
      ;;
    -c|--casher)
      CASHER="$2"
      shift 2
      ;;
    -t|--to)
      TO_ADDRESS="$2"
      shift 2
      ;;
    -s|--salt)
      SALT="$2"
      shift 2
      ;;
    -r|--rpc-url)
      RPC_URL="$2"
      shift 2
      ;;
    -d|--deploy)
      DEPLOY=true
      shift
      ;;
    --only-address)
      ONLY_ADDRESS=true
      shift
      ;;
    -n|--network)
      NETWORK="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

# Validate required parameters
if [[ -z "$OWNER" || -z "$CASHER" || -z "$TO_ADDRESS" ]]; then
  echo "Error: Missing required parameters."
  usage
fi

# Format cashers array
CASHERS_ARRAY=$(format_cashers_array "$CASHER")

# Generate salt if not provided
if [[ -z "$SALT" ]]; then
  echo "No salt provided. Generating random salt..."
  SALT=$(generate_salt)
  echo "Generated salt: $SALT"
fi

# Set RPC URL based on network if not provided directly
if [[ -z "$RPC_URL" && ! -z "$NETWORK" ]]; then
  case $NETWORK in
    ethereum)
      RPC_URL=$ETHEREUM_RPC
      ;;
    base)
      RPC_URL=$BASE_RPC
      ;;
    bsc)
      RPC_URL=$BSC_RPC
      ;;
    polygon)
      RPC_URL=$POLYGON_RPC
      ;;
    arbitrum)
      RPC_URL=$ARBITRUM_RPC
      ;;
    sepolia)
      RPC_URL=$SEPOLIA_RPC
      ;;
    *)
      echo "Error: Unknown network '$NETWORK'."
      usage
      ;;
  esac
  echo "Using RPC URL for $NETWORK: $RPC_URL"
fi

# Default to Ethereum RPC if none provided
RPC_URL=${RPC_URL:-$ETHEREUM_RPC}

# Display contract parameters
echo "Computing PullPayment contract address..."
echo "Factory: $FACTORY_ADDRESS"
echo "Owner: $OWNER"
echo "Cashers: $CASHERS_ARRAY"
echo "To Address: $TO_ADDRESS"
echo "Salt: $SALT"
echo ""

# Compute the contract address using updated ABI
CONTRACT_ADDRESS=$(cast call $FACTORY_ADDRESS "computePullPaymentAddress(address,address[],address,bytes32)(address)" $OWNER "$CASHERS_ARRAY" $TO_ADDRESS $SALT --rpc-url $RPC_URL)

echo "Computed contract address: $CONTRACT_ADDRESS"

# Deploy the contract if requested and not only-address mode
if [ "$DEPLOY" = true ] && [ "$ONLY_ADDRESS" = false ]; then
  echo ""
  echo "Deploying PullPayment contract to address: $CONTRACT_ADDRESS"
  
  # First check if the factory exists
  echo "Checking factory contract..."
  FACTORY_CODE=$(cast code $FACTORY_ADDRESS --rpc-url $RPC_URL 2>/dev/null)
  
  if [[ -n "$FACTORY_CODE" && "$FACTORY_CODE" != "0x" ]]; then
    echo "Factory contract exists."
    echo ""
    echo "Please enter your private key:"
    read -s PRIVATE_KEY
    
    echo "------------------------------------------------------"
    echo "Deploying contract..."
    
    # Deploy using updated ABI
    TX=$(cast send --private-key $PRIVATE_KEY \
        --rpc-url $RPC_URL \
        $FACTORY_ADDRESS \
        "createPullPayment(address,address[],address,bytes32)(address)" \
        $OWNER "$CASHERS_ARRAY" $TO_ADDRESS $SALT)
    
    echo "Transaction hash: $TX"
    echo "------------------------------------------------------"
    echo "If the transaction was successful, the contract should be deployed at: $CONTRACT_ADDRESS"
  else
    echo "Error: Factory contract not found at address $FACTORY_ADDRESS"
    echo "Please deploy the factory first or check the address."
    exit 1
  fi
elif [ "$ONLY_ADDRESS" = true ]; then
  echo ""
  echo "Address computation complete. Use --deploy flag to actually deploy the contract."
else
  echo ""
  echo "To deploy this contract, run the command with --deploy flag and --network or --rpc-url"
fi 