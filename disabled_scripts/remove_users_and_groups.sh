#!/usr/bin/env bash

set -x

# for i in $(cat /etc/passwd | awk -F: '{print $1}'); do echo -n "$i: "; find / -path .snapshots -prune -o -user $i 2> /dev/null | wc -l; done

for i in bin daemon adm sync shutdown halt operator games ftp
do
  userdel $i
done

for i in floppy games
do
  groupdel $i
done
