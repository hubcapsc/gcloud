#!/bin/bash
#
# This script will try to shutdown servers $1i, $1j, $1k, ... , $1n.
# i = 1, j = 2 and so on. The script exits when ever it tries to shutdown
# a server that doesn't exist.
#

GC_OBJECT=$1
if [ "$GC_OBJECT" = "" ]
then
	echo "USAGE: "$0" object-name"
	exit 1
fi

. ./default_set_up.sh
. ./required_variables.sh GC_BIN GC_ZONE GC_OBJECT

for((i=1; ;++i)); do
	$GC_BIN/gcloud compute instances stop --zone="$GC_ZONE" $GC_OBJECT$i
	if [ $? != "0" ]; then break; fi
	$GC_BIN/gcloud compute instances delete --zone="$GC_ZONE" \
		--quiet $GC_OBJECT$i
done

$GC_BIN/gcloud compute instances list --filter="name~hubcap"
