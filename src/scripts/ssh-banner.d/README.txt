/bin/bash required for install.sh script
ssh-banner.sh script works with /bin/sh

Before running install.sh, make sure to add following line into: /etc/ssh/sshd_config

Banner /opt/ssh-banner/ssh_banner

Where "/opt/ssh-banner" is $INSTALL_DIR variable defined in defaults.sh

