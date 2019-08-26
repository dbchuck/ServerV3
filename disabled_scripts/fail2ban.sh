#!/usr/bin/env bash

set -x

yum install epel-release -y
yum install fail2ban -y

mv /etc/fail2ban/jail.local /etc/fail2ban/jail.local.bak
mv /etc/fail2ban/jail.d/local.conf /etc/fail2ban/jail.d/local.conf.bak

cat << EOF > /etc/fail2ban/jail.d/local.conf
[DEFAULT]
bantime = 3600
sender = fail2ban@main
destemail = ddbishop@pm.me
action = %(action_mwl)s

[sshd]
enabled = true
EOF

systemctl enable --now fail2ban
