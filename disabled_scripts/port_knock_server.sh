#!/usr/bin/env bash

set -x

SSH_PORT=$1
KNOCKD_LOGGING_LOCATION=$2

until [[ -f /tmp/pkg_mgr_stack/pam_oath ]]; do sleep 5; set +x; done
set -x

yum install https://extras.getpagespeed.com/release-el7-latest.rpm -y
yum install knock-server -y

# Disable GetPageSpeed Repo
yum-config-manager --disable getpagespeed*

touch /tmp/pkg_mgr_stack/port_knock_server

# Setup the knockd server
mv /etc/knockd.conf{,.bak}

cat << EOF > /etc/knockd.conf
[options]
LogFile = $KNOCKD_LOGGING_LOCATION
Interface = $KNOCKD_LISTEN_IFACE
[opencloseSSH]
sequence        = 2222:udp,3333:tcp,4444:udp
seq_timeout     = 15
start_command   = /sbin/iptables -I INPUT -s %IP% -p tcp --dport $SSH_PORT -j ACCEPT
cmd_timeout     = 10
stop_command    = /sbin/iptables -D INPUT -s %IP% -p tcp --dport $SSH_PORT -j ACCEPT
tcpflags        = $KNOCKD_TCP_FLAGS
EOF

systemctl enable --now knockd.service

firewall-cmd --permanent --remove-service=dhcpv6-client
# The knockd server will execute the necessary commands to ssh in.
firewall-cmd --permanent --remove-service=ssh
firewall-cmd --reload

# Command to unlock
# hping 10.14.21.250 --udp -p 2222 -c 1 -q &> /dev/null; hping 10.14.21.250 -FR -p 3333 -c 1 -q &> /dev/null; hping 10.14.21.250 --udp -p 4444 -c 1 -q &> /dev/null
# Then ssh in before the 10 second timeout
