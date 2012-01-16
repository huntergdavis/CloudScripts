while getopts "n:h:" opt;
do
        case $opt in
        n) hostname=$OPTARG ;;
        h) echo "Usage: create-server-amazon -n SERVERNAME"; exit 1 ;;
        *) echo "Usage: create-server-amazon -n SERVERNAME"; exit 1 ;;
        esac
done

if [ -z $hostname ];
then
        echo "Must have a hostname set!"
        exit 0;
fi


# we must now log into amazon and create a server
# we use the aws controller script for this
# it requires us to have EC2_ACCESS_KEY and EC2_SECRET_KEY environment variables set
echo "Logging into Amazon EC2 using environment variables"
echo "To change this, you will need to replace the EC2_ACCESS_KEY and EC2_SECRET_KEY env variables"

if [ -z "$EC2_ACCESS_KEY" ];
then
	echo "Must have set $EC2_ACCESS_KEY env variable"
	exit 0;
fi

if [ -z "$EC2_SECRET_KEY" ];
then
	echo "Must have set $EC2_SECRET_KEY"
	exit 0;
fi

# uncomment to test if aws is working
#./aws describe-instances

# have aws create a new ssh-key for this new EC2 instance
echo "Adding a new keypair named" $hostname.key
./aws add-keypair $hostname > $hostname.key
chmod 600 ./$hostname.key

# have aws create a new server instance 
echo "Create Server Instance with Security Group MisoServer"
./aws run-instances ami-31814f58 -t m1.small -g MisoServer -k $hostname

# now sleep for a minute while we wait for amazon to setup the server instance
echo "Sleeping for 60 seconds for Amazon setup time"
sleep 60

# list the server and make sure it's connecting using the servername key we passed in
export SERVER_CREATED=`./aws describe-instances | grep $hostname`;

if [ -z "$SERVER_CREATED" ];
then
	echo "Problem With Server Creation";
	echo "Server not Created after 60 seconds";
	echo "Log Into EC2 Console and Debug!";
	echo "response: EC2 ERROR, Not Created"
	exit 0;
fi

# use AWK to pull out the new server name
export SERVERNAME=`echo $SERVER_CREATED | awk -F"|" '{print $6}'`

# print the server name for the script
echo "response: $SERVERNAME"
exit 1;
