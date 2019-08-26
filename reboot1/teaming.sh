#!/usr/bin/env bash

set -x

STATIC_IP=$1
GATEWAY=$2
MAC_ADDRS=$3

# Remove default route
ip route del default

function correlate_mac_to_iface() {
  # Initialize empty array
  IFACE_ARRAY=('')
  # Persistantly change the names of the interfaces
  IFS=',' read -r -a MAC_ARRAY <<< "$MAC_ADDRS"
  COUNT=0
  for MAC in "${MAC_ARRAY[@]}"
  do
    # Change interface names temporarily
    # Find interface associated with MAC address
    for iface in $(ls -1 /sys/class/net | grep -v 'lo')
    do
      if [[ $(cat /sys/class/net/$iface/address | awk '{print toupper($0)}') == $(echo $MAC | awk '{print toupper($0)}') ]]; then {
        # Populate array
        IFACE_ARRAY+=($iface)
      }
      fi
    done
  done
}

correlate_mac_to_iface

# Setup teaming interface
nmcli con add type team con-name team0 ifname team0 config '{"runner": {"name": "activebackup"}}'
nmcli con mod team0 ipv4.addresses $STATIC_IP
nmcli con mod team0 ipv4.method manual
nmcli con mod team0 ipv4.gateway $GATEWAY
nmcli con mod team0 ipv4.dns $GATEWAY
nmcli con mod team0 ipv4.route-metric 0
nmcli con mod team0 connection.autoconnect-slaves yes
nmcli con mod team0 connection.autoconnect yes
nmcli con up team0

nmcli con reload

for index in "${!IFACE_ARRAY[@]}"
do
  nmcli con down ${IFACE_ARRAY[$index]}

  nmcli con mod ${IFACE_ARRAY[$index]} connection.autoconnect yes
  nmcli con mod ${IFACE_ARRAY[$index]} connection.slave-type team connection.master team0
  #nmcli con mod ${IFACE_ARRAY[$index]} 802-3-ethernet.mac-address ${MAC_ARRAY[$index]}
  nmcli con mod ${IFACE_ARRAY[$index]} ipv6.method ignore

  nmcli con up ${IFACE_ARRAY[$index]}
done

nmcli con up team0
