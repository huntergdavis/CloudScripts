#!/bin/bash

while getopts "s:n:h:g:k:a:i:d:r:" opt;
do
	case $opt in
	a) AMAZON_INSTANCE="-a $OPTARG" ;;
	d) RACKSPACE_SERVER_SIZE="-d $OPTARG" ;;
	s) service=$OPTARG ;;
	n) hostname=$OPTARG ;;
	g) SECURITY_GROUP_NAME=$OPTARG ;;
	i) AMAZON_INSTANCE_SIZE=" -i $OPTARG" ;;
	k) PUBLIC_KEY=$OPTARG ;;
	r) RACKSPACE_INSTANCE_NAME="-r $OPTARG" ;;
	h) echo "Usage: create-server -n SERVERNAME -s SERVERTYPE (optional -d 'rackspace instance size', optional -g 'amazon security group name', optional -k 'public amazon/rackspace ssh key', optional -a 'amazon ami instance name', optional -i 'amazon instance size', optional -r 'rackspace VM instance name')"; exit 1 ;;
	*) echo "Usage: create-server -n SERVERNAME -s SERVERTYPE (optional -d 'rackspace instance size', optional -g 'amazon security group name', optional -k 'public amazon/rackspace ssh key', optional -a 'amazon ami instance name', optional -i 'amazon instance size', optional -r 'rackspace VM instance name')" ; exit 1 ;;
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
        ./create-server-rackspace.sh -n $hostname $RACKSPACE_SERVER_SIZE $RACKSPACE_INSTANCE_NAME -k $PUBLIC_KEY
        exit 1;
fi

if [ -z "$PUBLIC_KEY" ];
then
	KEYARG="";
else
	KEYARG=" -k $PUBLIC_KEY"
fi


if [ "$service" = "amazon" ];
then
	./create-server-amazon.sh -n $hostname -g $SECURITY_GROUP_NAME $KEYARG $AMAZON_INSTANCE $AMAZON_INSTANCE_SIZE
	exit 1;
fi

echo "You Must Enter A Service Type -s (either amazon or rackspace)"
exit 1;

