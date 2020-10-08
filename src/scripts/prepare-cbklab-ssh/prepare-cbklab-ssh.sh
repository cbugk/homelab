#!/bin/bash
# Note that rsa keys produced through ssh-keygen are used

SSH_DIR="./cbklab"
SSH_PUB="cbklab.pub"
SSH_PRIV="cbklab.ssh"
CHMOD_AUTH_KEYS=600	#set 0 (zero) to disable
CHMOD_SSH_PRIV=400	#set to one of 400 or 600

USER=("root" "cbkadm" "nonexistinguser")
CP_SSH_PRIV=(1 1 0)	#whether to copy private ssh key to correspending users ~/.ssh directory

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
echo "Script directory: $(pwd)"

# Get user home directories into the array HOME (e.g. "/home/myuser")
HOME=()
for user in ${USER[@]}; do
	user_home=$(awk -F':' -v v="$user" '{if ($1==v) print $6}' /etc/passwd)
	if [ $user_home ]; then
		HOME+=( $user_home )
	else
		HOME+=( "" )
	fi
done

# Append to authorized_keys, copy private key if desired
for (( ii=0; ii<${#HOME[@]}; ii++)); do
	if [ ${HOME[$ii]} ]; then
		echo -e "User: ${USER[$ii]}"
		# make sure ~/.ssh directory exists                 (does not disturb permissions/ownership)
		runuser -l ${USER[$ii]} -c "mkdir -p ~/.ssh"
		# make sure ~/.ssh/authorized_keys file exists      (does not disturb permissions/ownership)
		runuser -l ${USER[$ii]} -c "touch ~/.ssh/authorized_keys"
		# append public ssh key into ~/.ssh/authorized_keys (does not disturb permissions/ownership)
		cat $SSH_DIR/$SSH_PUB >> ${HOME[$ii]}/.ssh/authorized_keys && echo -e "\tPublic key appended"
		# if desired set chmod for ~/.ssh/authorized_keys
		if [ $CHMOD_AUTH_KEYS ]; then chmod $CHMOD_AUTH_KEYS ${HOME[$ii]}/.ssh/authorized_keys; fi
		# if desired add private key to user's ~/.ssh directory
		if [ ${CP_SSH_PRIV[$ii]} ]; then runuser -l ${USER[$ii]} -c "touch ~/.ssh/$SSH_PRIV" && cat $SSH_DIR/$SSH_PRIV > ${HOME[$ii]}/.ssh/$SSH_PRIV && chmod $CHMOD_SSH_PRIV ${HOME[$ii]}/.ssh/$SSH_PRIV; fi && echo -e "\tPrivate Key copied"
		echo -e "\tDone"
	else
		echo -e "No HOME directory for User: ${USER[$ii]}"
	fi
done

# Restart sshd.service
systemctl restart sshd.service && echo -e "Restarted sshd.service"

# Exit
echo -e "Success"
