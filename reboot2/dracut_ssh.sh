#!/usr/bin/env bash

set -x

DRACUT_SSH_PORT=$1
GRUB_CFG=$2

mkdir ~/.ssh
# Configure
sed -i "s@.*GRUB_CMDLINE_LINUX.*@$(echo GRUB_CMDLINE_LINUX=\"$(cat /etc/default/grub | grep GRUB_CMDLINE_LINUX | awk -F\" '{print $2,"rd.neednet=1 ip=dhcp"}')\")@" /etc/default/grub
mkdir /root/dracut-crypt-ssh-keys
setenforce 0
ssh-keygen -t rsa -f /root/dracut-crypt-ssh-keys/ssh_dracut_rsa_key -N ""
chmod 0600 /root/dracut-crypt-ssh-keys
cat /root/dracut-crypt-ssh-keys/ssh_dracut_rsa_key*
sed -i "s@.*dropbear_port=.*@dropbear_port=$DRACUT_SSH_PORT@" /etc/dracut.conf.d/crypt-ssh.conf
sed -i 's@.*dropbear_rsa_key=.*@dropbear_rsa_key=/root/dracut-crypt-ssh-keys/ssh_dracut_rsa_key@' /etc/dracut.conf.d/crypt-ssh.conf
#echo -n "command=\"console_auth\" $(cat /root/dracut-crypt-ssh-keys/ssh_dracut_rsa_key.pub)" > /root/.ssh/authorized_keys
echo -n "$(cat /root/dracut-crypt-ssh-keys/ssh_dracut_rsa_key.pub)" > /root/.ssh/authorized_keys
sed -i 's@.*dropbear_acl=.*@dropbear_acl=/root/.ssh/authorized_keys@' /etc/dracut.conf.d/crypt-ssh.conf
# Apply changes
grub2-mkconfig -o $GRUB_CFG
dracut --force

setenforce 1
