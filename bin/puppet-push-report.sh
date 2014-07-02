#!/usr/bin/bash

HOME=/home/bofh
HOST=`hostname`
ENVIRONMENT=development
CERT="--cert $HOME/openssl/certs/${HOST}.pem --key $HOME/openssl/private_keys/${HOST}.pem --cacert $HOME/openssl/ca/ca_crt.pem"

rm $HOME/etc/report.yaml

$HOME/bin/preport >$HOME/etc/report.yaml

$HOME/bin/curl $CERT -X PUT -H 'Content-Type: text/yaml' --data-binary @$HOME/etc/report.yaml https://ral-pupmstr01.gpi.com:8140/$ENVIRONMENT/report/${HOST}
