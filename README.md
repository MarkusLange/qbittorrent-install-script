A very basic qBitTorrent-nox install script.

Creats user for qBitTorrent, install qBitTorrent from repository, remove login for qBitTorrent and sets a softlink from Downloads to the actuall user
register a systemd service for qBitTorrent, setup apache for port redirection so qBitTorrent can be found under port 80.

This script needs sudo and the used local user added to the group sudo

grep the script file: `wget https://raw.githubusercontent.com/MarkusLange/qbittorrent-install-script/refs/heads/main/basic-qbittorrent-install-script.bash`

make it executable: `chmod +x basic-qbittorrent-install-script.bash`

start the script with: `sudo ./basic-qbittorrent-install-script.bash`

Add a updatefunction to the script with `gitupdate` as first value to the script: `sudo ./basic-qbittorrent-install-script.bash gitupdate`
the script greps a precompiled version of qBitTorrent from https://github.com/userdocs/qbittorrent-nox-static?tab=readme-ov-file and overwrites the
existing one, implemented for armhf, arm64(aarch64) and amd64
