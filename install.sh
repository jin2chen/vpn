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
apt_get install strongswan libstrongswan-extra-plugins
ipsec statusall
echo "==Install strongswan done."

echo "==Build chinadns..."
package=chinadns
package_source=https://github.com/shadowsocks/ChinaDNS/releases/download/1.3.2/chinadns-1.3.2.tar.gz
package_name=chinadns-1.3.2.tar.gz
package_extract_dir=chinadns-1.3.2
rm -rf /tmp/$package
mkdir -p /tmp/$package
pushd .
cd /tmp/$package
wget $package_source -O $package_name
tar zxf $package_name
pushd .
cd $package_extract_dir
./configure --prefix=/usr/local/opt/chinadns
make && make install
popd
popd
rm -rf /tmp/$package
tree /usr/local/opt/chinadns
pushd .
cd /usr/local/opt/chinadns/share
curl 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | grep ipv4 | grep CN | awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > chnroute.txt
popd
echo "==Build chinadns done."

echo "==Build dnsforwarder..."
package=dnsforwarder
package_source=https://codeload.github.com/holmium/dnsforwarder/zip/6
package_name=dnsforwarder-6.zip
package_extract_dir=dnsforwarder-6
rm -rf /tmp/$package
mkdir -p /tmp/$package
pushd .
cd /tmp/$package
wget $package_source -O $package_name
unzip $package_name
pushd .
cd $package_extract_dir
./configure --prefix=/usr/local/opt/dnsforwarder --enable-downloader=wget
make && make install
popd
popd
rm -rf /tmp/$package
tree /usr/local/opt/dnsforwarder
echo "==Build dnsforwarder done."

echo "==Install config..."
sed -e "s/^#DNSStubListener=udp/DNSStubListener=no/" -i /etc/systemd/resolved.conf
sed -e 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' -i /etc/sysctl.conf
cp -rf systemd/* /lib/systemd/system
cp -rf etc/* /etc/
cp -rf bin/* /usr/local/bin/
systemctl enable dnsforwarder-local.service dnsforwarder-up.service ss-redir.service chinadns.service
systemctl daemon-reload
echo "==Install config done."

popd
