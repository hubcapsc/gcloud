#!/bin/bash
#
# Run a command to test that the named host (this object) seems to function.
# Make GC_NUM attempts to run the command.
#   $1 = this object's name
#   $2 = number of times to test this object before giving up

#
# Obtain this object's external IP address.
#
GC_THIS_OBJECT=$1
LIST_PART1=$GC_BIN"/gcloud compute instances list "
LIST_PART2="--filter=\"name~"$GC_THIS_OBJECT"\" "
LIST_PART3="--format \"get(networkInterfaces[0].accessConfigs[0].natIP)\""
CMD=$LIST_PART1$LIST_PART2$LIST_PART3

#
GC_NUM=$2
if [ -z "$GC_NUM" ]; then GC_NUM=1; fi
if ! [[ "$GC_NUM" =~ ^[0-9]+$ ]]
then
	echo ":"$GC_NUM": isn't an integer"
	exit 1
fi
#
# They might create N servers. We'll keep the IP addresses of the servers
# in an array, where the IP address of the nth server is in GC_ADDR[n].
# We don't know the value of n, but bash will tell us how many elements are
# already in GC_ADDR with ${#GC_ADDR[@]}, so we can always compute which
# element to store this object's IP address in. Bash arrays are 0 based,
# but we don't want to use the 0th element since people who want six
# servers will get server1,server2,...,server6.
#
GC_FREE=${#GC_ADDR[@]}
GC_FREE=$GC_FREE+1

#
for j in `seq 1 $GC_NUM`
do
        #GC_ADDR[GC_FREE]=`eval $CMD | tail -1 | awk '{ print $5 }'`
        GC_ADDR[GC_FREE]=`eval $CMD`
        if [ -n "${GC_ADDR[GC_FREE]}" ]
        then
		#
		# gcloud IP addresses might get reused. If the address
		# of this host we just created is alread in the known_hosts
		# file, remove it.
		#
		GC_SED="sed -i '/^"${GC_ADDR[GC_FREE]}"/d' ~/.ssh/known_hosts"
		eval $GC_SED

                ssh -q -o "StrictHostKeyChecking no" \
			-o "PasswordAuthentication no" \
			${GC_ADDR[GC_FREE]} uptime
                if [ $? = 0 ]; then break; fi
        fi
        if [ $j = $GC_NUM ]
        then
                echo "ssh to :"${GC_ADDR[GC_FREE]}": failed :"$GC_NUM": times."
		# call cleanup script here
                exit 1
        fi
        sleep 5
done
echo
