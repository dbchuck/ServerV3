#!/bin/bash

function log () {
  # Parethesis are for subshell and execute installation processes in parallel
  (
  # make sure the directory is there.
  mkdir ~/logs &> /dev/null
  SCRIPT=$(basename $1)
  NAME=${SCRIPT/.sh/}
  touch /tmp/running/$NAME
  bash "${@}" &> ~/logs/$NAME.log
  touch /tmp/completed/$NAME
  ) &
  # ^ Uncomment to run in parallel
}

function install_packages () {
  for pkg_script in $(ls $EXEC_DIR/${1}/pkg_mgr_scripts)
  do
    until bash $EXEC_DIR/${1}/pkg_mgr_scripts/$pkg_script
    do
      echo "Trying again, package install script exited with non-zero status"
    done
  done
}

function stall_dns () {
  # Stall until DNS works
  while ! ping -c5 example.com &> /dev/null; do
    sleep 1
  done
}

function done_status {
  sleep 5
  until [[ $(diff /tmp/running/ /tmp/completed/ | wc -l) -eq '0' ]]
  do
    # Disable debugging output
    set +x
    sleep 1
  done
  # Re-enable debugging output
  set -x

  touch /root/$1
  sync
  reboot
}

function install_done {
  # systemctl disable persist.service
  # rm -f /usr/lib/systemd/system/persist.service
  # systemctl daemon-reload

  touch ~/$1
  sync
  #reboot
}

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [[ "${#@}" -lt 1 ]] || ! cat $1 ; then {
  echo "Usage: ./$0 <config file>"
  exit 2
}
fi

set -x

EXEC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Import config variables
source $1

mkdir /tmp/running
mkdir /tmp/completed

stall_dns

if [[ ! -f /root/reboot1-check ]]; then {
  # Setup networking
  log $EXEC_DIR/reboot1/teaming.sh "$LAN_ADDR/24" $GATEWAY $MAC_ADDRS
  sleep 7
  stall_dns
  install_packages reboot1
  # Configure the machine
  log $EXEC_DIR/reboot1/config.sh $GRUB_CFG $GRUB_USER

  cat << EOF > /usr/lib/systemd/system/persist.service
[Unit]
Description=persist

[Service]
ExecStart=/bin/bash /root/setup.sh $EXEC_DIR/$1
User=root
Group=root
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable persist.service

  done_status reboot1-check
}
elif [[ ! -f /root/reboot2-check ]]; then {
  stall_dns
  install_packages reboot2
  ( # Install SoftEther VPN
  log $EXEC_DIR/reboot2/softether_vpn.sh
  # Install and configure ZFS On Linux 0.8.1
  log $EXEC_DIR/reboot2/zfs.sh $ZFS_EMAIL $NORMAL_USER $ZPOOL_NAME
  # Install snapper
  log $EXEC_DIR/reboot2/snapper.sh
  # Install CPU Temp Limit
  log $EXEC_DIR/reboot2/temp_limit.sh
  # Setup email notification on any system (pam) login
  log $EXEC_DIR/reboot2/email_sys_login.sh $SYS_LOGIN_EMAIL
  # install dracut-ssh
  log $EXEC_DIR/reboot2/dracut_ssh.sh $DRACUT_SSH_PORT $GRUB_CFG
  # Download Security Onion
  log $EXEC_DIR/reboot2/security_onion.sh
  # # install aide
  # log $EXEC_DIR/reboot2/aide.sh $AUDIT_EMAIL

  until [[ $(diff /tmp/running/ /tmp/completed/ | wc -l) -eq '0' ]]; do sleep 1; set +x; done
  set -x

  install_done reboot2-check ) &> ~/logs/main.log
}
fi
