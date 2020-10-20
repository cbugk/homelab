# FOR ARCHIVAL PURPOSES ONLY!
# Templated script of Openshift Origin 3.11 installation on Google Cloud Platform
# spanning mostly pre-COVID19 period of 2020-spring semester.

# Source(s):
#   [tag:server-world]  https://www.server-world.info/en/note?os=CentOS_7&p=openshift311&f=1

# You are ADVISED TO DELETE HISTORY at least, or plain passwords will hurt the system inevitably
# Proper scripting practices were not put into use for this PROOF OF CONCEPT
# Thus, proper security patches are expected from those intrested in the code. Yet, it would
# be orders of magnitude easier to start from scratch, and not so wise just for Openshift Origin 3.11
# as OKD4 is out.i You are more than welcome to visit [source:server-world] instead.

# However, provided Japanese tech tutorials blog is strongly advised for its rich content.

# script v1.0.4 - single-master, multi-node
# adding another master was not automized although tutorial was realized to full extend manually.

# Requires Centos7 google compute nodes, with an ssh key defined from GCP Metadata options.

# To be run by root WITHIN GCLOUD compute node(LINUX_USER must exist on all nodes, gmail username is sufficient)
MEMORY_CHECK="false"
LINUX_USER="gmailuser"
OPENSHIFT_ADMIN_USER="openshift_admin"
OPENSHIFT_ADMIN_PASSWD="strong_password"
###
# define local-network hostnames for master and compute nodes
MSTR=(angelos)
SLAV=(charon cronus)
GCLOUD_DOMAIN="."$(echo $(hostname -f) | cut -d'.' -f2-)
for host in ${MSTR[*]} ${SLAV[*]}; do
	$host+=$GCLOUD_DOMAIN
done


# copy gcloud ssh private key to location below and provide its name
# Alternatively one could scp the file into appropriate directory with permissions specified bellow
PRIV_KEY_NAME="gcloud.ssh"
PRIV_KEY="/home/"$LINUX_USER"/.ssh/"$PRIV_KEY_NAME
PRIV_KEY_TEXT="-----BEGIN OPENSSH PRIVATE KEY-----
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed
in ipsum sollicitudin, lacinia justo vel, varius ex. Cras nec
elementum ex, vitae dignissim dolor. Nunc ex lectus, egestas
et iaculis eu, consequat eu turpis. Praesent eu augue non velit
ornare porta. Phasellus nec eros condimentum, rutrum dui mollis,
mollis justo. Nulla facilisi. Nullam semper leo sed magna viverra,
in dapibus augue consectetur. Phasellus vel arcu a nisl dictum
egestas at a ligula. Interdum et malesuada fames ac ante ipsum
primis in faucibus. Sed egestas iaculis velit sit amet viverra.
Sed porttitor quis sapien sit amet rutrum. Class aptent taciti
sociosqu ad litora torquent per conubia nostra, per inceptos
himenaeos. Curabitur sit amet augue ut mi tempus ultrices.
Vestibulum ac magna ut lorem dapibus auctor.
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed
in ipsum sollicitudin, lacinia justo vel, varius ex. Cras nec
elementum ex, vitae dignissim dolor. Nunc ex lectus, egestas
et iaculis eu, consequat eu turpis. Praesent eu augue non velit
ornare porta. Phasellus nec eros condimentum, rutrum dui mollis,
mollis justo. Nulla facilisi. Nullam semper leo sed magna viverra,
in dapibus augue consectetur. Phasellus vel arcu a nisl dictum
egestas at a ligula. Interdum et malesuada fames ac ante ipsum
primis in faucibus. Sed egestas iaculis velit sit amet viverra.
Sed porttitor quis sapien sit amet rutrum. Class aptent taciti
sociosqu ad litora torquent per conubia nostra, per inceptos
himenaeos. Curabitur sit amet augue ut mi tempus ultrices.
Vestibulum ac magna ut lorem dapibus auctor.
-----END OPENSSH PRIVATE KEY-----"



### Below is not to be modified, normally


