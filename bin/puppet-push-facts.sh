#!/usr/bin/bash

HOME=/home/bofh
HOST=`hostname`
PUPDIR=$HOME/etc/puppet
ENVIRONMENT=`cat $PUPDIR/orgenv`
CERT="--cert $HOME/openssl/certs/${HOST}.pem --key $HOME/openssl/private_keys/${HOST}.pem --cacert $HOME/openssl/ca/ca_crt.pem"

if [ ! -d $PUPDIR ]; then
    mkdir -p $PUPDIR
fi

rm $PUPDIR/facts.old.md5
$HOME/bin/openssl dgst -md5 $PUPDIR/facts.yaml | cut -d" " -f2 >$PUPDIR/facts.old.md5

rm $PUPDIR/facts.yaml
/usr/local/bin/sudo $HOME/bin/pfacter --puppet >$PUPDIR/facts.yaml

rm $PUPDIR/facts.new.md5
$HOME/bin/openssl dgst -md5 $PUPDIR/facts.yaml | cut -d" " -f2 >$PUPDIR/facts.new.md5

$HOME/bin/curl $CERT -X PUT -H 'Content-Type: text/yaml' --data-binary @$PUPDIR/facts.yaml https://ral-pupmstr01.gpi.com:8140/$ENVIRONMENT/facts/${HOST}
