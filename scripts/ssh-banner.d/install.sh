#!/bin/bash

# cd into preoject directory
# from homelab/scripts/common.d/script_dir.sh
SCRIPT_PATH=$0
if [ ! -e "$SCRIPT_PATH" ]; then
  case $SCRIPT_PATH in
    (*/*) exit 1;;
    (*) SCRIPT_PATH=$(command -v -- "$SCRIPT_PATH") || exit;;
  esac
fi
SCRIPT_DIR=$(
  cd -P -- "$(dirname -- "$SCRIPT_PATH")" && pwd -P
) || exit
SCRIPT_PATH=$dir/$(basename -- "$SCRIPT_PATH") || exit

cd $SCRIPT_DIR
echo -e "Script directory: $(pwd)"

# Check for figlet
if [ ! $(which figlet) ]; then
	echo "Dependency not found: figlet"
	echo "Try 'apt install figlet'"
	exit 1
fi

# Import default values
source ./defaults.sh

# Update defaults in: ssh-banner.sh
sed -i 's/INSTALL_DIR="\/opt\/ssh-banner"/INSTALL_DIR="'$INSTALL_DIR_ESCAPED'"/' ./ssh-banner.sh

# create installation directory
mkdir -p $INSTALL_DIR
cp ./* $INSTALL_DIR/	#trailing forward-slash is necessary

# cd into installation directory
cd $INSTALL_DIR
echo -e "Changed Dir: "$INSTALL_DIR

# create service file
echo "$SERVICE_DECLARATION" > ./ssh-banner.service

chown root:root ./ssh_banner_header
chown root:root ./ssh_banner_footer
chown root:root ./ssh-banner.sh
chown root:root ./ssh-banner.service

chmod 644 ./ssh_banner_header
chmod 644 ./ssh_banner_footer
chmod 744 ./ssh-banner.sh
chmod 664 ./ssh-banner.service

cp ./ssh-banner.service $SERVICE_DIR/	#trailing forward-slash is necessary


# At this point the line twice bellow must have been added into: /etc/ssh/sshd_config
# as uncommented, and installation directory de-parameterized (see file: ./common.sh).
#Banner $INSTALL_DIR/ssh_banner

systemctl daemon-reload
systemctl enable ssh-banner
systemctl start  ssh-banner

# Incase one wants to rerun script manually
#systemctl restart ssh-banner

# Exit
echo "Exit"
