#!/usr/bin/env bash

set -x

cd /tmp
git clone https://github.com/dbchuck/throttle-cpu-temp
cd throttle-cpu-temp
# Quick fix...
mount -o remount,rw,suid,dev,exec -t tmpfs /tmp
make
make install
mount -o remount,defaults -t tmpfs /tmp
