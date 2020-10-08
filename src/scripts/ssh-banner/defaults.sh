INSTALL_DIR="/opt/ssh-banner"
INSTALL_DIR_ESCAPED="\/opt\/ssh-banner"

SERVICE_DIR="/etc/systemd/system"

SERVICE_DECLARATION="# /etc/systemd/system/ssh-banner.service
[Unit]
After=network.service

[Service]
ExecStart="$INSTALL_DIR"/ssh-banner.sh

[Install]
WantedBy=default.target
"
