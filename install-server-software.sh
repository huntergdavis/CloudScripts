#!/bin/bash
# This is an install server software script

while getopts "s:h:k:u:p:n:" opt;
do
        case $opt in
        s) serveraddress=$OPTARG ;;
        k) keylocation=$OPTARG ;;
        u) CLOUDKICK_OATH_KEY=$OPTARG ;;
        p) CLOUDKICK_OATH_SECRET=$OPTARG ;;
        n) NEWRELIC_LICENSE_KEY=$OPTARG ;;
        h) echo "Usage: install-server-software -s SERVER_IP_ADRESS -k security.key (optional -u CLOUDKICK_OATH_KEY -p CLOUDKICK_OATH_SECRET -n NEWRELIC_LICENSE_KEY)"; exit 1 ;;
        *) echo "Usage: install-server-software -s SERVER_IP_ADRESS -k security.key (optional -u CLOUDKICK_OATH_KEY -p CLOUDKICK_OATH_SECRET -n NEWRELIC_LICENSE_KEY)"; exit 1 ;;
        esac
done

if [ -z $serveraddress ];
then
        echo "Must have a server address set!"
        exit 0;
fi

if [ -z $keylocation ];
then
        echo "Must pass in a public key location or you will be unable to connect!"
        exit 0;
fi

export SSHCOMMAND="ssh -o StrictHostKeyChecking=no -q -i $keylocation ec2-user@$serveraddress "

# test that our connection works

HOSTNAMETEST=`$SSHCOMMAND sudo hostname | grep tty`


if [ -n "${HOSTNAMETEST}" ];
then
        echo "You need to run the security setup script, sudo over tty needs to be enabled."
        exit 1;
fi

if [ -z "$CLOUDKICK_OATH_KEY" ];
then
	echo "Must have set CLOUDKICK_OATH_KEY env variable or passed -u"
	exit 0;
fi

if [ -z "$CLOUDKICK_OATH_SECRET" ];
then
	echo "Must have set CLOUDKICK_OATH_SECRET env variable or passed -p"
	exit 0;
fi

if [ -z "$NEWRELIC_LICENSE_KEY" ];
then
	echo "Must have set NEWRELIC_LICENSE_KEY env variable or passed -n"
	exit 0;
fi

# first we will update the server software with the newest updates from yum
echo "Updating Server Software"
$SSHCOMMAND sudo yum -y update 

# next we will install gcc, make, openssl, git, apache, php, mysql
echo "installing pre-requisites with yum"
$SSHCOMMAND sudo yum -y install gcc-c++ make openssl-devel git httpd mod_ssl php php-common php-devel php-mysql mysql php-dba php-gd php-pdo php-mbstring php-pear php-xml php-xmlrpc libmemcached

# install php memcache
echo "install php memcache"
$SSHCOMMAND "sudo pecl -q install memcache < <(yes y)"

# set up memcache extension ini
echo extension=memcache.so > ./memcache.ini
scp -q  -i $keylocation ./memcache.ini ec2-user@$serveraddress:~/memcache.ini
rm -f ./memcache.ini
$SSHCOMMAND sudo mv ./memcache.ini /etc/php.d/memcache.ini

# copy php.ini locally so we may remove the short_open_tag line
scp -q -i $keylocation ec2-user@$serveraddress:/etc/php.ini ./php.ini
cat ./php.ini | grep -v short_open_tag > ./php.ini.2
echo short_open_tag = On >> ./php.ini.2
rm ./php.ini
mv ./php.ini.2 ./php.ini
scp -q  -i $keylocation ./php.ini ec2-user@$serveraddress:~/php.ini
rm ./php.ini
$SSHCOMMAND sudo mv ./php.ini /etc/php.ini

# start apache
echo "starting apache"
$SSHCOMMAND sudo /etc/init.d/httpd start

# make sure apache is always started after reboot
$SSHCOMMAND sudo chkconfig --level 2345 httpd on

# create a script that sets up node
echo "Setting Up Node.JS"
echo git clone git://github.com/joyent/node.git >> ./setupnode.sh
echo cd node >> ./setupnode.sh
echo git checkout v0.6.3 >> ./setupnode.sh
echo ./configure >> ./setupnode.sh
echo make >> ./setupnode.sh
echo sudo make install >> ./setupnode.sh
echo cd .. >> ./setupnode.sh
echo sudo ln -s /usr/local/bin/node /usr/bin/node >> ./setupnode.sh
echo sudo ln -s /usr/local/lib/node /usr/lib/node >> ./setupnode.sh
echo sudo ln -s /usr/local/bin/node-waf /usr/bin/node-waf >> ./setupnode.sh

# execute the node setup script on server and remove it from local directory
scp -q -i $keylocation ./setupnode.sh ec2-user@$serveraddress:~/setupnode.sh
rm ./setupnode.sh 
$SSHCOMMAND chmod +x /home/ec2-user/setupnode.sh
$SSHCOMMAND /home/ec2-user/setupnode.sh
$SSHCOMMAND rm /home/ec2-user/setupnode.sh

