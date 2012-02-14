#!/bin/bash

# this script tests the successful deployment of the other scripts

while getopts "s:h:" opt;
do
        case $opt in
        s) IP_ADDRESS=$OPTARG ;;
        h) echo "Usage: test-script-deployment.sh -s IP_ADDRESS "; exit 1 ;;
        *) echo "Usage: test-script-deployment.sh -s IP_ADDRESS "; exit 1 ;;
        esac
done


echo "Testing that server is running"
ping -c 1 -w 5 $IP_ADDRESS &>/dev/null

if [ "$?" -ne "64" ] ; then
   echo "$IP_ADDRESS is down!  Or not returning 64 bytes (malformed return?) You're fired!!!!11"
   exit 1;
fi

echo "Server IS Running, this is good"

echo "Testing server does not allow root login"
ssh root@$IP_ADDRESS ls > /dev/null

if [ $? -ne 255 ] ; then
   echo "You should get a permission denied error when ssh in as root, there is a problem here!"
   exit 1;
fi

echo "Server does not allow root login or passwords, this is good"