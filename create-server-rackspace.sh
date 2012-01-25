while getopts "n:h:d:r:" opt;
do
        case $opt in
        n) hostname=$OPTARG ;;
		d) SERVER_SIZE=$OPTARG ;;
		r) RACKSPACE_INSTANCE_NAME=$OPTARG ;;
        h) echo "Usage: create-server-rackspace -n SERVERNAME (optional -d 'size' parameter maps to rackspace size option, optional -r 'rackspace VM instance name')"; exit 1 ;;
        *) echo "Usage: create-server-rackspace -n SERVERNAME (optional -d 'size' parameter maps to rackspace size option, optional -r 'rackspace VM instance name')"; exit 1 ;;
        esac
done

if [ -z $hostname ];
then
        echo "Must have a hostname set!"
        exit 0;
fi

# we must now log into rackspace and create a server
# we use the rscurl controller script for this
# it requires us to have RACKSPACE_USERNAME and RACKSPACE_API_KEY environment variables set
echo "Logging into Rackspace using environment variables"
echo "To change this, you will need to replace the RACKSPACE_USERNAME and RACKSPACE_API_KEY env variables"

if [ -z "$RACKSPACE_USERNAME" ];
then
	echo "Must have set RACKSPACE_USERNAME env variable"
	exit 0;
fi

if [ -z "$RACKSPACE_API_KEY" ];
then
	echo "Must have set RACKSPACE_API_KEY"
	exit 0;
fi

# uncomment to test if aws is working
#./rscurl.sh -a $RACKSPACE_API_KEY -u $RACKSPACE_USERNAME -c list-flavors

# set the database argument to 4 (2048 megs) or 6 (8092 megs) for creation
if [ -z "$SERVER_SIZE" ];
then
	echo "Defaulting to default rackspace server size 4 (2048)"
	SERVER_SIZE_ARGUMENT=4;
else
	SERVER_SIZE_ARGUMENT=$SERVER_SIZE;
fi

# set the database argument to 4 (2048 megs) or 6 (8092 megs) for creation
if [ -z "$RACKSPACE_INSTANCE_NAME" ];
then
	echo "Defaulting to default rackspace instance of 118 (centos 32-bit linux)"
	RACKSPACE_INSTANCE_ARGUMENT=118;
else
	RACKSPACE_INSTANCE_ARGUMENT=$RACKSPACE_INSTANCE_NAME;
fi

# have rackspace create a new server instance 
echo "Create Server Instance $hostname"
SERVER_CREATED=`./rscurl.sh -a $RACKSPACE_API_KEY -u $RACKSPACE_USERNAME -c create-server -i $RACKSPACE_INSTANCE_ARGUMENT -f $SERVER_SIZE_ARGUMENT -n $hostname`

#list the server and make sure it's connecting using the servername key we passed in

if [ -z "$SERVER_CREATED" ];
then
	echo "Problem With Server Creation";
	echo "Server not Created on rackspace";
	echo "Log Into Rackspace Console and Debug!";
	echo "Rackspace ERROR, Not Created"
	exit 0;
fi

# use AWK to pull out the new server password
export SERVERNAME=`echo $SERVER_CREATED | awk '{print $20}'`
export SERVERPASS=`echo $SERVER_CREATED | awk '{print $19}'`


# print the server name for the script
echo "IP: $SERVERNAME PASS: $SERVERPASS"
exit 1;
