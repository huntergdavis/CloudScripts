#!/bin/bash
# this sript disables password authentication on amazon servers

while getopts "s:h:k:o:p:" opt;
do
        case $opt in
        s) IP_ADDRESS=$OPTARG ;;
        k) keylocation=$OPTARG ;;
        o) hostname=$OPTARG ;;
        p) password=$OPTARG ;;
        h) echo "Usage: secure-server-rackspace.sh -s IP_ADDRESS -p PASSWORD -k security_key_name (must have .pub and .key keyfile)"; exit 1 ;;
        *) echo "Usage: secure-server-rackspace.sh -s IP_ADDRESS -p PASSWORD -k security_key_name (must have .pub and .key keyfile)"; exit 1 ;;
        esac
done


# set a variable for the public key
PUBLIC_KEY=`cat $keylocation.pub`;

# clear out the script
rm ./rackspace-expect-script.sh

# first we generate an expect file
echo  "#!/usr/bin/expect -f" >> ./rackspace-expect-script.sh 
echo 'spawn  ssh  -q -oStrictHostKeyChecking=no -oCheckHostIP=no ' "root@$IP_ADDRESS" >> ./rackspace-expect-script.sh 
echo "expect \"password:\"" >> ./rackspace-expect-script.sh 
echo "send \"$password\r\"" >> ./rackspace-expect-script.sh 
echo "expect \"*]\"" >> ./rackspace-expect-script.sh 
echo "send \"useradd rackspace-user\r\"" >> ./rackspace-expect-script.sh 
echo "expect \"*]\"" >> ./rackspace-expect-script.sh 
echo "send \"echo \\\"rackspace-user ALL=(ALL) NOPASSWD: ALL\\\" >> /etc/sudoers\r\"" >> ./rackspace-expect-script.sh 
echo "expect \"*]\"" >> ./rackspace-expect-script.sh
echo "send \"cat /etc/ssh/sshd_config | grep -v PasswordAuthentication | grep -v PAM > ./sshd_config \r\"" >> ./rackspace-expect-script.sh  
echo "expect \"*]\"" >> ./rackspace-expect-script.sh 
echo "send \"echo PasswordAuthentication no >> ./sshd_config \r\"" >> ./rackspace-expect-script.sh 
echo "expect \"*]\"" >> ./rackspace-expect-script.sh 
echo "send \"echo RSAAuthentication yes >> ./sshd_config \r\"" >> ./rackspace-expect-script.sh 
echo "expect \"*]\"" >> ./rackspace-expect-script.sh 
echo "send \"echo PubkeyAuthentication yes >> ./sshd_config \r\"" >> ./rackspace-expect-script.sh 
echo "expect \"*]\"" >> ./rackspace-expect-script.sh 
echo "send \"echo AuthorizedKeysFile     .ssh/authorized_keys >> ./sshd_config \r\"" >> ./rackspace-expect-script.sh 
echo "expect \"*]\"" >> ./rackspace-expect-script.sh 
echo "send \"echo PermitRootLogin no >> ./sshd_config \r\"" >> ./rackspace-expect-script.sh 
echo "expect \"*]\"" >> ./rackspace-expect-script.sh 
echo "send \"echo UsePAM no >> ./sshd_config \r\"" >> ./rackspace-expect-script.sh 
echo "expect \"*]\"" >> ./rackspace-expect-script.sh 
echo "send \"cat ./sshd_config > /etc/ssh/sshd_config \r\"" >> ./rackspace-expect-script.sh 
echo "send \"su rackspace-user\r\"" >> ./rackspace-expect-script.sh 
echo "expect \"*]\"" >> ./rackspace-expect-script.sh 
echo "send \"cd \r\"" >> ./rackspace-expect-script.sh 
echo "expect \"*]\"" >> ./rackspace-expect-script.sh 
echo "send \"mkdir .ssh\r\"" >> ./rackspace-expect-script.sh 
echo "expect \"*]\"" >> ./rackspace-expect-script.sh 
echo "send \"touch .ssh/authorized_keys\r\"" >> ./rackspace-expect-script.sh 
echo "expect \"*]\"" >> ./rackspace-expect-script.sh 
echo "send \"echo $PUBLIC_KEY >> .ssh/authorized_keys\r\"" >> ./rackspace-expect-script.sh 
echo "expect \"*]\"" >> ./rackspace-expect-script.sh
echo "send \"chmod 0755 /home/rackspace-user\r\"" >> ./rackspace-expect-script.sh 
echo "expect \"*]\"" >> ./rackspace-expect-script.sh
echo "send \"chmod 0700 .ssh\r\"" >> ./rackspace-expect-script.sh 
echo "expect \"*]\"" >> ./rackspace-expect-script.sh
echo "send \"chmod 0600 .ssh/authorized_keys\r\"" >> ./rackspace-expect-script.sh 
echo "expect \"*]\"" >> ./rackspace-expect-script.sh
echo "send \"exit\r\"" >> ./rackspace-expect-script.sh 
echo "expect \"*]\"" >> ./rackspace-expect-script.sh 
echo "send \"/etc/init.d/sshd reload\r\"" >> ./rackspace-expect-script.sh 

# make sure we exit from the remote script
echo "expect \"*]\"" >> ./rackspace-expect-script.sh 
echo "send \"exit\r\"" >> ./rackspace-expect-script.sh 

chmod +x ./rackspace-expect-script.sh
./rackspace-expect-script.sh

rm ./rackspace-expect-script.sh 

export SSHCOMMAND="ssh -t -o StrictHostKeyChecking=no -q -i $keylocation.key -l rackspace-user $IP_ADDRESS "
HOSTNAMETEST=`$SSHCOMMAND sudo hostname | grep tty`

if [ -n "${HOSTNAMETEST}" ];
then
        echo "You need to ensure your public key has the correct 0700 permissoins"
        exit 1;
fi

echo "Rackspace security setup finished"