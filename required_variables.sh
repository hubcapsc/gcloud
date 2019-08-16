#!/bin/bash
#
# required_variables.sh
#
# verify that arguments correspond with set variables.
#
for var in "$@"
do
	eval REQ_VAR='$'"$var"
	if [ "$REQ_VAR" = "" ]
	then
		echo $var" not set, can't continue..."
		exit 1
	fi
done
