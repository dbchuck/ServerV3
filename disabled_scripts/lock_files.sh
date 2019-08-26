#!/usr/bin/env bash

set -x

for i in services fstab passwd shadow crontab audit/audit.rules ../boot/grub2/user.cfg
do
  chattr +i /etc/$i
done
