#!/bin/bash

while getopts "s:n:h:" opt;
do
	case $opt in
	s) service=$OPTARG ;;
	n) hostname=$OPTARG ;;
	h) echo "Usage: create-server -n SERVERNAME -s SERVERTYPE"; exit 1 ;;
	*) echo "Usage: create-server -n SERVERNAME -s SERVERTYPE" ; exit 1 ;;
	esac
done

if [ -z $hostname ];
then
	echo "Must have a hostname set!"
	echo "Usage: create-server -n SERVERNAME -s SERVERTYPE";
	exit 0;
fi

if [ "$service" = "amazon" ];
then
	./create-server-amazon.sh -n $hostname
	exit 1;
fi

if [ "$service" = "rackspace" ];
then
	./create-server-rackspace.sh -n $hostname
	exit 1;
fi

echo "You Must Enter A Service Type -s (either amazon or rackspace)"
exit 1;

