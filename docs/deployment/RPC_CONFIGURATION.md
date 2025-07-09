# RPC节点部署与配置指南

本指南将帮助您为Kiwi支付系统配置RPC节点，支持多种EVM兼容区块链网络。您可以选择使用第三方RPC服务或自行部署RPC节点。

## 📋 概述

Kiwi支付系统需要连接到各个区块链网络的RPC节点来：
- 监听链上交易事件
- 查询账户余额和交易状态
- 广播交易到网络
- 获取最新区块信息

支持的网络：
- **Ethereum** (主网 + 测试网)
- **BSC** (币安智能链)
- **Base** (Coinbase Layer 2)
- **Polygon** (Polygon PoS)
- **Arbitrum One** (Arbitrum Layer 2)

---

## 🌐 方案一：使用第三方RPC服务（推荐）

### 优势
- ✅ **快速部署**：无需自建基础设施
- ✅ **高可用性**：专业团队维护，99.9%+可用性
- ✅ **全球加速**：CDN加速，低延迟
- ✅ **自动扩展**：按需扩容，无需容量规划
- ✅ **专业支持**：24/7技术支持

### 主要RPC服务商

#### 🔹 Alchemy（推荐）

**支持网络**：Ethereum, Polygon, Arbitrum One, Base
**特点**：高性能、可靠性强、提供增强API

