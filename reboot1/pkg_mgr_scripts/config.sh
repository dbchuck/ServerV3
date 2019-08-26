#!/usr/bin/env bash

set -x

yum install deltarpm -y || exit 1
yum install epel-release -y || exit 1
yum install vim nano vi htop pv rsyslog lm_sensors -y || exit 1
yum install cockpit cockpit-bridge cockpit-dashboard cockpit-pcp cockpit-storaged -y || exit 1
yum update -y || exit 1

# remove extra packages
for pkg in aic94xx-firmware alsa-firmware alsa-lib alsa-tools-firmware authconfig dosfstools fxload ivtv-firmware iwl100-firmware iwl1000-firmware iwl105-firmware iwl135-firmware iwl2000-firmware iwl2030-firmware iwl3160-firmware iwl3945-firmware iwl4965-firmware iwl5000-firmware iwl5150-firmware iwl6000-firmware iwl6000g2a-firmware iwl6000g2b-firmware iwl6050-firmware iwl7260-firmware iwl7265-firmware lshw newt newt-python slang NetworkManager-tui
do
  yum erase -y $pkg || exit 1
done
