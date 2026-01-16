# 🌀 hy2-onekey

> **Hysteria2 一键部署脚本（安全版 / 工程级）**  
> 自动部署 Hysteria2 服务端，并生成可直接使用的 Clash 订阅配置  
> 支持 Ubuntu / Debian / CentOS / Rocky / AlmaLinux  
> **不破坏现有 Nginx 环境**

---

## ✨ 项目简介

`hy2-onekey` 是一个 **安全、可复用、最小侵入** 的 Hysteria2 一键安装脚本，目标是：

- 让普通用户 **无需理解复杂配置**
- 让已有服务器 **不会被脚本“污染”或破坏**
- 自动生成 **Clash / Clash Meta / Stash 可直接使用的订阅配置**

本项目 **不依赖任何个人服务器或私有域名**，所有脚本均通过 **GitHub 官方 Raw 地址分发**，适合长期使用与开源维护。

---

## 🚀 功能特性

- ✅ 一键安装 Hysteria2 服务端
- ✅ 自动申请 Let's Encrypt TLS 证书
- ✅ 自动处理证书权限问题
- ✅ 自动放行 UDP 端口
- ✅ 自动注册 systemd 服务并启动
- ✅ 自动生成 Clash 完整配置（rule 模式）
- ✅ 自动生成可订阅的 YAML 文件
- ✅ **不会覆盖或修改已有 Nginx 配置**
- ✅ 支持 `curl | bash` 交互运行

---

## 🖥️ 支持系统

| 系统              | 支持情况 |
| ----------------- | -------- |
| Ubuntu            | ✅        |
| Debian            | ✅        |
| CentOS 7 / 8      | ✅        |
| Rocky Linux       | ✅        |
| AlmaLinux         | ✅        |
| 其他 systemd 系统 | 理论支持 |

---

## 📦 安装使用（一行命令）

```bash
curl -fsSL https://raw.githubusercontent.com/zshTolors/hy2-onekey/main/install-hy2.sh | bash
```

或：

```bash
wget https://raw.githubusercontent.com/zshTolors/hy2-onekey/main/install-hy2.sh
chmod +x install-hy2.sh
./install-hy2.sh
```

---

## 🧭 安装过程说明

脚本会引导你输入：

- 📍 域名（需已解析到当前服务器 IP）
- 🔢 UDP 监听端口（建议 20000–40000）
- 🔐 连接密码

脚本将自动完成：

1. 系统依赖安装
2. TLS 证书申请（standalone 模式）
3. Hysteria2 安装与配置
4. UDP 端口放行
5. systemd 服务启动
6. Clash 配置生成
7. 订阅文件发布（HTTP）

---

## 📄 安装完成后

- Clash 配置文件：`/root/hy2/clash.yaml`
- 订阅地址：`http://<服务器IP>/clash/clash.yaml`

---