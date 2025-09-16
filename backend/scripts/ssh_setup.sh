#!/bin/bash
set -e

# root パスワード設定（本番環境では要変更）
echo 'root:Docker!' | chpasswd

# SSH設定の一部を有効化
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# SSH鍵がなければ作成
[ ! -f /etc/ssh/ssh_host_rsa_key ] && ssh-keygen -A
