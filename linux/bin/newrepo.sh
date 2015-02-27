#!/bin/bash
#       Very simple script to create bare git repos

# exit conditions
EXIT_NOREPO=88

# configuration
repodir="${HOME}/repos"

function usage {
cat << EOF
usage: $0 <reponame>

This script will create a bare git repository named <reponame>.git

OPTIONS:
   -d <dir>     Set repo directory
   -x           Set -x
   -?           Show this message

<reponame> is required.
Repo directory defaults to: $repodir

EOF
}

while getopts ":d:x" opt; do
        case $opt in
                d) repodir=$OPTARG
                   ;;
                x) set -x
                   ;;
                ?) usage
                   exit 0
                   ;;
        esac
done
shift $(( OPTIND - 1 ))
repo="$1"

################################################################################
## Check for required paramters before messing with anything
if [ -z "$repo" ]; then
        usage
        exit $EXIT_NOREPO
fi


################################################################################
## Do the work

mkdir -p $repodir/$repo.git
cd $repodir/$repo.git
git --bare init
