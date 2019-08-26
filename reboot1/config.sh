#!/usr/bin/env bash

set -x

GRUB_CFG=$1
USER=$2

###
# Security Limits
###

function set_option_limits () {
  EXPLANATION=$5
  if ! egrep "^$1" /etc/security/limits.conf | grep $2 | grep $3 | grep $4; then {
    echo "# $EXPLANATION" >> /etc/security/limits.conf
    echo "* hard core 0" >> /etc/security/limits.conf
  } else {
    sed -i "s/^$(egrep "^$1" /etc/security/limits.conf | grep $2 | grep $3 | grep $4)/# $EXPLANATION\n$1 $2 $3 $4/g" /etc/security/limits.conf
  }
  fi
}

set_option_limits '*' hard core 0 'Disable core dumps for all users'

###
# IOMMU
###

# Enable IOMMU via grub boot parameter
sed -i "s@.*GRUB_CMDLINE_LINUX.*@$(echo GRUB_CMDLINE_LINUX=\"$(cat /etc/default/grub | grep GRUB_CMDLINE_LINUX | awk -F\" '{print $2,"intel_iommu=on"}')\")@" /etc/default/grub
# Regenerate grub configration
grub2-mkconfig -o $GRUB_CFG
# # List out all of the IOMMU groups
# shopt -s nullglob
# for g in /sys/kernel/iommu_groups/*; do
#     echo "IOMMU Group ${g##*/}:"
#     for d in $g/devices/*; do
#         echo -e "\t$(lspci -nns ${d##*/})"
#     done;
# done;
## More info here: https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF

###
# GRUB
###

# Set password on GRUB boot menu
# Just use grub2-setpassword command
sed -i "s/root/$USER/" /etc/grub.d/01_users
# Password: grub
# BIOS grub password
echo 'GRUB2_PASSWORD=grub.pbkdf2.sha512.10000.EFBDEA5388BC8F96DF607188B5C6FA59E184677A6501E5B780F5858DD0967FE9936E1ABE600ACD644365135AAA73EECF9643179BD85ECA261CCCFAE5FCD54AC6.29DE95EAC699E653A298197AB7505555A73044A544029A865E852BABD65EDE73B89EACC09FD27EB2DF3D72083155C6D750FE1D7A43717D3AA84ACB3C46E2D1F1' > /boot/grub2/user.cfg
# UEFI grub password
echo 'GRUB2_PASSWORD=grub.pbkdf2.sha512.10000.EFBDEA5388BC8F96DF607188B5C6FA59E184677A6501E5B780F5858DD0967FE9936E1ABE600ACD644365135AAA73EECF9643179BD85ECA261CCCFAE5FCD54AC6.29DE95EAC699E653A298197AB7505555A73044A544029A865E852BABD65EDE73B89EACC09FD27EB2DF3D72083155C6D750FE1D7A43717D3AA84ACB3C46E2D1F1' > /boot/efi/EFI/centos/user.cfg
chmod 600 /boot/grub2/user.cfg
chmod 600 /boot/efi/EFI/centos/user.cfg

###
# Auto-prune Idle Users
###

# Remove idle users after 15 minutes
echo "readonly TMOUT=900" >> /etc/profile.d/os-security.sh
echo "readonly HISTFILE" >> /etc/profile.d/os-security.sh
chmod +x /etc/profile.d/os-security.sh

###
# Tuned
###

systemctl enable --now tuned
tuned-adm profile virtual-host

###
# Lock down CRON and AT
###

echo "Locking down Cron"
touch /etc/cron.allow
chmod 600 /etc/cron.allow
awk -F: '{print $1}' /etc/passwd | grep -v root > /etc/cron.deny
echo "Locking down AT"
touch /etc/at.allow
chmod 600 /etc/at.allow
awk -F: '{print $1}' /etc/passwd | grep -v root > /etc/at.deny

###
# Secure mount options
###

