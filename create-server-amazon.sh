while getopts "n:h:g:k:a:i:" opt;
do
        case $opt in
        a) AMAZON_INSTANCE_NAME=$OPTARG ;;
        n) hostname=$OPTARG ;;
		g) SECURITY_GROUP_NAME=$OPTARG ;;
		k) SSH_KEY_NAME=$OPTARG ;;
		i) AMAZON_INSTANCE_SIZE=$OPTARG ;;
        h) echo "Usage: create-server-amazon -n SERVERNAME (optional -g security group parameter, optional -k 'public amazon ssh key', optional -a 'amazon ami instance name', optional -i 'amazon instance size')"; exit 1 ;;
        *) echo "Usage: create-server-amazon -n SERVERNAME (optioanl -g security group parameter, optional -k 'public amazon ssh key', optional -a 'amazon ami instance name', optional -i 'amazon instance size')"; exit 1 ;;
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
	echo "Must have set EC2_ACCESS_KEY env variable"
	exit 0;
fi

if [ -z "$EC2_SECRET_KEY" ];
then
	echo "Must have set EC2_SECRET_KEY env variable"
	exit 0;
fi

if [ -z "$SECURITY_GROUP_NAME" ];
then
	echo "Must have set GROUP_NAME env variable or passed it in with -g"
	exit 0;
fi

# uncomment to test if aws is working
#./aws/aws describe-instances

if [ -z "$SSH_KEY_NAME" ];
then
	# have aws create a new ssh-key for this new EC2 instance
	echo "Adding a new keypair named" $hostname.key
	./aws/aws add-keypair $hostname > $hostname.key
	chmod 600 ./$hostname.key
	SSH_KEY_ARGUMENT=" -k $hostname ";
else
	SSH_KEY_ARGUMENT=" -k $SSH_KEY_NAME ";
fi

if [ -z "$AMAZON_INSTANCE_NAME" ];
then
	echo "No Amazon Instance Name Set, set IMAGE_NAME to change, using default 32-bit Amazon Linux AMI: ami-31814f58"
	AMAZON_INSTANCE_NAME="ami-31814f58";
fi

if [ -z "$AMAZON_INSTANCE_SIZE" ];
then
	echo "No Amazon Instance Size Set, using default size m1.small"
	AMAZON_INSTANCE_SIZE="m1.small";
fi

# have aws create a new server instance 
echo "Create Server Instance with Security Group $SECURITY_GROUP_NAME"
RUN_INSTANCE=`./aws/aws run-instances $AMAZON_INSTANCE_NAME -t $AMAZON_INSTANCE_SIZE -g $SECURITY_GROUP_NAME $SSH_KEY_ARGUMENT`

INITIALIZEDNAME=`echo $RUN_INSTANCE | awk -F"|" '{print $18}'`

echo "initialized instance name: $INITIALIZEDNAME"

# now sleep for a minute while we wait for amazon to setup the server instance
echo "Sleeping for 60 seconds for Amazon setup time"
sleep 60;

# list the server and make sure it's connecting using the servername key we passed in
export SERVER_CREATED=`./aws/aws describe-instances | grep $INITIALIZEDNAME | grep running`;

if [ -z "$SERVER_CREATED" ];
then
	echo "Problem With Server Creation";
	echo "Server not Created after 260 seconds";
	echo "Log Into EC2 Console and Debug!";
	echo "EC2 ERROR, Not Created"
	exit 0;
fi

#echo $SERVER_CREATED

# use AWK to pull out the new server name
#export SERVERNAME=`echo $SERVER_CREATED | awk -F"|" '{print $6}'`

# print the server name for the script draft 1
#echo "$SERVERNAME"
#exit 1;

# execute the security script draft 2
echo ./secure-server-amazon.sh -s $INITIALIZEDNAME $SSH_KEY_ARGUMENT 
./secure-server-amazon.sh -s $INITIALIZEDNAME $SSH_KEY_ARGUMENT 