# create private key
echo "$PRIV_KEY_TEXT" > $PRIV_KEY
chown $LINUX_USER:$LINUX_USER $PRIV_KEY
chmod 400 $PRIV_KEY


###
# configure hosts under ~/.ssh/
yum -y install bind-utils

HOME_USER_SSH_CONFIG=""

for host in ${MSTR[*]} ${SLAV[*]}; do
HOME_USER_SSH_CONFIG+="
Host "$host"
    Hostname "$host"
    User "$LINUX_USER"
    Port 22
    IdentityFile $PRIV_KEY
"
done

echo -e "$HOME_USER_SSH_CONFIG" > /home/$LINUX_USER/.ssh/config
chown $LINUX_USER:$LINUX_USER /home/$LINUX_USER/.ssh/config
chmod 600 /home/$LINUX_USER/.ssh/config



###
#ssh into all hosts, accepts public keys as necessary
# Definitely NOT SECURE, yet piggy backing on GCP's security
for host in ${MSTR[*]} ${SLAV[*]}; do    
    runuser -l $LINUX_USER -c "ssh -oStrictHostKeyChecking=no $host sudo yum -y install python3"
done


###
echo -e 'Defaults:origin !requiretty\n'$LINUX_USER' ALL = (root) NOPASSWD:ALL' | tee /etc/sudoers.d/openshift
chmod 440 /etc/sudoers.d/openshift
firewall-cmd --add-service=ssh --permanent
firewall-cmd --reload
yum -y install centos-release-openshift-origin311 epel-release docker git pyOpenSSL
systemctl start docker
systemctl enable docker
yum -y install openshift-ansible
yum -y install ansible
yum -y install python-pip && pip install ansible=2.6.20

# ansible downgrade via yum does not work anymore, use pip
# after openshift-ansible install to do so.
yum -y downgrade ansible 2.6.20-1.e17.noarch


###
# ansible config file
ETC_ANSIBLE_HOSTS="# ANSIBLE-INSTALLER "$(date '+%Y-%m-%d %H:%M:%S')"
[OSEv3:children]
masters
nodes
etcd

[OSEv3:vars]
# admin user created in previous section
ansible_ssh_user="$LINUX_USER"
ansible_become=true
openshift_deployment_type=origin"

# default disable option:
# "openshift_disable_check=disk_availability,docker_storage,memory_availability"
if [ $MEMORY_CHECK == "false" ]
then
ETC_ANSIBLE_HOSTS+="
openshift_disable_check=disk_availability,docker_storage,memory_availability"
fi

ETC_ANSIBLE_HOSTS+="

# use HTPasswd for authentication
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider'}]
# allow unencrypted connection within cluster
openshift_docker_insecure_registries=172.30.0.0/16

[masters]
"${MSTR[0]}" openshift_schedulable=true containerized=false

[etcd]
"${MSTR[0]}"

[nodes]
# defined values for [openshift_node_group_name] in the file below
# [/usr/share/ansible/openshift-ansible/roles/openshift_facts/defaults/main.yml]
"${MSTR[0]}" openshift_node_group_name='node-config-master-infra'"

for host in ${SLAV[*]}; do
ETC_ANSIBLE_HOSTS+="
"$host" openshift_node_group_name='node-config-compute'"
done


cp /etc/ansible/hosts /etc/ansible/hosts.previous
echo -e "$ETC_ANSIBLE_HOSTS" > /etc/ansible/hosts
#do not edit chmod or chown, file already exists


###
# run ansible-playbook
runuser -l $LINUX_USER -c "ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml"
runuser -l $LINUX_USER -c "ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml"
runuser -l $LINUX_USER -c "oc get nodes"



###\
# add user for openshift console
htpasswd -c -b /etc/origin/master/htpasswd $OPENSHIFT_ADMIN_USER $OPENSHIFT_ADMIN_PASSWD

# unknown command from past
#runuser -l $LINUX_USER -c "ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/openshift-master/restart.yml"

oc login -u system:admin
oc adm policy add-cluster-role-to-user cluster-admin $OPENSHIFT_ADMIN_USER

