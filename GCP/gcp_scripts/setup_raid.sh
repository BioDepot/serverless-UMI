#!/bin/bash
sudo mdadm --create --verbose /dev/md0 --level=0 --raid-devices=4 /dev/nvme0n1 /dev/nvme0n2 /dev/nvme0n3 /dev/nvme0n4
sudo mkfs.ext4 -F /dev/md0
sudo mount /dev/md0 /mnt/data
sudo chown -R ubuntu:ubuntu /mnt/data

cp -r /home/ubuntu/References /mnt/data/References
cp -r /home/ubuntu/function /mnt/data/function
