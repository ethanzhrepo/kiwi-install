# Cloudflare全栈部署指南

本指南将帮助您使用Cloudflare服务部署完整的Kiwi支付系统，包括：
- **Cloudflare Zero Trust Tunnel** 部署API服务
- **Cloudflare Pages** 部署前端UI

这种部署方式具有以下优势：
- 🔒 **高安全性**：Zero Trust网络架构，API服务器无需公网IP
- 🛡️ **访问控制**：Nginx层实现/admin/路径的内网访问限制  
- ⚡ **高性能**：全球CDN加速，用户访问体验极佳
- 💰 **低成本**：Cloudflare免费套餐即可满足中小企业需求
- 🛡️ **DDoS防护**：自动防护DDoS攻击
- 📊 **详细分析**：完整的访问统计和性能监控

## 🏗️ 架构图

```
Internet
    ↓
Cloudflare CDN/WAF
    ↓
Cloudflare Zero Trust Tunnel
    ↓
Nginx Reverse Proxy (localhost:8080)
    ├── /admin/* → 内网IP限制 → Kiwi API (localhost:8090)
    └── /* → 正常代理 → Kiwi API (localhost:8090)
```

---

## 📋 部署前准备

### 🔧 必需工具
- Docker 和 Docker Compose
- Cloudflare账户
- 已配置的Kiwi API服务器
- 编译好的前端文件

### 🌐 域名要求
- 一个托管在Cloudflare的域名（免费套餐即可）
- 建议准备两个子域名：
  - `api.your-domain.com` - API服务
  - `app.your-domain.com` - 前端UI

---

## 🚀 第一步：部署API服务（Zero Trust Tunnel）

### 1.1 安装Cloudflared

#### 在Ubuntu/Debian系统：
```bash
# 下载并安装cloudflared
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb
```

#### 在CentOS/RHEL系统：
```bash
# 下载并安装cloudflared
curl -L --output cloudflared.rpm https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-x86_64.rpm
sudo rpm -i cloudflared.rpm
```

#### 在macOS系统：
```bash
# 使用Homebrew安装
brew install cloudflare/cloudflare/cloudflared
```

### 1.2 认证Cloudflared

```bash
# 登录Cloudflare账户
cloudflared tunnel login
```

这将打开浏览器，请完成Cloudflare授权。

### 1.3 创建Tunnel

```bash
# 创建一个新的tunnel
cloudflared tunnel create kiwi-api

# 记录下显示的Tunnel ID，后面会用到
```

### 1.4 配置DNS记录

```bash
# 为API子域名创建DNS记录
cloudflared tunnel route dns kiwi-api api.your-domain.com
```

### 1.5 配置Nginx反向代理

为了实现对/admin/路径的访问控制，我们需要在Kiwi API前面添加Nginx代理层。

#### 安装Nginx

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install nginx

# CentOS/RHEL
sudo yum install nginx
```

#### 创建Nginx配置

创建 `/etc/nginx/sites-available/kiwi-api` 文件：

```nginx
upstream kiwi_backend {
    server 127.0.0.1:8090;
    keepalive 16;
}

