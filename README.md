A very basic qBitTorrent-nox install script, for debian, and debian based linux

Creats user for qBitTorrent, install qBitTorrent from repository, remove login for qBitTorrent and sets a softlink from qBitTorrent to the actuall user,
register a systemd service for qBitTorrent, setup apache2 for port redirection so qBitTorrent can be found under port 80.

This script needs sudo and the used local user added to the group sudo

grep the script file: `wget https://raw.githubusercontent.com/MarkusLange/qbittorrent-install-script/refs/heads/main/basic-qbittorrent-install-script.bash`<br />
make it executable: `chmod +x basic-qbittorrent-install-script.bash`<br />
start the script with: `sudo ./basic-qbittorrent-install-script.bash`<br />

Add a update-function to the script with `--gitupdate` as first value to the script: `sudo ./basic-qbittorrent-install-script.bash --gitupdate`
the script greps a precompiled version of qBitTorrent from https://github.com/userdocs/qbittorrent-nox-static?tab=readme-ov-file and overwrites the
existing one, implemented for armhf, arm64(aarch64) and amd64

Add a remove-function to the script with `--remove` as first value to the script: `sudo ./basic-qbittorrent-install-script.bash --remove`
the script removes everthing installed before

Add a reinstall-function to the script with `--reinstall` as first value to the script: `sudo ./basic-qbittorrent-install-script.bash --reinstall`
the script reinstalls the repository version from qBitTorrent-nox

<pre>
Parameters:  
  --install,            install qBitTorrent-nox on the system  
  --gitupdate,          grep the latest release from qbittorrent-nox-static  
  --remove,             removes qBitTorrent from the system  
  --reinstall,          reinstall qBitTorrent-nox to the repository version  
</pre>
