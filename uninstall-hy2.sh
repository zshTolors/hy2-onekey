#!/usr/bin/env bash
set -e

echo "=================================================="
echo " Hysteria2 一键卸载脚本（hy2-onekey）"
echo " 仅移除本项目相关内容，不破坏系统环境"
echo "=================================================="
echo

# ================== 1. root 检查 ==================
if [ "$EUID" -ne 0 ]; then
  echo "❌ 请使用 root 用户运行该脚本"
  exit 1
fi

# ================== 2. 确认卸载 ==================
read -rp "⚠️  确认要卸载 Hysteria2 及相关配置？[y/N]: " CONFIRM </dev/tty
CONFIRM=${CONFIRM,,}

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "yes" ]]; then
  echo "已取消卸载"
  exit 0
fi

echo
echo "🧹 开始卸载 Hysteria2..."

# ================== 3. 停止并禁用服务 ==================
if systemctl list-units --full -all | grep -q hysteria-server.service; then
  systemctl stop hysteria-server || true
  systemctl disable hysteria-server || true
fi

# ================== 4. 删除 systemd 服务文件 ==================
rm -f /etc/systemd/system/hysteria-server.service
rm -f /etc/systemd/system/hysteria-server@.service
systemctl daemon-reload

# ================== 5. 删除 hysteria 程序 ==================
if command -v hysteria >/dev/null 2>&1; then
  rm -f "$(command -v hysteria)"
fi

# ================== 6. 删除配置与数据目录 ==================
rm -rf /etc/hysteria
rm -rf /root/hy2

# ================== 7. 删除订阅文件（仅本项目路径） ==================
if [ -d /var/www/html/clash ]; then
  rm -rf /var/www/html/clash
fi

if [ -d /usr/share/nginx/html/clash ]; then
  rm -rf /usr/share/nginx/html/clash
fi

# ================== 8. 防火墙规则提示（不自动删除） ==================
echo
echo "⚠️ 防火墙 UDP 端口规则未自动删除（安全起见）"
echo "如需手动清理，请根据你的系统执行："
echo
echo "firewalld:"
echo "  firewall-cmd --list-ports"
echo "  firewall-cmd --remove-port=端口/udp --permanent"
echo "  firewall-cmd --reload"
echo

# ================== 9. 完成 ==================
echo "✅ 卸载完成"
echo "--------------------------------------------------"
echo "已移除："
echo "- Hysteria2 程序"
echo "- systemd 服务"
echo "- /etc/hysteria 配置"
echo "- /root/hy2 Clash 配置"
echo "- 本项目生成的订阅文件"
echo
echo "未移除："
echo "- Nginx"
echo "- Certbot / TLS 证书"
echo "- 系统其他服务与配置"
echo "--------------------------------------------------"
