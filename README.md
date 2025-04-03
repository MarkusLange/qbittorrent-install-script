A very basic qBitTorrent-nox install script.

Creats user for qBitTorrent, install qBitTorrent from repository, remove login for qBitTorrent and sets a softlink from Downloads to the actuall user
register a systemd service for qBitTorrent, setup apache for port redirection so qBitTorrent can be found under port 80.

This script needs sudo and the used local user added to the group sudo

grep the script file: `wget https://raw.githubusercontent.com/MarkusLange/qbittorrent-install-script/main/qbittorrent-install-script`

make it executable: `chmod +x qbittorrent-install-script`

start the GUI with: `sudo ./qbittorrent-install-script`
