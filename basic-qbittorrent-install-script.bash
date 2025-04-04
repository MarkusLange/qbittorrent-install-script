#!/bin/bash
#user associated with stdin "who am i"
stdin_user=$(who -m | cut -d' ' -f1)
qbittorrent_user=qbituser

architecture=$(dpkg --print-architecture)
if [ $1 == "gitupdate" ]
then
	echo "Update qBitTorrent precompiled from git https://github.com/userdocs/qbittorrent-nox-static?tab=readme-ov-file"
	case $architecture in
		armhf)
			wget -q --show-progress https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/armhf-qbittorrent-nox;;
		arm64)
			wget -q --show-progress https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/aarch64-qbittorrent-nox;;
		amd64)
			wget -q --show-progress https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/x86_64-qbittorrent-nox;;
	esac
	
	systemctl stop qbittorrent
	mv x86_64-qbittorrent-nox qbittorrent-nox
	chmod 755 qbittorrent-nox
	chown root:root qbittorrent-nox
	mv qbittorrent-nox /usr/bin/qbittorrent-nox
	systemctl start qbittorrent
	exit 0
fi

apt-get install -y qbittorrent-nox

adduser --system --group $qbittorrent_user --home /home/$qbittorrent_user
adduser $stdin_user $qbittorrent_user
#usermod --append -G $qbittorrent_user $stdin_user

sudo -u $qbittorrent_user mkdir -p /home/$qbittorrent_user/.config/qBittorrent

mkdir -p /srv/Downloads
chown $qbittorrent_user:$qbittorrent_user /srv/Downloads
chmod 770 /srv/Downloads/
sudo -u $stdin_user ln -s /srv/Downloads /home/$stdin_user/Downloads

#https://github.com/qbittorrent/qBittorrent/wiki/Running-qBittorrent-without-X-server-(WebUI-only,-systemd-service-set-up,-Ubuntu-15.04-or-newer)
cat > /etc/systemd/system/qbittorrent.service <<-EOF
[Unit]
Description=qBittorrent-nox service
Documentation=man:qbittorrent-nox(1)
Wants=network-online.target
After=network-online.target nss-lookup.target

[Service]
# if you have systemd < 240 (Ubuntu 18.10 and earlier, for example), you probably want to use Type=simple instead
Type=exec
# change user as needed
User=$qbittorrent_user
UMask=007
# The -d flag should not be used in this setup
ExecStart=/usr/bin/qbittorrent-nox
# uncomment this for versions of qBittorrent < 4.2.0 to set the maximum number of open files to unlimited
#LimitNOFILE=infinity
# uncomment this to use "Network interface" and/or "Optional IP address to bind to" options
# without this binding will fail and qBittorrent's traffic will go through the default route
# AmbientCapabilities=CAP_NET_RAW

[Install]
WantedBy=multi-user.target
EOF

#https://github.com/qbittorrent/qBittorrent/issues/10725#issuecomment-1147650959
cat >/home/$qbittorrent_user/.config/qBittorrent/qBittorrent.conf <<-EOF
[BitTorrent]
Session\DefaultSavePath=/srv/Downloads
Session\QueueingSystemEnabled=false

[LegalNotice]
Accepted=true

[Preferences]
WebUI\AuthSubnetWhitelist=0.0.0.0/0
WebUI\AuthSubnetWhitelistEnabled=true
WebUI\UseUPnP=false
WebUI\LocalHostAuth=false
EOF

systemctl daemon-reload
systemctl enable qbittorrent
systemctl start qbittorrent

apt-get -y install apache2
a2enmod proxy
a2enmod proxy_http

systemctl restart apache2

cat > /etc/apache2/sites-available/qbittorrent.conf << EOF
<VirtualHost *:80>
    ServerAdmin info@node-example.com
    ServerName  node-example.com
    ServerAlias www.node-example.com

    ProxyRequests off

    <Proxy *>
            Order deny,allow
            Allow from all
    </Proxy>

    <Location />
            ProxyPass http://localhost:8080/
            ProxyPassReverse http://localhost:8080/
    </Location>

</VirtualHost>
EOF

a2dissite 000-default.conf
a2ensite qbittorrent.conf
systemctl reload apache2

su - $stdin_user
