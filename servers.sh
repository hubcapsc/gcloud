#!/bin/bash
set -x
. ./default_set_up.sh
. ./consume_command_line_arguments.sh
. ./required_variables.sh GC_BIN GC_ZONE GC_PROJECT GC_MOUNT_POINT GC_OBJECT

##### build a server create command
#
# Make the servers as "small" as possible and still do the job.
# An f1-micro (1 vCPU, 0.6 GB memory) doesn't have enough memory
# to even run dnf (yum). If you specify custom-memory, you must
# also specify custom-cpu, and if you specify custom-cpu you cannot
# specify machine-type.
#
# --scopes=storage-full          can write in buckets
#	cpus	memory
#	1	1024
#	2	2048
#	3	3840
CREATE_PART1=$GC_BIN"/gcloud compute instances create "
CREATE_PART2="--image="$GC_IMAGE" "
CREATE_PART2=$CREATE_PART2"--image-project="$GC_PROJECT" " 
# g1-small, local-ssd features are not compatible
#CREATE_PART2=$CREATE_PART2"--machine-type=g1-small "
CREATE_PART2=$CREATE_PART2"--machine-type=n1-standard-1 "
CREATE_PART2=$CREATE_PART2"--zone="$GC_ZONE" " 
CREATE_PART2=$CREATE_PART2"--local-ssd interface=nvme "

##### set defaults when needed
if [ -z "$GC_NUM_ATTEMPTS" ]; then GC_NUM_ATTEMPTS=1; fi
if [ -z "$GC_NUM_IO" ]; then GC_NUM_IO=1; fi
if [ -z "$GC_NUM_META" ]; then GC_NUM_META=1; fi
GC_NUM_MAX=$(($GC_NUM_IO > $GC_NUM_META ? $GC_NUM_IO : $GC_NUM_META))

##### try to create the orangefs servers, give up if they don't seem to be OK
for i in `seq 1 $GC_NUM_MAX`
do
	# create server i
	CMD=$CREATE_PART1$GC_OBJECT$i" "$CREATE_PART2
	eval $CMD
	if [ "$?" != "0" ]
	then
		exit 1
	fi

	# exit if server i doesn't seem functional.
	. ./test_host.sh $GC_OBJECT$i $GC_NUM_ATTEMPTS
done

# format each orangefs server's nvme drive.
for i in `seq 1 $GC_NUM_MAX`
do
	. ./format.sh
done

##### makes io and metadata server lists for the orangefs config file.
for i in `seq 1 $GC_NUM_IO`
do
	if [ -z "$GC_IO_LIST" ]
	then
		GC_IO_LIST=$GC_OBJECT$i
	else
		GC_IO_LIST=$GC_IO_LIST","$GC_OBJECT$i
	fi
done
for i in `seq 1 $GC_NUM_META`
do
	if [ -z "$GC_META_LIST" ]
	then
		GC_META_LIST=$GC_OBJECT$i
	else
		GC_META_LIST=$GC_META_LIST","$GC_OBJECT$i
	fi
done

##### create an orangefs config file for the new servers. We
##### need two orangefs filesystems on these servers for xfstests,
##### a primary filesystem and a scratch filesystem, so we create
##### a config file for each and append the scratch FileSystem stanza
##### to the end of the primary config file.
#PATH=$PATH:/opt/orangefs/bin
which pvfs2-genconfig >> /dev/null 2>&1
if [ "$?" != "0" ]
then
	# call cleanup script here
	echo "+++++++++++++++ CAN'T FIND pvfs2-genconfig +++++++++++"
	exit 1
fi

GC_ORANGEFS="/tmp/orangefs.conf"
GC_SCRATCH="/tmp/scratch"
if [ -e "$GC_ORANGEFS" ]; then rm $GC_ORANGEFS; fi
if [ -e "$GC_SCRATCH" ]; then rm $GC_SCRATCH; fi

CMD="pvfs2-genconfig --quiet "
CMD=$CMD"--protocol tcp "
CMD=$CMD"--storage  /mnt/data "
CMD=$CMD"--metadata /mnt/meta "
CMD=$CMD"--ioservers "$GC_IO_LIST" "
CMD=$CMD"--metaservers "$GC_META_LIST" "
eval $CMD$GC_ORANGEFS
if [ "$?" != "0" ]
then
	# call cleanup script here
	echo "+++++++++++++++ pvfs2-genconfig orangefs.conf failed +++++++++++"
	exit 1
fi
eval $CMD"--fsname scratch "$GC_SCRATCH
if [ "$?" != "0" ]
then
	# call cleanup script here
	echo "+++++++++++++++ pvfs2-genconfig scratch failed +++++++++++"
	exit 1
fi
# copy the scratch filesystem stanza onto the end of the main config file.
sed -n '/FileSystem/,/\/Filesystem/p;/\/Filesystem/q' /tmp/scratch >> \
	/tmp/orangefs.conf

# copy the config files to the servers we just created.
for i in `seq 1 $GC_NUM_MAX`
do
	scp /tmp/orangefs.conf ${GC_ADDR[i]}:
done

# create file system storage on the servers and start them.
for i in `seq 1 $GC_NUM_MAX`
do
	ssh ${GC_ADDR[i]} sudo pvfs2-server ./orangefs.conf -f
	ssh ${GC_ADDR[i]} sudo pvfs2-server ./orangefs.conf
done