# setup npm and express on server
echo "Setting up NPM and Express"
echo git clone git://github.com/isaacs/npm.git >> setupnpm.sh
echo cd npm >> setupnpm.sh
echo ./configure >> setupnpm.sh
echo make >> setupnpm.sh
echo sudo make install >> setupnpm.sh
echo cd .. >> setupnpm.sh
echo sudo npm install express  >> setupnpm.sh
echo sudo ln -s /usr/local/bin/npm /usr/bin/npm >> setupnpm.sh
echo sudo ln -s ~/node_modules /usr/bin/node_modules >> setupnpm.sh

# execute the npm and express setup script on server and remove it from local and remote directory
scp -q -i $keylocation ./setupnpm.sh ec2-user@$serveraddress:~/setupnpm.sh
rm ./setupnpm.sh 
$SSHCOMMAND chmod +x /home/ec2-user/setupnpm.sh
$SSHCOMMAND /home/ec2-user/setupnpm.sh
$SSHCOMMAND rm /home/ec2-user/setupnpm.sh

# prep cloudkick repo file
echo "Setting up cloudkick"
echo [cloudkick] >> cloudkick.repo
echo name=Cloudkick >> cloudkick.repo
echo baseurl=http://packages.cloudkick.com/amazon/i386 >> cloudkick.repo
echo gpgcheck=0 >> cloudkick.repo

# configuration of cloudkick repo and installation
scp -q -i $keylocation ./cloudkick.repo ec2-user@$serveraddress:~/cloudkick.repo
rm ./cloudkick.repo
$SSHCOMMAND sudo mv /home/ec2-user/cloudkick.repo /etc/yum.repos.d/cloudkick.repo
$SSHCOMMAND sudo yum install -y cloudkick-agent

# generate the cloudkick configuration file
echo "#" >> ./cloudkick.conf
echo "# Cloudkick Congfiguration" >> ./cloudkick.conf
echo "#" >> ./cloudkick.conf
echo "# See the following URL for the most up to date documentation:" >> ./cloudkick.conf
echo "#   https://support.cloudkick.com/Agent/Cloudkick.conf" >> ./cloudkick.conf
echo "#" >> ./cloudkick.conf
echo "# The keys in cloudkick.conf are tied to your entire account," >> ./cloudkick.conf
echo "# so you can deploy the same file across all of your machines." >> ./cloudkick.conf
echo "#" >> ./cloudkick.conf
echo "# oAuth consumer key" >> ./cloudkick.conf
echo "oauth_key $CLOUDKICK_OATH_KEY" >> ./cloudkick.conf
echo "# oAuth consumer secret" >> ./cloudkick.conf
echo "oauth_secret $CLOUDKICK_OATH_SECRET" >> ./cloudkick.conf
echo "# Path to a directory containing custom agent plugins" >> ./cloudkick.conf
echo "local_plugins_path /usr/lib/cloudkick-agent/plugins/" >> ./cloudkick.conf

# copy over the cloudkick configuration
scp -q -i $keylocation ./cloudkick.conf ec2-user@$serveraddress:~/cloudkick.conf
rm ./cloudkick.conf
$SSHCOMMAND sudo mv /home/ec2-user/cloudkick.conf /etc/cloudkick.conf
$SSHCOMMAND sudo chkconfig cloudkick-agent on
$SSHCOMMAND sudo service cloudkick-agent start

# install new relic agent
echo "setting up new relic agent"
$SSHCOMMAND sudo rpm -Uvh http://yum.newrelic.com/pub/newrelic/el5/i386/newrelic-repo-5-3.noarch.rpm
$SSHCOMMAND sudo yum install -y newrelic-sysmond
$SSHCOMMAND sudo nrsysmond-config --set license_key=$NEWRELIC_LICENSE_KEY
$SSHCOMMAND sudo /etc/init.d/newrelic-sysmond start
$SSHCOMMAND sudo yum install -y newrelic-php5
$SSHCOMMAND sudo newrelic-install install 

# copy the newrelic config to local
$SSHCOMMAND sudo cp /etc/newrelic/newrelic.cfg /home/ec2-user/newrelic.cfg 
$SSHCOMMAND sudo chmod 777 /home/ec2-user/newrelic.cfg
scp -q -i $keylocation ec2-user@$serveraddress:/home/ec2-user/newrelic.cfg ./newrelic.cfg
cat ./newrelic.cfg | grep -v license_key > ./newrelic.new
echo license_key=$NEWRELIC_LICENSE_KEY >> ./newrelic.new
rm ./newrelic.cfg
mv ./newrelic.new ./newrelic.cfg
scp -q  -i $keylocation ./newrelic.cfg ec2-user@$serveraddress:/home/ec2-user/newrelic.cfg
rm ./newrelic.cfg
$SSHCOMMAND sudo mv /home/ec2-user/newrelic.cfg /etc/newrelic/newrelic.cfg 
$SSHCOMMAND sudo /etc/init.d/newrelic-daemon restart
$SSHCOMMAND sudo /etc/init.d/httpd restart
echo "Completion successful - install server software successfully completed"
