#!/bin/bash

linux_partition=$(sudo fdisk -l | grep nvme | grep Linux | grep -o 'nvme[0-9]*')
unset nvmes
if [ -z "$linux_partition" ]; then
echo "Linux partition not ssd"
 IFS=$'\n'
 nvmes=($(sudo fdisk -l | grep nvme | grep -o '/dev/nvme[0-9]*n[0-9]*'))
 unset IFS
else
 echo "linux partition is $linux_partition"
 IFS=$'\n'
 nvmes=($(sudo fdisk -l | grep nvme | grep -v $linux_partition | grep -o '/dev/nvme[0-9]*n[0-9]*'))
 unset IFS
fi
echo "sudo mdadm --create --verbose /dev/md0 --level=0 --name=RAID0 --raid-devices=${#nvmes[@]} ${nvmes[*]}"
sudo mdadm --create --verbose /dev/md0 --level=0 --name=RAID0 --raid-devices=${#nvmes[@]} ${nvmes[*]}
sudo mkfs.ext4 -L RAID0 /dev/md0
sudo mount /dev/md0 /mnt/data
sudo chown -R ubuntu:ubuntu /mnt/data
