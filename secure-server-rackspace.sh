#!/bin/bash
# this sript disables password authentication on amazon servers

while getopts "s:h:k:o:" opt;
do
        case $opt in
        s) INSTANCE_ID=$OPTARG ;;
        k) keylocation=$OPTARG ;;
        o) hostname=$OPTARG ;;
        h) echo "Usage: secure-server-amazon.sh -s instance_id -k security.key"; exit 1 ;;
        *) echo "Usage: secure-server-amazon.sh -s instance_id -k security.key"; exit 1 ;;
        esac
done

echo "Rebooting instance for new security"
echo ./aws/aws reboot-instances $INSTANCE_ID

# now sleep for a minute while we wait for amazon to setup the server instance
echo "Sleeping for 60 seconds for Amazon reboot instance time"
echo sleep 60

SERVERADDRESS=`./aws/aws describe-instances | grep $INSTANCE_ID | awk -F"|" '{print $14}'`;

export SSHCOMMAND="ssh -t -o StrictHostKeyChecking=no -q -i $keylocation.key -l ec2-user $SERVERADDRESS "
HOSTNAMETEST=`$SSHCOMMAND sudo hostname | grep tty`

if [ -n "${HOSTNAMETEST}" ];
then
        echo "You need to change the security setup script, sudo over tty needs to be enabled with -t parameter."
        exit 1;
fi

echo "Amazon security setup finished"