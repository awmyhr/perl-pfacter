#!/bin/bash

# exit conditions
EXIT_NOHOSTNAME=85
EXIT_NOIP=86
EXIT_NOENV=87
EXIT_NOUSER=88

#Defaults
db=""

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
   -x       set -x
   -?      show this message
Hostname, IP Address, and AD username are required, the
rest will be inferred as best as possible.

EOF
}
source ./install_functions
##############################################################################
## Parse command line options
while getopts ":h:i:n:g:e:dapsx" opt; do
	case $opt in
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
if [ -z "$user" ]; then
	usage
	exit $EXIT_NOUSER
fi
if [ -z "$hostname"  ]; then
	echo "Must provide hostname"
	exit $EXIT_NOHOSTNAME
fi
if [  -z "$ipaddress" ]; then
	echo "Must provide IP Address"
	exit $EXIT_NOIP
fi

setup_hostname
set_env_domain
setup_network
if [ $? -ne 0 ];then
	echo "Error in setting up network.  Exiting..."
	exit $?
fi
make_swap
rhn_register
join_ad
init_puppet

echo "All done."
exit 0
