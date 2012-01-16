while getopts "n:h:" opt;
do
        case $opt in
        n) hostname=$OPTARG ;;
        h) echo "Usage: create-server-rackspace -n SERVERNAME"; exit 1 ;;
        *) echo "Usage: create-server-rackspace -n SERVERNAME"; exit 1 ;;
        esac
done

if [ -z $hostname ];
then
        echo "Must have a hostname set!"
        exit 0;
fi

