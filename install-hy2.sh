#!/usr/bin/env bash
set -e

echo "=================================================="
echo " Hysteria2 一键安装脚本"
echo " 支持 Ubuntu / Debian / CentOS / Rocky / Alma"
echo "=================================================="
echo

# ================== 1. root 检查 ==================
if [ "$EUID" -ne 0 ]; then
  echo "❌ 请使用 root 用户运行该脚本"
  exit 1
fi

# ================== 2. 读取参数（兼容 curl | bash） ==================
read -rp "请输入域名（已解析到本机，如 v.example.com）: " DOMAIN </dev/tty
read -rp "请输入监听端口（UDP，建议 20000-40000）: " PORT </dev/tty
read -rsp "请输入连接密码: " PASSWORD </dev/tty
echo

if [[ -z "$DOMAIN" || -z "$PORT" || -z "$PASSWORD" ]]; then
  echo "❌ 参数不能为空"
  exit 1
fi

# ================== 3. 系统检测 ==================
if command -v apt >/dev/null 2>&1; then
  OS="debian"
elif command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
  OS="rhel"
else
  echo "❌ 不支持的系统"
  exit 1
fi

echo "✅ 检测到系统类型: $OS"

# ================== 4. 安装基础依赖 ==================
if [ "$OS" = "debian" ]; then
  apt update
  apt install -y curl wget socat cron nginx certbot
else
  yum install -y epel-release
  yum install -y curl wget socat cronie nginx certbot
fi

# ================== 5. 申请 TLS 证书 ==================
echo "🔐 正在申请 Let's Encrypt 证书（需要 80 端口空闲）"
certbot certonly --standalone \
  -d "$DOMAIN" \
  --non-interactive \
  --agree-tos \
  -m admin@"$DOMAIN"

# ================== 6. 安装 Hysteria2 ==================
if ! command -v hysteria >/dev/null 2>&1; then
  echo "⬇️  安装 Hysteria2"
  curl -fsSL https://get.hy2.sh | bash
fi

# ================== 7. 证书权限修复 ==================
echo "🔧 处理证书权限（避免 hysteria 读取失败）"
mkdir -p /etc/hysteria/certs
cp /etc/letsencrypt/live/"$DOMAIN"/fullchain.pem /etc/hysteria/certs/
cp /etc/letsencrypt/live/"$DOMAIN"/privkey.pem /etc/hysteria/certs/
chown -R hysteria:hysteria /etc/hysteria/certs
chmod 600 /etc/hysteria/certs/*

# ================== 8. 写入 Hysteria2 配置 ==================
cat >/etc/hysteria/config.yaml <<EOF
listen: 0.0.0.0:${PORT}

tls:
  cert: /etc/hysteria/certs/fullchain.pem
  key: /etc/hysteria/certs/privkey.pem

auth:
  type: password
  password: ${PASSWORD}
EOF

# ================== 9. 防火墙放行 UDP ==================
if command -v firewall-cmd >/dev/null 2>&1; then
  firewall-cmd --add-port=${PORT}/udp --permanent
  firewall-cmd --reload
fi

# ================== 10. 启动 Hysteria2 ==================
systemctl enable hysteria-server
systemctl restart hysteria-server

echo
echo "✅ Hysteria2 服务状态："
systemctl status hysteria-server --no-pager

# ================== 11. 生成 Clash 完整配置 ==================
mkdir -p /root/hy2

cat >/root/hy2/clash.yaml <<EOF
mixed-port: 7890
allow-lan: true
mode: rule
log-level: info

proxies:
  - name: "Hy2-${DOMAIN}"
    type: hysteria2
    server: ${DOMAIN}
    port: ${PORT}
    password: ${PASSWORD}
    sni: ${DOMAIN}
    alpn:
      - h3
    skip-cert-verify: false

proxy-groups:
  - name: PROXY
    type: select
    proxies:
      - Hy2-${DOMAIN}
      - DIRECT

rules:
  - IP-CIDR,127.0.0.0/8,DIRECT
  - IP-CIDR,10.0.0.0/8,DIRECT
  - IP-CIDR,172.16.0.0/12,DIRECT
  - IP-CIDR,192.168.0.0/16,DIRECT
  - GEOIP,CN,DIRECT
  - GEOSITE,CN,DIRECT
  - MATCH,PROXY
EOF

# ================== 12. 安全提供订阅（不破坏现有 Nginx） ==================
echo "🌐 准备生成订阅文件（零侵入 Nginx）"

if [ -d /var/www/html ]; then
  WEB_ROOT="/var/www/html"
elif [ -d /usr/share/nginx/html ]; then
  WEB_ROOT="/usr/share/nginx/html"
else
  WEB_ROOT="/var/www/html"
  mkdir -p "$WEB_ROOT"
fi

mkdir -p "$WEB_ROOT/clash"
cp /root/hy2/clash.yaml "$WEB_ROOT/clash/clash.yaml"

systemctl enable nginx
systemctl restart nginx

# ================== 13. 输出最终信息 ==================
IP=$(curl -s ipv4.icanhazip.com || echo "<你的服务器IP>")

echo
echo "🎉 安装完成！"
echo "------------------------------------------"
echo "Hysteria2 节点已启动"
echo "Clash 配置文件路径："
echo "  /root/hy2/clash.yaml"
echo
echo "📡 订阅地址："
echo "  http://${IP}/clash/clash.yaml"
echo
echo "👉 可直接复制到 Clash Meta / Stash / Verge 订阅使用"
echo "------------------------------------------"