#!/bin/bash
#
# Setup SSH with public key authentication
# Public Key MUST be passed as argument $1
 
# 1. 获取公钥并进行校验
PUBLIC_KEY=${1}
echo $PUBLIC_KEY
 
if [ -z "$PUBLIC_KEY" ]; then
    echo "错误：未提供公钥。请使用您的公钥作为第一个参数。"
    echo "用法: $0 \"ssh-rsa AAAAB3NzaC1yc2EA...\""
    exit 1
fi
 
echo "Setting up SSH with public key authentication..."
 
# Download ngrok (only if not already installed)
if ! command -v ngrok &> /dev/null;
then
    echo "ngrok not found. Downloading..."
    wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
    sudo tar xvzf ngrok-v3-stable-linux-amd64.tgz -C /usr/local/bin
    rm ngrok-v3-stable-linux-amd64.tgz
else
    echo "ngrok is already installed."
fi
 
# Install SSH-Server
echo "Running apt update..."
sudo apt update --allow-releaseinfo-change
 
echo "Installing OpenSSH server..."
sudo apt install openssh-server -y
 
# 2. 设置公钥认证所需的文件和权限
echo "Configuring authorized_keys for root user..."
# 创建 .ssh 目录并设置权限
sudo mkdir -p /root/.ssh
sudo chmod 700 /root/.ssh
 
# 将公钥写入 authorized_keys 文件并设置权限
echo "$PUBLIC_KEY" | sudo tee /root/.ssh/authorized_keys > /dev/null
sudo chmod 700 /root/.ssh/authorized_keys
 
# 3. SSH Config - 启用公钥认证并禁用密码认证
echo "Configuring SSH..."
 
# 允许 root 登录 (注意：这是为了与原脚本兼容，生产环境建议禁用或使用普通用户)
echo "PermitRootLogin yes" | sudo tee -a /etc/ssh/sshd_config
 
# 启用公钥认证
echo "PubkeyAuthentication yes" | sudo tee -a /etc/ssh/sshd_config
 
# *禁用*密码认证 (关键修改)
echo "PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config
 
# 可选：禁用 ChallengeResponse，进一步提高安全性并防止尝试密码登录
echo "ChallengeResponseAuthentication no" | sudo tee -a /etc/ssh/sshd_config
 
echo "Restarting SSH service..."
sudo service ssh restart
 
echo "SSH Server configured successfully with public key authentication!"