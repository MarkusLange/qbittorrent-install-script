#!/bin/bash
#user associated with stdin "who am i"
stdin_user=$(who -m | cut -d' ' -f1)
qbittorrent_user=qbituser

case $1 in
gitupdate)
	architecture=$(dpkg --print-architecture)
	echo "Update qBitTorrent precompiled from git https://github.com/userdocs/qbittorrent-nox-static?tab=readme-ov-file"
	case $architecture in
		armhf)
			wget -q --show-progress https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/armhf-qbittorrent-nox;;
		arm64)
			wget -q --show-progress https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/aarch64-qbittorrent-nox;;
		amd64)
			wget -q --show-progress https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/x86_64-qbittorrent-nox;;
	esac
	
	systemctl stop apache2.service
	systemctl stop qbittorrent.service
	
	mv *-qbittorrent-nox qbittorrent-nox
	chmod 755 qbittorrent-nox
	chown root:root qbittorrent-nox
	mv qbittorrent-nox /usr/bin/qbittorrent-nox
	
	systemctl start qbittorrent.service
	systemctl start apache2.service
	exit 0;;
remove)
	echo "Remove qBitTorrent"
	systemctl stop apache2.service
	systemctl disable apache2.service
	systemctl stop qbittorrent.service
	systemctl disable qbittorrent.service
	systemctl daemon-reload
	
	rm /etc/systemd/system/qbittorrent.service
	rm /etc/apache2/sites-available/qbittorrent.conf
	
	unlink /home/$stdin_user/qBitTorrent
	
	rm -rf /srv/qbittorrent/
	rm -rf /home/$qbittorrent_user/.config/qBittorrent
	
	deluser $stdin_user $qbittorrent_user
	deluser --remove-home $qbittorrent_user
	
	apt-get purge -y qbittorrent-nox apache2
	apt-get -y autoremove
	exit 0;;	
esac

apt-get install -y qbittorrent-nox

adduser --system --group $qbittorrent_user --home /home/$qbittorrent_user
adduser $stdin_user $qbittorrent_user
#usermod --append -G $qbittorrent_user $stdin_user

sudo -u $qbittorrent_user mkdir -p /home/$qbittorrent_user/.config/qBittorrent

mkdir -p /srv/qbittorrent/{download,log,.session,watch/start}
chown -R $qbittorrent_user:$qbittorrent_user /srv/qbittorrent/
chmod -R 770 /srv/qbittorrent/
sudo -u $stdin_user ln -s /srv/qbittorrent/ /home/$stdin_user/qBitTorrent

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
[Application]
FileLogger\Path=/srv/qbittorrent/log

[BitTorrent]
Session\DefaultSavePath=/srv/qbittorrent/download
Session\TorrentExportDirectory=/srv/qbittorrent/.session
Session\QueueingSystemEnabled=false

[LegalNotice]
Accepted=true

[Preferences]
WebUI\AuthSubnetWhitelist=0.0.0.0/0
WebUI\AuthSubnetWhitelistEnabled=true
WebUI\UseUPnP=false
WebUI\LocalHostAuth=false
EOF

cat >/home/$qbittorrent_user/.config/qBittorrent/watched_folders.json <<-EOF
{
    "/srv/qbittorrent/watch/start": {
        "add_torrent_params": {
            "category": "",
            "download_limit": -1,
            "download_path": "",
            "inactive_seeding_time_limit": -2,
            "operating_mode": "AutoManaged",
            "ratio_limit": -2,
            "save_path": "/srv/qbittorrent/download",
            "seeding_time_limit": -2,
            "skip_checking": false,
            "tags": [
            ],
            "upload_limit": -1,
            "use_auto_tmm": false
        },
        "recursive": false
    }
}
EOF

systemctl daemon-reload
systemctl enable qbittorrent.service
systemctl start qbittorrent.service

apt-get -y install apache2
a2enmod proxy
a2enmod proxy_http

systemctl restart apache2.service

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
systemctl reload apache2.service

su - $stdin_user
