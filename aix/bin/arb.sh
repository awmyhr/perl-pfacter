#!/bin/bash

echo "AIX Repo Build"

BUNDLEFILES='/var/spool/cq_repos/aix/bundles'
RPMFILES='/var/spool/cq_repos/aix/RPMS'

## First get bundle files
for aix in aix53 aix61 aix71; do
    for package in `cat ${BUNDLEFILES}/LIST`; do
        wget -nv ftp://www.oss4aix.org/bundles/${aix}/${package}.${aix}.bundle -O ${BUNDLEFILES}/${package}.${aix}.bundle
    done
done

for aix in aix53 aix61 aix71; do
    cat ${BUNDLEFILES}/*.${aix}.bundle | sort -u -o ${BUNDLEFILES}/ALL.${aix}.bundle
done

## Then get RPMs
for program in `cat ${BUNDLEFILES}/ALL.*| sort -u`; do
    if [ -e ${RPMFILES}/${program} ]; then
        echo ${program} already exists...
    else
        aix=`echo ${program} | perl -pe 's/.+(aix.)\.(.)\.ppc.+/$1$2/'`
        wget -nv ftp://www.oss4aix.org/compatible/${aix}/${program} -O ${RPMFILES}/${program}
    fi
done