server {
    listen 8080;
    server_name localhost;
    
    # 日志配置
    access_log /var/log/nginx/kiwi-api.access.log;
    error_log /var/log/nginx/kiwi-api.error.log;
    
    # 基础安全配置
    server_tokens off;
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    
    # 限制请求体大小
    client_max_body_size 10M;
    
    # /admin/ 路径仅限内网访问
    location /admin/ {
        # 仅允许内网IP访问
        allow 10.0.0.0/8;
        allow 172.16.0.0/12;
        allow 192.168.0.0/16;
        allow 127.0.0.1;
        deny all;
        
        # 反向代理到Kiwi API
        proxy_pass http://kiwi_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # 超时配置
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        # 缓存配置
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }
    
    # 其他所有路径正常代理
    location / {
        # 反向代理到Kiwi API
        proxy_pass http://kiwi_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # 超时配置
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        # 缓存配置
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        
        # 健康检查
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
    }
    
    # 健康检查端点
    location /nginx-health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
```

#### 启用配置并启动Nginx

```bash
# 创建软链接启用站点
sudo ln -s /etc/nginx/sites-available/kiwi-api /etc/nginx/sites-enabled/

# 测试配置文件语法
sudo nginx -t

# 启动并启用Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# 重新加载配置
sudo systemctl reload nginx
```

### 1.6 更新Cloudflare配置

修改 `~/.cloudflared/config.yml` 文件，将流量导向Nginx：

```yaml
tunnel: kiwi-api
credentials-file: /home/your-username/.cloudflared/<TUNNEL-ID>.json

ingress:
  - hostname: api.your-domain.com
    service: http://localhost:8080  # 指向Nginx端口
    originRequest:
      httpHostHeader: api.your-domain.com
      connectTimeout: 30s
      tlsTimeout: 10s
      tcpKeepAlive: 30s
      keepAliveConnections: 10
      keepAliveTimeout: 1m30s
  - service: http_status:404
```

**注意**：
- 替换 `your-domain.com` 为您的实际域名
- 替换 `<TUNNEL-ID>` 为步骤1.3中的实际Tunnel ID
- 确保 `8090` 端口与您的Kiwi API服务端口一致

### 1.7 启动Kiwi API服务

```bash
# 进入Kiwi项目目录
cd /path/to/kiwi

# 启动API服务（使用官方镜像）
docker-compose -f docker-compose.yml up -d
```

**注意**：系统使用官方镜像仓库 `ghcr.io/ethanzhrepo/kiwi-api`，支持多架构（linux/amd64, linux/arm64）。

如需自定义构建镜像：
```bash
# 构建和推送自定义镜像
cd api
make docker-build-push VERSION=v1.0.0
```

### 1.8 启动Tunnel服务

```bash
# 启动cloudflared tunnel
cloudflared tunnel run kiwi-api
```

### 1.9 配置系统服务（可选但推荐）

为了确保Tunnel在系统重启后自动启动，创建系统服务：

```bash
# 安装为系统服务
sudo cloudflared service install

# 启动服务
sudo systemctl start cloudflared
sudo systemctl enable cloudflared
```

### 1.10 验证部署和访问控制

#### 测试公开API访问

```bash
# 测试公开API是否可访问
curl https://api.your-domain.com/pub/api/v1/health

# 应该返回类似以下的响应：
# {"status":"ok","timestamp":"2024-01-01T00:00:00Z"}
```

#### 测试Admin路径访问控制

```bash
# 从外网测试admin路径（应该被拒绝）
curl https://api.your-domain.com/admin/

# 应该返回403 Forbidden错误

# 从内网测试admin路径（应该正常访问，需要在服务器上执行）
curl http://localhost:8080/admin/

# 应该正常返回或转发到实际的admin接口
```

#### 验证Nginx日志

```bash
# 查看访问日志
sudo tail -f /var/log/nginx/kiwi-api.access.log

# 查看错误日志
sudo tail -f /var/log/nginx/kiwi-api.error.log

# 测试Nginx健康检查
curl http://localhost:8080/nginx-health
```

---

## 🌐 第二步：部署前端UI（Cloudflare Pages）

### 2.1 准备前端代码

确保您的前端项目已经配置好环境变量并构建：

```bash
# 进入UI目录
cd ui

# 配置环境变量
cat > .env << EOF
VITE_APP_NAME=Kiwi Billing
VITE_APP_COPYRIGHT=Your Company
VITE_APP_CORP_NAME=Your Company
VITE_APP_API_URL=https://api.your-domain.com/pub/api/v1
VITE_APP_SUPPORT_EMAIL=support@your-domain.com
VITE_APP_SUPPORT_TWITTER=@yourcompany
VITE_APP_SUPPORT_TELEGRAM=yourcompany
EOF

# 安装依赖并构建
yarn install
yarn build
```

### 2.2 部署到Cloudflare Pages

#### 方法一：Git集成部署（推荐）

1. **推送代码到Git仓库**：
   ```bash
   # 确保您的代码已推送到GitHub/GitLab
   git add .
   git commit -m "Ready for Cloudflare Pages deployment"
   git push origin main
   ```

2. **创建Pages项目**：
   - 登录 [Cloudflare Dashboard](https://dash.cloudflare.com)
   - 进入 **Workers & Pages**
   - 点击 **Create application**
   - 选择 **Pages** 标签
   - 点击 **Connect to Git**

3. **连接仓库**：
   - 选择您的Git提供商（GitHub/GitLab）
   - 授权Cloudflare访问您的仓库
   - 选择包含Kiwi UI的仓库

4. **配置构建设置**：
   ```
   项目名称: kiwi-ui
   生产分支: main
   根目录: ui
   构建命令: yarn build
   构建输出目录: dist
   ```

5. **配置环境变量**：
   在Pages项目设置中添加以下环境变量：
   ```
   VITE_APP_NAME=Kiwi Billing
   VITE_APP_COPYRIGHT=Your Company
   VITE_APP_CORP_NAME=Your Company
   VITE_APP_API_URL=https://api.your-domain.com/pub/api/v1
   VITE_APP_SUPPORT_EMAIL=support@your-domain.com
   VITE_APP_SUPPORT_TWITTER=@yourcompany
   VITE_APP_SUPPORT_TELEGRAM=yourcompany
   ```

6. **开始部署**：
   - 点击 **Save and Deploy**
   - Cloudflare将自动构建并部署您的应用

#### 方法二：直接上传部署

1. **上传构建文件**：
   - 在Cloudflare Dashboard中创建新的Pages项目
   - 选择 **Upload assets**
   - 上传 `ui/dist` 目录中的所有文件

### 2.3 配置自定义域名

1. **添加自定义域名**：
   - 在Pages项目设置中
   - 进入 **Custom domains**
   - 点击 **Set up a custom domain**
   - 输入 `app.your-domain.com`

2. **配置DNS记录**：
   Cloudflare会自动为您创建CNAME记录，指向Pages部署。

### 2.4 配置页面规则

为了正确处理单页应用的路由，需要配置重定向规则：

1. **进入Pages项目设置**
2. **添加重定向规则**：
   ```
   来源: /*
   目标: /index.html
   状态码: 200
   ```

### 2.5 验证前端部署

访问 `https://app.your-domain.com`，确认：
- ✅ 页面正常加载
- ✅ 可以正常调用API
- ✅ 路由功能正常
- ✅ SSL证书有效

---

## 🔧 高级配置

### 3.1 API安全增强

#### 配置访问策略

在Cloudflare Zero Trust中配置访问策略：

1. **进入Zero Trust Dashboard**
2. **创建应用程序**：
   - Application type: Self-hosted
   - Application domain: `api.your-domain.com`

3. **配置访问策略**：
   ```
   策略名称: Kiwi API Access
   规则: 允许所有用户访问 (或根据需要配置更严格的规则)
   ```

#### 配置防火墙规则

```yaml
# 在config.yml中添加额外的安全配置
ingress:
  - hostname: api.your-domain.com
    service: http://localhost:8090
    originRequest:
      httpHostHeader: api.your-domain.com
      connectTimeout: 30s
      tlsTimeout: 10s
      # 添加安全头
      originServerName: api.your-domain.com
      caPool: /etc/ssl/certs/ca-certificates.crt
```

### 3.2 性能优化

#### 配置缓存规则

在Cloudflare Dashboard中配置页面规则：

1. **API缓存规则**：
   ```
   URL: api.your-domain.com/pub/api/v1/static/*
   设置: 
   - 缓存级别: 缓存所有内容
   - 边缘缓存TTL: 2小时
   ```

2. **前端缓存规则**：
   ```
   URL: app.your-domain.com/*
   设置:
   - 缓存级别: 缓存所有内容
   - 浏览器缓存TTL: 4小时
   ```

#### 启用HTTP/3

1. 进入域名的 **Network** 设置
2. 开启 **HTTP/3 (with QUIC)**

### 3.3 监控和日志

#### 配置实时日志

1. **API访问日志**：
   - 在Zero Trust Dashboard中查看Tunnel日志
   - 配置日志推送到外部服务（如Datadog、Splunk）

2. **前端访问分析**：
   - 在Pages项目中查看访问统计
   - 配置Web Analytics

#### 设置告警

```bash
# 创建健康检查脚本
cat > /opt/kiwi/health-check.sh << 'EOF'
#!/bin/bash
API_URL="https://api.your-domain.com/pub/api/v1/health"
UI_URL="https://app.your-domain.com"

# 检查API健康状态
if ! curl -f -s "$API_URL" > /dev/null; then
    echo "API health check failed" >&2
    exit 1
fi

# 检查UI访问
if ! curl -f -s "$UI_URL" > /dev/null; then
    echo "UI health check failed" >&2
    exit 1
fi

echo "All services healthy"
EOF

chmod +x /opt/kiwi/health-check.sh

# 配置cron任务
echo "*/5 * * * * /opt/kiwi/health-check.sh" | crontab -
```

---

## 🚨 故障排除

### 常见问题及解决方案

#### 1. Tunnel连接失败

**症状**：API无法通过域名访问
**解决方案**：
```bash
# 检查tunnel状态
cloudflared tunnel info kiwi-api

# 检查本地服务状态
curl http://localhost:8090/pub/api/v1/health

# 重启tunnel服务
sudo systemctl restart cloudflared
```

#### 2. SSL证书问题

**症状**：浏览器显示SSL错误
**解决方案**：
- 确保域名已托管在Cloudflare
- 在Cloudflare中设置SSL模式为 "Full (strict)"
- 等待证书颁发完成（通常几分钟）

#### 3. 前端无法访问API

**症状**：前端页面加载但API调用失败
**解决方案**：
```bash
# 检查环境变量配置
grep API_URL ui/.env

# 检查CORS配置
curl -H "Origin: https://app.your-domain.com" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: X-Requested-With" \
     -X OPTIONS \
     https://api.your-domain.com/pub/api/v1/health
```

#### 4. 页面路由404错误

**症状**：前端路由刷新后显示404
**解决方案**：
- 确保已配置重定向规则
- 检查构建输出目录是否正确

#### 5. Admin路径访问控制问题

**症状**：Admin路径无法正确控制访问
**解决方案**：
```bash
# 检查Nginx配置语法
sudo nginx -t

# 检查Nginx状态
sudo systemctl status nginx

# 重新加载Nginx配置
sudo systemctl reload nginx

# 检查防火墙设置
sudo ufw status

# 测试内网访问
curl -v http://localhost:8080/admin/
```

#### 6. Nginx代理错误

**症状**：502 Bad Gateway或503 Service Unavailable
**解决方案**：
```bash
# 检查后端服务状态
curl http://localhost:8090/pub/api/v1/health

# 检查Nginx错误日志
sudo tail -50 /var/log/nginx/kiwi-api.error.log

# 检查upstream配置
sudo nginx -T | grep -A 10 "upstream kiwi_backend"

# 重启服务
sudo systemctl restart nginx
docker-compose restart

# 如果使用自定义镜像，重新拉取最新版本
docker-compose pull
docker-compose up -d
```

### 日志调试

#### Tunnel日志
```bash
# 查看tunnel日志
sudo journalctl -u cloudflared -f

# 查看详细日志
cloudflared tunnel run kiwi-api --loglevel debug
```

#### Nginx日志
```bash
# 查看Nginx访问日志
sudo tail -f /var/log/nginx/kiwi-api.access.log

# 查看Nginx错误日志
sudo tail -f /var/log/nginx/kiwi-api.error.log

# 查看特定IP的访问记录
sudo grep "192.168.1.100" /var/log/nginx/kiwi-api.access.log

# 查看Admin路径的访问记录
sudo grep "/admin/" /var/log/nginx/kiwi-api.access.log
```

#### API服务日志
```bash
# 查看Docker容器日志
docker-compose logs -f

# 查看特定服务日志（使用官方镜像）
docker logs $(docker ps -q --filter ancestor=ghcr.io/ethanzhrepo/kiwi-api)

# 拉取最新镜像版本
docker pull ghcr.io/ethanzhrepo/kiwi-api:latest
```

---

## 📊 性能监控

### 设置监控面板

创建监控脚本 `/opt/kiwi/monitor.sh`：

```bash
#!/bin/bash

# 配置变量
API_URL="https://api.your-domain.com"
UI_URL="https://app.your-domain.com"
LOG_FILE="/var/log/kiwi-monitor.log"

# 监控函数
check_api() {
    local start_time=$(date +%s%N)
    local response=$(curl -s -w "%{http_code}" -o /dev/null "$API_URL/pub/api/v1/health")
    local end_time=$(date +%s%N)
    local response_time=$(( (end_time - start_time) / 1000000 ))
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') API Status: $response, Response Time: ${response_time}ms" >> "$LOG_FILE"
}

check_ui() {
    local start_time=$(date +%s%N)
    local response=$(curl -s -w "%{http_code}" -o /dev/null "$UI_URL")
    local end_time=$(date +%s%N)
    local response_time=$(( (end_time - start_time) / 1000000 ))
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') UI Status: $response, Response Time: ${response_time}ms" >> "$LOG_FILE"
}

# 执行检查
check_api
check_ui
```

### Cloudflare Analytics

1. **启用分析**：
   - 在域名设置中启用 **Web Analytics**
   - 在Pages项目中查看访问统计

2. **自定义事件追踪**：
   ```javascript
   // 在前端代码中添加
   // 追踪支付事件
   if (typeof cloudflareAnalytics !== 'undefined') {
       cloudflareAnalytics('payment_initiated', {
           amount: paymentAmount,
           currency: 'USDT'
       });
   }
   ```

---

## 🔐 安全最佳实践

### 1. 网络安全

- ✅ 使用Cloudflare WAF防护
- ✅ 启用DDoS保护
- ✅ 配置速率限制
- ✅ 启用Bot Fight Mode

### 2. 访问控制

- ✅ 配置Zero Trust访问策略
- ✅ 使用强密码和2FA
- ✅ 定期轮换API密钥
- ✅ 监控异常访问

### 3. 数据保护

- ✅ 所有通信使用HTTPS
- ✅ 敏感数据加密存储
- ✅ 定期备份配置
- ✅ 遵循数据保护法规

---

## 📞 技术支持

### 获取帮助

如果在部署过程中遇到问题：

1. **查看日志**：先检查相关服务的日志输出
2. **检查配置**：确认所有配置文件语法正确
3. **网络测试**：使用curl等工具测试连接
4. **联系支持**：提供详细的错误信息和环境描述

### 有用的命令

```bash
# 测试API连通性
curl -v https://api.your-domain.com/pub/api/v1/health

# 检查DNS解析
nslookup api.your-domain.com
nslookup app.your-domain.com

# 检查SSL证书
openssl s_client -connect api.your-domain.com:443 -servername api.your-domain.com

# 监控tunnel状态
watch -n 10 'cloudflared tunnel info kiwi-api'
```

---

## 🎉 部署完成

恭喜！您已成功使用Cloudflare服务部署了完整的Kiwi支付系统。现在您可以：

- ✅ 通过 `https://app.your-domain.com` 访问管理界面
- ✅ 通过 `https://api.your-domain.com` 提供API服务
- ✅ 享受Cloudflare提供的全球CDN加速
- ✅ 受益于Zero Trust安全架构保护

### 下一步

1. **配置监控告警**：设置关键指标的监控
2. **优化性能**：根据实际使用情况调整缓存策略
3. **扩展功能**：根据业务需求添加更多功能
4. **定期维护**：保持系统和依赖项更新

**享受您的Kiwi支付系统吧！** 🚀