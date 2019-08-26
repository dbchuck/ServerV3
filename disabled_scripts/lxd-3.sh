#!/usr/bin/env bash

set -x

# Setup lxd profile for user environments

until zpool status | grep "pool: storage"; do sleep 5; done
until systemctl status snap.lxd.daemon.unix.socket | grep 'active (running)'; do sleep 5; done

lxc storage create storage zfs source=storage
lxc storage volume create storage massVol
lxc network create lxdbr0 ipv6.nat=false ipv6.address=none
lxc profile create userEnv
lxc profile edit userEnv << EOF
config:
  limits.cpu: "8"
  limits.cpu.allowance: 90%
  limits.cpu.priority: "5"
  limits.disk.priority: "5"
  limits.memory: 32GB
  limits.memory.swap: "false"
  limits.network.priority: "5"
  linux.kernel_modules: iptable_nat, ip6table_nat, ebtables, openvswitch, kvm, kvm_intel,
    vhost, vhost_net
  security.nesting: "true"
  user.network-config: |
    version: 1
    config: {}
  user.user-data: |
    #cloud-config
    runcmd:
    - ip link add name br-eth0 type bridge
    - ip link set br-eth0 up
    - ip link set eth0 up
    - ip link set eth0 master br-eth0
    - dhclient br-eth0
    - apt-get update
    - DEBIAN_FRONTEND=noninteractive apt install -y -q cockpit-machines cockpit-ws cockpit-system cockpit-dashboard
    - apt install -y openvswitch-switch openvswitch-common
description: ""
devices:
  massVol:
    limits.read: 30MB
    limits.write: 30MB
    path: /massVol
    pool: storage
    source: massVol
    type: disk
  root:
    limits.read: 30MB
    limits.write: 30MB
    path: /
    pool: storage
    type: disk
  kvm:
    path: /dev/kvm
    type: unix-char
  tun:
    path: /dev/net/tun
    type: unix-char
  vhost-net:
    mode: "0600"
    path: /dev/vhost-net
    type: unix-char
name: userEnv
EOF
lxc profile create bridgeInterface
lxc profile edit bridgeInterface << EOF
config: {}
description: Bridged networking LXD profile
devices:
  eth0:
    nictype: bridged
    parent: lxdbr0
    type: nic
name: bridgeInterface
EOF
