#!/usr/bin/env bash

set -x

EMAIL=$1

# # Disable prelinking altogether
# #
# if grep -q ^PRELINKING /etc/sysconfig/prelink
# then
#   sed -i 's/PRELINKING.*/PRELINKING=no/g' /etc/sysconfig/prelink
# else
#   echo -e "\n# Set PRELINKING=no per security requirements" >> /etc/sysconfig/prelink
#   echo "PRELINKING=no" >> /etc/sysconfig/prelink
# fi
#
# /usr/sbin/prelink -ua

/usr/sbin/aide --init
cp /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
/usr/sbin/aide --check | mail -s "AIDE Weekly Check" $EMAIL

echo "01 3 * * sun root /usr/sbin/aide --check | mail -s \"AIDE Weekly Check\" $EMAIL" >> /etc/crontab
