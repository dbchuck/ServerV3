#!/usr/bin/env bash

set -x

cd /opt
mkdir securityOnion
cd securityOnion

curl -L https://github.com/Security-Onion-Solutions/security-onion/releases/download/v16.04.6.1_20190514/securityonion-16.04.6.1.iso -o securityonion-16.04.6.1.iso
# ISO signature
curl -L https://github.com/Security-Onion-Solutions/security-onion/raw/master/sigs/securityonion-16.04.6.1.iso.sig -o securityonion-16.04.6.1.iso.sig
# Signing Keys
curl -L https://raw.githubusercontent.com/Security-Onion-Solutions/security-onion/master/KEYS -o KEYS
gpg --import KEYS
if ! gpg --verify securityonion-16.04.6.1.iso.sig securityonion-16.04.6.1.iso; then
  exit 1
fi

#virt-install --name security_onion --cdrom securityonion-16.04.6.1.iso --graphics spice --graphics vnc --vcpus 4 --ram 8192 --os-type linux --os-variant ubuntu16.04 --disk size=50 --network network=default
