#!/bin/bash

#Defaults
db=""
ad=0
swap=0
puppet=0
register=0

function usage {
cat << EOF
usage: $0 [options] <AD username>

This script will do a postinstall configuration of the host.
It sets network configuration, registers with Satellite,
joins the host to the AD domain, and initilized Puppet.

OPTIONS:
   -h <hostname>    New hostname
   -i <IP addr>     New ipaddress
   -n <netmask>     New netmask
                        (default: 255.255.255.0)
   -g <gateway>     New gateway
                        (default: change last octat of IP to .1)
   -e <env>         environment [dev|qa|prod]
                        (default: hostname before first '-')
   -d       Host is a Percona DB server
   -a       Whether to join AD or not, default is not
   -s       Whether to set swap or not, default is not
   -p       Whether to join puppet or not, default is not
   -r       Whether to register with satellite or not, default is not
   -x       set -x
   -?      show this message
Hostname, IP Address, and AD username are required, the
rest will be inferred as best as possible.

EOF
}
source ./install_functions
################################################################################
## Parse command line options
while getopts ":h:i:n:g:e:darpsx" opt; do
	case $opt in
                a) ad=1;
                   ;;
                h) hostname=$OPTARG
                   ;;
                i) ipaddress=$OPTARG
                   ;;
                n) netmask=$OPTARG
                   ;;
                g) gw=$OPTARG
                   ;;
                e) env=$OPTARG
                   ;;
                d) db="-db"
                   ;;
                p) puppet=1
                   ;;
                r) register=1
                   ;;
                s) swap=1
                   ;;
                x) set -x
                   ;;
                ?) usage
                   exit 0
                   ;;
                *) usage
                   exit 1
                   ;;
	esac
done
shift $(( OPTIND - 1 ))
user="$1"

################################################################################
## Check for required paramters before messing with anything
if [ ! -z "$hostname"  ]; then
	echo "Hostname provided"
	setup_hostname
else
    echo "No hostname provided.."
    hostname=`hostname -s`
    echo "Hostname is $hostname"
fi
set_env_domain
if [ ! -z "$ipaddress" ]; then
	echo "IP address provided"
	setup_network
	if [ $? -ne 0 ];then
		echo "Network Error.  Exiting..."
		exit $EXIT_NONETWORK
	fi
fi
if [ $swap -ne 0 ];then
	make_swap
fi
if [ $register -ne 0 ];then
	rhn_register
	if [ $? -ne 0 ];then
		echo "Registration Error. Exiting..."
		exit $EXIT_NOENV
	fi
fi
if [ $ad -ne 0 ];then
	join_ad
	if [ $? -ne 0 ];then
		echo "Error joining the domain.";
		exit $EXIT_NODOMAIN
	fi
fi
if [ $puppet -ne 0 ];then
	init_puppet
fi

echo "All done."
exit 0
