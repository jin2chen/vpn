#!/bin/bash
ROOT_DIR=vpn-cert

rm -rf $ROOT_DIR
mkdir $ROOT_DIR
pushd .
cd $ROOT_DIR
# Generate CA
ipsec pki --gen --type rsa --size 4096 --outform pem > CA.key
ipsec pki --self --ca --lifetime 3650 --in CA.key --type rsa \
    --dn "/C=US/ST=Hunan/L=Changsha/O=JinChen/OU=VPN/CN=ca.jinchen.me" --outform pem > CA.pem

# Generate server
ipsec pki --gen --type rsa --size 4096 --outform pem > server.key
ipsec pki --pub --in server.key --type rsa | ipsec pki --issue --lifetime 3650 --cacert CA.pem --cakey CA.key \
    --dn "/C=US/ST=Hunan/L=Changsha/O=JinChen/OU=VPN/CN=vpn.jinchen.me"	--san "vpn.jinchen.me" \
    --flag serverAuth --flag ikeIntermediate --outform pem > server.pem
popd

