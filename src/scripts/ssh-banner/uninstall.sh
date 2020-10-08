#!/bin/bash
# To UNINSTALL ssh-banner

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

source ./defaults.sh

systemctl disable ssh-banner
rm -r $INSTALL_DIR
rm $SERVICE_DIR/ssh-banner.service
