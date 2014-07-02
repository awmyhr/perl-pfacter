#!/usr/bin/bash

HOME=/home/bofh
HOST=`hostname`
ENVIRONMENT=`cat /etc/environment`
CERT="--cert $HOME/openssl/certs/${HOST}.pem --key $HOME/openssl/private_keys/${HOST}.pem --cacert $HOME/openssl/ca/ca_crt.pem"

rm $HOME/etc/facts.yaml

/usr/local/bin/sudo $HOME/bin/pfacter --puppet >$HOME/etc/facts.yaml

$HOME/bin/curl $CERT -X PUT -H 'Content-Type: text/yaml' --data-binary @$HOME/etc/facts.yaml https://ral-pupmstr01.gpi.com:8140/$ENVIRONMENT/facts/${HOST}
