#!/bin/bash

while getopts "s:n:h:g:" opt;
do
	case $opt in
	s) service=$OPTARG ;;
	n) hostname=$OPTARG ;;
	g) GROUP_NAME=$OPTARG ;;
	h) echo "Usage: create-server -n SERVERNAME -s SERVERTYPE (optional -g 'amazon security group name')"; exit 1 ;;
	*) echo "Usage: create-server -n SERVERNAME -s SERVERTYPE (optional -g 'amazon security group name')" ; exit 1 ;;
	esac
done

if [ -z "$hostname" ];
then
	echo "Must have a hostname set!"
	echo "Usage: create-server -n SERVERNAME -s SERVERTYPE";
	exit 0;
fi

if [ "$service" = "rackspace" ];
then
        ./create-server-rackspace.sh -n $hostname
        exit 1;
fi

if [ "$service" = "rackspace-db" ];
then
        ./create-server-rackspace.sh -n $hostname -d 1
        exit 1;
fi


if [ -z "$GROUP_NAME" ];
then
	echo "Either set GROUP_NAME env variable or pass -g flag for amazon security group name"
	exit 0;
fi



if [ "$service" = "amazon" ];
then
	./create-server-amazon.sh -n $hostname -g $GROUP_NAME
	exit 1;
fi

echo "You Must Enter A Service Type -s (either amazon or rackspace or rackspace-db)"
exit 1;

