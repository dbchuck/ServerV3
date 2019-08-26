#!/usr/bin/env bash

set -x

# sshd -T

PORT=$1
DIGITS=$2
OATH_USER=$3
ADDR=$4
LISTEN_ADDR="$ADDR:$PORT"
ALLOWED_USERS=$OATH_USER

until [[ -f /tmp/pkg_mgr_stack/temp_limit ]]; do sleep 5; set +x; done
set -x

yum install epel-release -y
yum install pam_oath oathtool policycoreutils-python -y
# Enable for debugging
#yum install setroubleshoot -y

touch /tmp/pkg_mgr_stack/pam_oath

mkdir /etc/oath
if [[ "$OATH_PASSWD" == '' ]]; then {
  OATH_PASSWD='-'
}
fi
echo "HOTP/T30/$DIGITS $OATH_USER $OATH_PASSWD da822738cabc1f39bd7ae7421f5536" >> /etc/oath/users.oath

# Ensure only root can view OTP secrets
chmod 600 /etc/oath/users.oath
chown root:root /etc/oath/users.oath

# Temporarily disable SeLinux
#setenforce 0
# Fix SeLinux context
semanage fcontext -a -t systemd_passwd_var_run_t '/etc/oath(/.*)?'
restorecon -rv /etc/oath/

# Fix PAM
mv /etc/pam.d/sshd /etc/pam.d/sshd.bak
COMMENT_OUT=$(grep auth /etc/pam.d/sshd.bak | grep substack | grep password-auth)
sed "s/$COMMENT_OUT/#$COMMENT_OUT/" /etc/pam.d/sshd.bak > /etc/pam.d/sshd
sed -i "2i auth\t\trequired\tpam_oath.so usersfile=/etc/oath/users.oath window=5 digits=$DIGITS" /etc/pam.d/sshd
mv /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Notify SeLinux of port change if not running on port 22
semanage port -a -t ssh_port_t -p tcp $PORT # PORTNUMBER

# Edit existing ssh firewalld service file
firewall-cmd --permanent --service=ssh --remove-port=22/tcp
firewall-cmd --permanent --service=ssh --add-port=$PORT/tcp
firewall-cmd --reload

# Secure SSH config
cat << EOF > /etc/ssh/sshd_config
Protocol 2
Port $PORT
AddressFamily inet
ListenAddress $LISTEN_ADDR
LoginGraceTime 30 # seconds

# Server fingerprints
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Ciphers and keying
RekeyLimit 1G 15m
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group18-sha512,diffie-hellman-group16-sha512,diffie-hellman-group14-sha256
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com

# Log for audit, even users' key fingerprint
LogLevel VERBOSE
# Add additional restrictions
UsePrivilegeSeparation sandbox
AuthorizedKeysFile /root/.authorized_keys

PubkeyAuthentication no
PasswordAuthentication no
HostbasedAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication yes
AuthenticationMethods keyboard-interactive
# Restrict SSH usage
AllowUsers $ALLOWED_USERS
UsePAM yes

# Limit sessions and its duration
MaxAuthTries 2
MaxSessions 3
ClientAliveInterval 300
ClientAliveCountMax 0
TCPKeepAlive no
# Enabling DisableForwarding disables the four following settings
DisableForwarding yes
AllowAgentForwarding no       #
AllowStreamLocalForwarding no #
AllowTcpForwarding no         #
X11Forwarding no              #
PermitTunnel no
PermitUserRC no
PrintMotd no
Compression no
IgnoreRhosts yes
#ChrootDirectory /home/%u

# Only if you really need it:
#AcceptEnv LANG LC_*
#Subsystem sftp /usr/libexec/openssh/sftp-server
EOF
# Restarting too quickly after replacing the configuration file will result in an service error state.
sleep .1
systemctl restart sshd
