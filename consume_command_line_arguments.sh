#!/bin/bash
#
# consume_command_line_arguments.sh
#
# The last argument is the name of the google cloud object.
#
# The other ones must be some kind of command options :-)
#
if [ "$1" = "" ]
then
	echo "USAGE: "$0" [args] gc-object"
	echo "-aX	X = max number of verification attempts"
	echo "-iX	X = number of io servers"
	echo "-mX	X = number of metadata servers"
	exit 1
fi

ARGNUM=1
while [ "$ARGNUM" -le "$#" ]
do

	CMD="THIS_ARG=$"$ARGNUM
	eval $CMD
	if [ "$#" = "$ARGNUM" ]
	then
		if [ "${THIS_ARG:0:1}" = "-" ]
		then
			echo "name can't start with a dash."
			exit 1
		else
			GC_OBJECT=$THIS_ARG
		fi
	else
		if [ "${THIS_ARG:0:1}" != "-" ]
		then
			echo "args need dashes..."
			exit 1
		else
			#
			# arguments: dash, letter, value - no spaces...
			#
			# args:
			# -aX     X = max number of verification attempts
			# -iX     X = number of io servers
			# -mX     X = number of metadata servers
			#
			case ${THIS_ARG:1:1} in
				a)	GC_NUM_ATTEMPTS=${THIS_ARG:2}
					;;
				i)	GC_NUM_IO=${THIS_ARG:2}
					;;
				m)	GC_NUM_META=${THIS_ARG:2}
					;;
				*)	echo "unknown arg:"${THIS_ARG:1:1}":"
					exit 1
					;;
			esac
		fi
	fi

	ARGNUM=$((ARGNUM + 1))
done
