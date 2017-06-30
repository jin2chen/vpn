#!/usr/bin/env bash

ROOT_PATH=$(pwd $(dirname $0))
TMP_DIR=/tmp

source $ROOT_PATH/function

pushd .
cd $ROOT_PATH

apt_get install tree unzip

echo "==Install geoip..."
apt_get install xtables-addons-common libtext-csv-xs-perl
if [[ ! -f $ROOT_PATH/geoip.lock ]]; then
	mkdir -p /usr/share/xt_geoip
	mkdir -p /tmp/geoip
	pushd .
	cd /tmp/geoip
	/usr/lib/xtables-addons/xt_geoip_dl
	/usr/lib/xtables-addons/xt_geoip_build -D /usr/share/xt_geoip *.csv
	touch $ROOT_PATH/geoip.lock
	popd
	rm -rf /tmp/geoip
fi
echo "====Test geoip."
iptables -m geoip --help
echo "==Install geoip done."

echo "==Install shadowsocks-libev..."
dpkg -i deb/libbloom1_1.5-1_amd64.deb
dpkg -i deb/shadowsocks-libev_3.0.7+ds-2_amd64.deb
apt --fix-broken -y install
systemctl stop shadowsocks-libev
systemctl disable shadowsocks-libev
echo "==Install shadowsocks-libev done."

echo "==Install strongswan..."
apt_get install libcharon-standard-plugins libstrongswan libstrongswan-standard-plugins strongswan strongswan-charon strongswan-libcharon strongswan-starter libstrongswan-extra-plugins libcharon-extra-plugins
ipsec statusall
echo "==Install strongswan done."

echo "==Install config..."
sed -e "s/^#DNSStubListener=udp/DNSStubListener=no/" -i /etc/systemd/resolved.conf
sed -e 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' -i /etc/sysctl.conf
cp -rf opt /usr/local
cp -rf systemd/* /lib/systemd/system
cp -rf etc/* /etc/
cp -rf bin/* /usr/local/bin/
systemctl enable dnsforwarder-local.service dnsforwarder-up.service ss-redir.service chinadns.service
systemctl daemon-reload
echo "==Install config done."

popd
