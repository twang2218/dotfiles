#!/bin/bash

sudo umount /mnt/disk1
sudo fsck.hfsplus /dev/sdc1
sudo mount -a
mount | grep disk1