1. **注册账户**：
   - 访问 [Alchemy官网](https://www.alchemy.com/)
   - 注册开发者账户
   - 验证邮箱并完成KYC

2. **创建应用**：
   ```
   Dashboard → Create App
   - Name: Kiwi Payment System
   - Description: Cryptocurrency payment gateway
   - Chain: 选择需要的网络
   - Network: Mainnet (生产) / Testnet (测试)
   ```

3. **获取API密钥**：
   ```
   应用详情页面 → View Key
   - HTTP URL: https://eth-mainnet.g.alchemy.com/v2/YOUR-API-KEY
   - WebSocket URL: wss://eth-mainnet.g.alchemy.com/v2/YOUR-API-KEY
   ```

4. **配置示例**：
   ```json
   {
     "ethereum": {
       "mainnet": {
         "name": "Ethereum Mainnet",
         "rpc_url": "https://eth-mainnet.g.alchemy.com/v2/YOUR-API-KEY",
         "ws_url": "wss://eth-mainnet.g.alchemy.com/v2/YOUR-API-KEY",
         "chain_id": 1
       }
     },
     "polygon": {
       "mainnet": {
         "name": "Polygon Mainnet",
         "rpc_url": "https://polygon-mainnet.g.alchemy.com/v2/YOUR-API-KEY",
         "ws_url": "wss://polygon-mainnet.g.alchemy.com/v2/YOUR-API-KEY",
         "chain_id": 137
       }
     }
   }
   ```

#### 🔹 Infura

**支持网络**：Ethereum, Polygon, Arbitrum One
**特点**：老牌服务商、稳定可靠、简单易用

1. **注册账户**：
   - 访问 [Infura官网](https://infura.io/)
   - 创建免费账户
   - 验证邮箱

2. **创建项目**：
   ```
   Dashboard → Create New Key
   - Project Name: Kiwi Payment
   - Network: Web3 API
   ```

3. **获取端点**：
   ```
   项目设置页面 → Endpoints
   - HTTPS: https://mainnet.infura.io/v3/YOUR-PROJECT-ID
   - WebSocket: wss://mainnet.infura.io/ws/v3/YOUR-PROJECT-ID
   ```

4. **配置示例**：
   ```json
   {
     "ethereum": {
       "mainnet": {
         "name": "Ethereum Mainnet",
         "rpc_url": "https://mainnet.infura.io/v3/YOUR-PROJECT-ID",
         "ws_url": "wss://mainnet.infura.io/ws/v3/YOUR-PROJECT-ID",
         "chain_id": 1
       }
     }
   }
   ```

#### 🔹 QuickNode

**支持网络**：所有主流EVM链
**特点**：性能优异、支持网络全面

1. **注册账户**：[QuickNode官网](https://www.quicknode.com/)
2. **创建端点**：选择网络和节点规格
3. **获取URL**：复制HTTP和WebSocket端点

#### 🔹 Ankr

**支持网络**：多链支持、价格实惠
**特点**：高性价比、支持网络广泛

1. **注册账户**：[Ankr官网](https://www.ankr.com/)
2. **创建项目**：选择Premium或Enterprise计划
3. **配置端点**：获取专用RPC端点

#### 🔹 公共免费RPC（仅测试用）

**⚠️ 警告**：免费公共RPC有严格的速率限制，仅适用于开发测试，生产环境请使用付费服务。

```json
[
  {
    "name": "Ethereum",
    "chainId": 1,
    "symbol": "ETH",
    "chainName": "Ethereum",
    "decimals": 18,
    "confirmBlock": 12,
    "confirmTimeDelaySeconds": 600,
    "confirmThresholdAmountInDecimals": 1000,
    "rpc": [
      "wss://rpc.ankr.com/eth/ws",
      "wss://ethereum-mainnet-rpc.publicnode.com"
    ],
    "explorerUrl": "https://etherscan.io",
    "supportsEIP1559": true,
    "feeStrategy": "auto",
    "usdtContracts": [
      {
        "address": "0xdAC17F958D2ee523a2206206994597C13D831ec7",
        "decimals": 6,
        "symbol": "USDT"
      },
      {
        "address": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
        "decimals": 6,
        "symbol": "USDC"
      }
    ],
    "maxGasPrice": "20gwei"
  },
  {
    "name": "BSC",
    "chainId": 56,
    "symbol": "BNB",
    "chainName": "BSC",
    "decimals": 18,
    "confirmBlock": 15,
    "confirmTimeDelaySeconds": 45,
    "confirmThresholdAmountInDecimals": 1000,
    "rpc": [
      "wss://bsc-dataseed1.binance.org/",
      "wss://bsc-ws-node.nariox.org:443"
    ],
    "explorerUrl": "https://bscscan.com/",
    "usdtContracts": [
      {
        "address": "0x55d398326f99059fF775485246999027B3197955",
        "decimals": 18,
        "symbol": "BSC-USD"
      },
      {
        "address": "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d",
        "decimals": 18,
        "symbol": "USDC"
      }
    ],
    "maxGasPrice": "5gwei"
  }
]
```

---

## 🏗️ 方案二：自建RPC节点

### 优势
- ✅ **完全控制**：数据和基础设施完全自主
- ✅ **无速率限制**：不受第三方限制
- ✅ **隐私保护**：交易数据不经过第三方
- ✅ **成本可控**：大规模使用时成本更低

### 劣势
- ❌ **技术复杂**：需要专业运维知识
- ❌ **硬件要求高**：存储、计算、网络资源需求大
- ❌ **维护成本高**：需要持续监控和更新
- ❌ **同步时间长**：初始同步可能需要数天

### 硬件要求

#### 最低配置（仅测试）
- **CPU**: 8核
- **内存**: 32GB RAM
- **存储**: 2TB NVMe SSD
- **网络**: 100Mbps带宽

#### 推荐配置（生产环境）
- **CPU**: 16核以上
- **内存**: 64GB+ RAM
- **存储**: 4TB+ NVMe SSD
- **网络**: 1Gbps+ 带宽

### 各公链RPC部署官方文档

#### 🔹 Ethereum

**官方文档**：[Ethereum Node Documentation](https://ethereum.org/en/developers/docs/nodes-and-clients/)

**主要客户端**：
- **Geth**: [官方安装指南](https://geth.ethereum.org/docs/install-and-build/installing-geth)
- **Erigon**: [GitHub部署文档](https://github.com/ledgerwatch/erigon#getting-started)
- **Nethermind**: [官方文档](https://docs.nethermind.io/nethermind/first-steps-with-nethermind/getting-started)
- **Besu**: [官方指南](https://besu.hyperledger.org/en/stable/HowTo/Get-Started/Install-Binaries/)

**快速部署**：
```bash
# 使用Geth
docker run -d --name ethereum-node \
  -p 8545:8545 -p 8546:8546 -p 30303:30303 \
  -v ethereum-data:/root/.ethereum \
  ethereum/client-go:latest \
  --http --http.addr 0.0.0.0 \
  --ws --ws.addr 0.0.0.0
```

#### 🔹 BSC (Binance Smart Chain)

**官方文档**：[BSC Node Documentation](https://docs.bnbchain.org/docs/validator/fullnode)

**部署指南**：
- **全节点部署**: [Full Node Setup](https://docs.bnbchain.org/docs/validator/fullnode)
- **Docker部署**: [Docker Guide](https://github.com/bnb-chain/bsc/blob/master/README.md)
- **硬件要求**: [Hardware Requirements](https://docs.bnbchain.org/docs/validator/manage-validator#hardware-requirements)

**快速启动**：
```bash
# 使用官方Docker镜像
docker run -d --name bsc-node \
  -p 8545:8545 -p 8546:8546 -p 30311:30311 \
  -v bsc-data:/bsc \
  ghcr.io/bnb-chain/bsc:latest
```

#### 🔹 Polygon

**官方文档**：[Polygon Node Setup](https://docs.polygon.technology/pos/how-to/operating/full-node/)

**部署选项**：
- **Heimdall + Bor**: [完整节点部署](https://docs.polygon.technology/pos/how-to/operating/full-node/full-node-binaries/)
- **Docker部署**: [Docker Setup](https://docs.polygon.technology/pos/how-to/operating/full-node/full-node-docker/)
- **Erigon**: [Erigon for Polygon](https://github.com/ledgerwatch/erigon/tree/devel/cmd/rpcdaemon)

**一键部署脚本**：
```bash
# 使用官方安装脚本
curl -L https://raw.githubusercontent.com/maticnetwork/launch/master/mainnet-v1/sentry/sentry/setup.sh | bash
```

#### 🔹 Base (Coinbase Layer 2)

**官方文档**：[Base Node Documentation](https://docs.base.org/tools/node-providers)

**部署方式**：
- **OP Stack节点**: [Base Node Setup](https://github.com/base-org/node)
- **Docker部署**: [Docker Guide](https://docs.base.org/guides/run-a-base-node)
- **Replicas**: [Replica Setup](https://github.com/base-org/node/blob/main/README.md)

**Docker部署**：
```bash
# 克隆仓库
git clone https://github.com/base-org/node.git
cd node

# 启动节点
docker-compose up -d
```

#### 🔹 Arbitrum One

**官方文档**：[Arbitrum Node Running](https://docs.arbitrum.io/node-running/running-a-node)

**部署选项**：
- **全节点**: [Full Node Setup](https://docs.arbitrum.io/node-running/running-a-node)
- **Archive节点**: [Archive Node](https://docs.arbitrum.io/node-running/running-a-node#archive-node)
- **Docker部署**: [Docker Guide](https://github.com/OffchainLabs/nitro/blob/master/README.md)

**Docker快速启动**：
```bash
# 使用官方镜像
docker run -d --name arbitrum-node \
  -p 8547:8547 -p 8548:8548 \
  -v arbitrum-data:/home/user/.arbitrum \
  offchainlabs/nitro-node:latest
```

---

## ⚙️ Kiwi系统RPC配置

### Docker镜像仓库

Kiwi系统使用官方镜像仓库：
- **仓库地址**: `ghcr.io/ethanzhrepo/kiwi-api`
- **支持架构**: `linux/amd64`, `linux/arm64`
- **标签**: `latest`, 版本标签（如 `v1.0.0`）

```bash
# 拉取最新镜像
docker pull ghcr.io/ethanzhrepo/kiwi-api:latest

# 构建自定义镜像
cd api
make docker-build-push VERSION=v1.0.0
```

### 配置文件位置

RPC配置位于：`.config/evm_chains.json`

### 完整配置示例

```json
[
  {
    "name": "Ethereum",
    "chainId": 1,
    "symbol": "ETH",
    "chainName": "Ethereum",
    "decimals": 18,
    "confirmBlock": 12,
    "confirmTimeDelaySeconds": 600,
    "confirmThresholdAmountInDecimals": 1000,
    "rpc": [
      "wss://eth-mainnet.g.alchemy.com/v2/YOUR-API-KEY",
      "wss://mainnet.infura.io/ws/v3/YOUR-PROJECT-ID",
      "wss://ethereum-mainnet-rpc.publicnode.com"
    ],
    "explorerUrl": "https://etherscan.io",
    "supportsEIP1559": true,
    "feeStrategy": "auto",
    "eip1559Config": {
      "baseFeeMultiplier": 2.0,
      "priorityFeePercentile": 50,
      "maxPriorityFeeGwei": 20,
      "minPriorityFeeGwei": 1
    },
    "usdtContracts": [
      {
        "address": "0xdAC17F958D2ee523a2206206994597C13D831ec7",
        "decimals": 6,
        "symbol": "USDT"
      },
      {
        "address": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
        "decimals": 6,
        "symbol": "USDC"
      },
      {
        "address": "0x6c3ea9036406852006290770BEdFcAbA0e23A0e8",
        "decimals": 6,
        "symbol": "PYUSD"
      },
      {
        "address": "0x6B175474E89094C44Da98b954EedeAC495271d0F",
        "decimals": 18,
        "symbol": "DAI"
      }
    ],
    "maxGasPrice": "5gwei"
  },
  {
    "name": "BSC",
    "chainId": 56,
    "symbol": "BNB",
    "chainName": "BSC",
    "decimals": 18,
    "confirmBlock": 15,
    "confirmTimeDelaySeconds": 45,
    "confirmThresholdAmountInDecimals": 1000,
    "rpc": [
      "wss://bsc-dataseed1.binance.org/",
      "wss://bsc-ws-node.nariox.org:443"
    ],
    "explorerUrl": "https://bscscan.com/",
    "usdtContracts": [
      {
        "address": "0x55d398326f99059fF775485246999027B3197955",
        "decimals": 18,
        "symbol": "BSC-USD"
      },
      {
        "address": "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d",
        "decimals": 18,
        "symbol": "USDC"
      },
      {
        "address": "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56",
        "decimals": 18,
        "symbol": "BUSD"
      }
    ],
    "maxGasPrice": "5gwei"
  },
  {
    "name": "Base",
    "chainId": 8453,
    "symbol": "ETH",
    "chainName": "Base",
    "decimals": 18,
    "confirmBlock": 10,
    "confirmTimeDelaySeconds": 45,
    "confirmThresholdAmountInDecimals": 1000,
    "rpc": [
      "wss://base-mainnet.g.alchemy.com/v2/YOUR-API-KEY",
      "wss://base-mainnet.infura.io/ws/v3/YOUR-PROJECT-ID"
    ],
    "explorerUrl": "https://basescan.org",
    "supportsEIP1559": true,
    "feeStrategy": "auto",
    "eip1559Config": {
      "baseFeeMultiplier": 1.5,
      "priorityFeePercentile": 25,
      "maxPriorityFeeGwei": 5,
      "minPriorityFeeGwei": 1
    },
    "usdtContracts": [
      {
        "address": "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
        "decimals": 6,
        "symbol": "USDC"
      },
      {
        "address": "0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2",
        "decimals": 6,
        "symbol": "Bridged-USDT"
      }
    ],
    "maxGasPrice": "1gwei"
  },
  {
    "name": "Polygon (PoS)",
    "chainId": 137,
    "symbol": "POL",
    "chainName": "Polygon (PoS)",
    "decimals": 18,
    "confirmBlock": 100,
    "confirmTimeDelaySeconds": 240,
    "confirmThresholdAmountInDecimals": 1000,
    "rpc": [
      "wss://polygon-mainnet.g.alchemy.com/v2/YOUR-API-KEY",
      "wss://polygon-mainnet.infura.io/ws/v3/YOUR-PROJECT-ID"
    ],
    "explorerUrl": "https://polygonscan.com",
    "supportsEIP1559": true,
    "feeStrategy": "auto",
    "eip1559Config": {
      "baseFeeMultiplier": 1.8,
      "priorityFeePercentile": 60,
      "maxPriorityFeeGwei": 100,
      "minPriorityFeeGwei": 30
    },
    "usdtContracts": [
      {
        "address": "0xc2132D05D31c914a87C6611C10748AEb04B58e8F",
        "decimals": 6,
        "symbol": "USDT"
      },
      {
        "address": "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174",
        "decimals": 6,
        "symbol": "USDC"
      },
      {
        "address": "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063",
        "decimals": 18,
        "symbol": "DAI"
      }
    ],
    "maxGasPrice": "40gwei"
  },
  {
    "name": "Arbitrum One",
    "chainId": 42161,
    "symbol": "ETH",
    "chainName": "Arbitrum One",
    "decimals": 18,
    "confirmBlock": 3,
    "confirmTimeDelaySeconds": 3,
    "confirmThresholdAmountInDecimals": 1000,
    "rpc": [
      "wss://arb-mainnet.g.alchemy.com/v2/YOUR-API-KEY",
      "wss://arbitrum-mainnet.infura.io/ws/v3/YOUR-PROJECT-ID"
    ],
    "explorerUrl": "https://arbiscan.io",
    "supportsEIP1559": true,
    "feeStrategy": "auto",
    "eip1559Config": {
      "baseFeeMultiplier": 1.2,
      "priorityFeePercentile": 10,
      "maxPriorityFeeGwei": 2,
      "minPriorityFeeGwei": 1
    },
    "usdtContracts": [
      {
        "address": "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9",
        "decimals": 6,
        "symbol": "USDT"
      },
      {
        "address": "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
        "decimals": 6,
        "symbol": "USDC"
      }
    ],
    "maxGasPrice": "0.1gwei"
  }
]
```


### 配置验证

使用CLI工具验证RPC配置：

```bash
# 测试所有网络连接
./kiwi-cli system test-rpc

# 测试特定网络
./kiwi-cli system test-rpc --chain ethereum

# 查看网络状态
./kiwi-cli system network-status

# 查看最新区块
./kiwi-cli system latest-block --chain ethereum
```

---

## 🔧 高级配置

### 负载均衡配置

为提高可用性，可以配置多个RPC端点：

```json
{
  "ethereum": {
    "mainnet": {
      "name": "Ethereum Mainnet",
      "chain_id": 1,
      "rpc_urls": [
        "https://eth-mainnet.g.alchemy.com/v2/YOUR-API-KEY",
        "https://mainnet.infura.io/v3/YOUR-PROJECT-ID",
        "https://rpc.ankr.com/eth"
      ],
      "ws_urls": [
        "wss://eth-mainnet.g.alchemy.com/v2/YOUR-API-KEY",
        "wss://mainnet.infura.io/ws/v3/YOUR-PROJECT-ID"
      ],
      "failover_enabled": true,
      "health_check_interval": 30
    }
  }
}
```

### 性能优化配置

```json
{
  "performance": {
    "connection_pool_size": 10,
    "request_timeout": 30,
    "retry_attempts": 3,
    "retry_delay": 1000,
    "batch_request_limit": 100,
    "websocket_ping_interval": 30
  }
}
```

### 监控配置

```json
{
  "monitoring": {
    "metrics_enabled": true,
    "health_check_enabled": true,
    "log_rpc_calls": false,
    "slow_query_threshold": 5000,
    "error_rate_threshold": 0.05
  }
}
```

---

## 📊 性能对比

### RPC服务商性能对比

| 服务商 | 延迟 | 可用性 | 速率限制 | 价格 | 支持网络 |
|--------|------|--------|----------|------|----------|
| Alchemy | ~100ms | 99.9% | 高 | 中等 | 主流EVM链 |
| Infura | ~120ms | 99.8% | 中等 | 中等 | 部分EVM链 |
| QuickNode | ~80ms | 99.9% | 高 | 较高 | 全面 |
| Ankr | ~150ms | 99.5% | 中等 | 较低 | 全面 |
| 自建节点 | ~20ms | 取决于运维 | 无限制 | 高(基础设施) | 取决于部署 |

### 成本估算

#### 第三方RPC服务（月费用）
- **小型项目** (1M请求/月): $50-200
- **中型项目** (10M请求/月): $200-800  
- **大型项目** (100M请求/月): $800-3000
- **企业级** (1B请求/月): $3000-10000

#### 自建节点（月成本）
- **服务器租赁**: $200-1000
- **带宽费用**: $100-500
- **存储费用**: $50-200
- **运维人力**: $2000-5000
- **总计**: $2350-6700

---

## 🚨 故障排除

### 常见问题

#### 1. RPC连接超时
```bash
# 检查网络连接
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  YOUR_RPC_URL

# 检查防火墙设置
sudo ufw status

# 检查DNS解析
nslookup eth-mainnet.g.alchemy.com
```

#### 2. WebSocket连接失败
```bash
# 测试WebSocket连接
wscat -c wss://eth-mainnet.g.alchemy.com/v2/YOUR-API-KEY

# 检查代理设置
echo $HTTP_PROXY
echo $HTTPS_PROXY
```

#### 3. 速率限制
```bash
# 检查API配额使用情况
curl -H "Authorization: Bearer YOUR-API-KEY" \
  https://dashboard.alchemy.com/api/metrics

# 调整请求频率
# 在config.yml中设置更保守的参数
```

#### 4. 同步延迟
```bash
# 检查节点同步状态
./kiwi-cli system sync-status --chain ethereum

# 比较本地和远程区块高度
./kiwi-cli system compare-blocks --chain ethereum
```

### 监控脚本

创建RPC健康检查脚本：

```bash
#!/bin/bash
# rpc-health-check.sh

CHAINS=("ethereum" "bsc" "polygon" "base" "arbitrum")
LOG_FILE="/var/log/kiwi-rpc-health.log"

for chain in "${CHAINS[@]}"; do
    echo "Checking $chain..." | tee -a $LOG_FILE
    
    # 检查RPC连接
    if ./kiwi-cli system test-rpc --chain $chain > /dev/null 2>&1; then
        echo "✅ $chain RPC: OK" | tee -a $LOG_FILE
    else
        echo "❌ $chain RPC: FAILED" | tee -a $LOG_FILE
        # 发送告警
        ./send-alert.sh "RPC failure on $chain"
    fi
    
    # 检查同步状态
    sync_status=$(./kiwi-cli system sync-status --chain $chain 2>/dev/null)
    echo "📊 $chain sync: $sync_status" | tee -a $LOG_FILE
done

echo "Health check completed at $(date)" | tee -a $LOG_FILE
```

---

## 🔐 安全最佳实践

### API密钥管理
- ✅ 使用环境变量存储密钥
- ✅ 定期轮换API密钥
- ✅ 限制API密钥权限
- ✅ 监控API使用情况
- ✅ 不在代码中硬编码密钥

### 网络安全
- ✅ 使用HTTPS/WSS连接
- ✅ 配置防火墙规则
- ✅ 启用DDoS防护
- ✅ 监控异常流量
- ✅ 使用VPN访问自建节点

### 访问控制
- ✅ IP白名单限制
- ✅ 请求签名验证
- ✅ 频率限制
- ✅ 操作审计日志
- ✅ 多因子认证

---

## 📞 技术支持

### 获取帮助

1. **查看日志**: 检查Kiwi系统和RPC服务的日志
2. **网络测试**: 使用curl等工具测试RPC连接
3. **配置验证**: 确认所有配置文件格式正确
4. **社区支持**: 查看官方文档和社区论坛

### 有用的工具

```bash
# RPC连接测试
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  YOUR_RPC_URL

# WebSocket测试
npm install -g wscat
wscat -c YOUR_WS_URL

# 性能测试
time curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_getBalance","params":["0x...",  "latest"],"id":1}' \
  YOUR_RPC_URL
```

---

## 🎉 部署完成

恭喜！您已成功配置RPC节点连接。现在Kiwi支付系统可以：

- ✅ 连接到多个区块链网络
- ✅ 监听链上交易事件
- ✅ 查询账户余额和状态
- ✅ 广播交易到网络
- ✅ 自动处理故障转移

### 下一步

1. **压力测试**: 测试在高负载下的性能表现
2. **监控告警**: 设置关键指标的监控和告警
3. **优化配置**: 根据实际使用情况调整参数
4. **备份方案**: 准备多个RPC提供商作为备用

**祝您使用愉快！** 🚀