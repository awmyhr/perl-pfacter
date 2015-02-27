#!/bin/bash
#
# This script will scan the network and add machines to OMD (check_mk)
#   Original found at: http://lists.mathias-kettner.de/pipermail/checkmk-en/2013-June/009756.htmll
#
##############################################################################
## exit conditions
EXIT_NONETWORK=85
EXIT_NOLIST=86
EXIT_ARGCONFLICT=87
EXIT_NOSITE=88
EXIT_NONMAP=89

##############################################################################
## Usage
function usage {
cat << EOF
usage: $0 [options] <OMD Site>

This script will scan a network and add found hosts to OMD.

OPTIONS:
  -n <network>    Network to scan
                      (Example: 192.168.100.0/24)
  -l <file>       File with list of hosts/IPs
  -d <domain>     DNS Domain to search
                      (Example: example.com)
                      (Default: [none])
  -f <folder>     OMD folder to put new hosts/IPs
                      (Default: _incoming)
  -M              Make changes
  -x     set -x
  -?     show this message
OMD Site and either a list or network are requried.

If the -M option is not set, then the changes will *not*
be made, but the new file will be created in /tmp 

EOF
}

##############################################################################
## Parse command line options
while getopts ":n:d:l:xM" opt; do
  case $opt in
    n) NETWORK=$OPTARG
       ;;
    l) LIST=$OPTARG
       ;;
    d) DOMAIN=$OPTARG
       ;;
    f) FOLDER=$OPTARG
       ;;
    x) set -x
       ;;
    M) MAKECHANGES=1
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
SITE="$1"

################################################################################
## Check for required paramters before messing with anything
if [ -z "$SITE" ]; then
  usage
  exit $EXIT_NOSITE
fi
if [ -z "$NETWORK" ] && [ -z "$LIST" ]; then
  echo "Must provide a network or list"
  exit $EXIT_NONETWORK
fi
if [ "$NETWORK" ] && [ "$LIST" ]; then
  echo "Must provide a network or list, not both."
  exit $EXIT_ARGCONFLICT
fi
if [ -z "$DOMAIN" ]; then
  DOMAIN=""
fi
if [ -z "$FOLDER" ]; then
  FOLDER="_incoming"
fi

################################################################################
## Directories and files to work with
SITEPATH="/omd/sites/$SITE/etc/check_mk/conf.d/wato"
WATO="$SITEPATH/$FOLDER/hosts.mk"
INLIST_RAW="/tmp/cmk_rawlist.txt"
INLIST_CLEAN="/tmp/cmk_cleanlist.txt"
WF_NEW="/tmp/cmk_wf_new.txt"
WF_TMP="/tmp/cmk_wf_tmp.txt"
WF_PREV="/tmp/cmk_wf_prev.txt"
WF_REPORT="/tmp/cmk_wf_report.txt"

# Clean up work files
rm -rf $INLIST_RAW $INLIST_CLEAN $WF_NEW $WF_TMP $WF_PREV $WF_REPORT

################################################################################
## Scan the network for new hosts or read list and create INLIST_CLEAN.
if [ "$NETWORK" ]; then
  if [ ! -x `which nmap` ]; then
    echo "can not find nmap"
    exit EXIT_NONMAP
  fi
  nmap -v -sP $NETWORK > $INLIST_RAW
  if [ "$DOMAIN" ]; then
    IFS=$'\r\n' RESULTS=($(cat $INLIST_RAW | grep $DOMAIN | cut -d " " -f 5 | sed "s/\.[a-zA-Z]\+//g"))
  else
    IFS=$'\r\n' RESULTS=($(cat $INLIST_RAW | grep "Nmap scan report" | grep -v "host down" | cut -d " " -f 5 | sed "s/\.[a-zA-Z]\+//g"))
  fi
else
  if [ ! -f "$LIST" ]; then
    echo "$LIST does not exist."
    exit $EXIT_NOLIST
  fi
  IFS=$'\r\n' RESULTS=($(cat $LIST))
fi

TOTAL=${#RESULTS[@]}
if [ $TOTAL -eq 0 ]; then
  echo "no hosts/IPs found"
  exit
fi

touch $INLIST_CLEAN
for (( i=0; i<${TOTAL}; i++ )); do
  echo "${RESULTS[$i]}" >> $INLIST_CLEAN
done

################################################################################
## Build a new config file in tmp
find $SITEPATH -name hosts.mk -exec cat {} ";"|grep -v "^#" | grep -v "^$" | grep '  "' >$WF_PREV

if [ -f $WATO ]; then
  cp $WATO $WF_NEW
else
  cat >$WF_NEW <<EOF
# Written by WATO
# encoding: utf-8

all_hosts += [
]


# Host attributes (needed for WATO)
host_attributes.update(
{})

EOF
fi

for (( i=0; i<${TOTAL}; i++ )); do
  # Check for hosts that users had already added to the system - Can't have them listed twice!
  CHECK=`cat $WF_PREV |grep ${RESULTS[$i]} | wc -l`
  if [ $CHECK -eq 0 ]; then
    sed -e "/all_hosts/a \ \ \"${RESULTS[$i]}|ping|test|lan|tcp|wato|\/\" + FOLDER_PATH + \"\/\","  $WF_NEW > $WF_TMP
    mv $WF_TMP $WF_NEW
    echo "added: ${RESULTS[$i]}" >> $WF_REPORT
  else
    echo "not added: ${RESULTS[$i]}" >> $WF_REPORT
  fi
done

################################################################################
## Make changes if requested (-M).
if [ $MAKGECHANGES ]; then
  cp $WF_NEW $WATO
  su - $SITE -c "cmk -IIu"
  omd restart $SITE
fi
