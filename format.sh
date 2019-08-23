#!/bin/bash

for i in `seq 1 $GC_NUM_MAX`
do
	GC_NVME=`ssh ${GC_ADDR[i]} lsblk | grep nvme | awk '{ print $1 }'`
	if [ "$GC_NVME" = "" ]
	then
		echo "no ssd for "${GC_ADDR[i]}", quitting"
		# call cleanup script here
		exit 1
	fi
	ssh ${GC_ADDR[i]} sudo mkfs.ext4 -F /dev/$GC_NVME
	if [ "$?" != "0" ]
	then
		echo "mkfs failed for "${GC_ADDR[i]}", quitting"
		# call cleanup script here
		exit 1
	fi
	if [ ! -d "$GC_MOUNT_POINT" ]
	then
		echo "mount point :"$GC_MOUNT_POINT": does not exist, quitting"
		# call cleanup script here
		exit 1
	else
		ssh ${GC_ADDR[i]} sudo mount /dev/$GC_NVME $GC_MOUNT_POINT
	fi
done