mv /etc/fstab /etc/fstab.bak
echo "# <file system>     <mount point>  <type>  <options>  <dump>  <pass>" > /etc/fstab
echo "tmpfs /tmp tmpfs defaults,nosuid,nodev,noexec 0 0" >> /etc/fstab
egrep -v '#|^$' /etc/fstab.bak >> /etc/fstab

###
# Sysctl values
###

# Change the TCP options for the Linux box via sysctl

function set_value_sysctl () {
  OPTION=$1
  VALUE=$2
  EXPLANATION=$3
  # Set running system sysctl values
  sysctl -n -w $OPTION=$VALUE

  # Set persistent sysctl values
  if grep ^$OPTION /etc/sysctl.conf ; then
    sed -i "s/^$(echo $OPTION | sed "s/\./\\\./g").*/# $EXPLANATION\n$(echo $OPTION | sed "s/\./\\\./g") = $VALUE/" /etc/sysctl.conf
  else
    echo "# $EXPLANATION" >> /etc/sysctl.conf
    echo "$OPTION = $VALUE" >> /etc/sysctl.conf
  fi
}

set_value_sysctl net.ipv4.ip_forward 0
set_value_sysctl net.ipv4.conf.all.send_redirects 0
set_value_sysctl net.ipv4.conf.default.send_redirects 0
set_value_sysctl net.ipv4.tcp_max_syn_backlog 1280
set_value_sysctl net.ipv4.icmp_echo_ignore_broadcasts 1
set_value_sysctl net.ipv4.conf.all.accept_source_route 0
set_value_sysctl net.ipv4.conf.all.accept_redirects 0
set_value_sysctl net.ipv4.conf.all.secure_redirects 0
set_value_sysctl net.ipv4.conf.all.log_martians 1
set_value_sysctl net.ipv4.conf.default.accept_source_route 0
set_value_sysctl net.ipv4.conf.default.accept_redirects 0
set_value_sysctl net.ipv4.conf.default.secure_redirects 0
set_value_sysctl net.ipv4.icmp_echo_ignore_broadcasts 1
set_value_sysctl net.ipv4.icmp_ignore_bogus_error_responses 1
set_value_sysctl net.ipv4.tcp_syncookies 1
set_value_sysctl net.ipv4.conf.all.rp_filter 1
set_value_sysctl net.ipv4.conf.default.rp_filter 1
set_value_sysctl net.ipv4.tcp_timestamps 0
set_value_sysctl fs.suid_dumpable 0 'Disable core dumps for SUID programs'
set_value_sysctl kernel.randomize_va_space 2 'Enable ASLR'

###
# Enable security services
###

systemctl enable --now rsyslog.service
systemctl enable --now auditd.service
systemctl enable --now irqbalance
systemctl enable --now crond
systemctl enable --now firewalld
systemctl enable --now cockpit.socket
firewall-cmd --permanent --add-service=cockpit
firewall-cmd --reload

###
# Disable unused services
###

for svc in rhel-autorelabel.service rhel-configure.service rhel-domainname.service rhel-import-state.service
do
  systemctl disable $svc
done

###
# Configure KVM
###

# Enable nested KVM machines
echo "options kvm_intel nested=1" >> /etc/modprobe.d/kvm.conf

###
# Disable IPV6
###

echo "options ipv6 disable=1" >> /etc/modprobe.d/disabled.conf
echo "NETWORKING_IPV6=no" >> /etc/sysconfig/network
echo "IPV6INIT=no" >> /etc/sysconfig/network

###
# Disable unnecessary protocols
###

echo "install dccp /bin/false" > /etc/modprobe.d/dccp.conf
echo "install sctp /bin/false" > /etc/modprobe.d/sctp.conf
echo "install rds /bin/false" > /etc/modprobe.d/rds.conf
echo "install tipc /bin/false" > /etc/modprobe.d/tipc.conf

###
# Disable Zeroconf Networking
###

echo "NOZEROCONF=yes" >> /etc/sysconfig/network

###
# Remove unused folders
###

for i in /media /srv /mnt
do
  # Remove empty directories (will error out if not empty)
  rmdir $i
done
