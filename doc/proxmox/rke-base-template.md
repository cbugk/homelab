# Creating a Template for RKE VMs

## Prerequisite(s)
[ubuntu-2004-cloudinit-template](./ubuntu-2004-cloudinit-template.md)

## Source(s)
- [brandStetter](https://norocketscience.at/deploy-proxmox-virtual-machines-using-cloud-init/)
- [oliveira](https://medium.com/swlh/provision-proxmox-vms-with-terraform-quick-and-easy-5ad1975df1de)
- [dockerce](https://docs.docker.com/engine/install/ubuntu/)
- [rke-install](https://rancher.com/docs/rke/latest/en/installation/)
- [rke-prep-os](https://rancher.com/docs/rke/latest/en/os/)
- [kubevirt-crio](https://kubevirt.io/2019/KubeVirt_k8s_crio_from_scratch.html)

## Environment
    Workstation:
      Shell: bash
      User: cbugra@workstation
    Proxmox_Cluster:
      Nodes: [ apollo, hermes, triton ]
      Domain: pve.cbk.lab
      Storage: [ CephFS: cephfs, RADOS: cephrds ]
      VMs:
      - 9000:
        template: true
        name: ubuntu-2004-cloudinit-template

## End Result
RKE node (id: 9001), with required packages/binaries/images installed and virtual hardware specified.

## Procedure

- Create cluster-wide public key directory
    ```console
    cbugra@workstation:/depot/ssh_keys/rke_vm$
    ssh root@hermes.pve.cbk.lab mkdir -p /etc/pve/pub_keys
    ```
- Upload ssh public key onto cluster-wide directory
    ```console
    cbugra@workstation:/depot/ssh_keys/rke_vm$
    scp ./rke_vm.pub root@hermes.pve.cbk.lab:/etc/pve/pub_keys/
    ```

- Enter into the node
    ```console
    cbugra@workstation:/depot/ssh_keys/rke_vm$
    ssh root@hermes.pve.cbk.lab
    ```
    - Clone template to further configure (full clone)
        ```console
        root@hermes:/root#
        qm clone 9000 9001 --name rke-base-template --full 1
        ```
    - Set ssh authentication from uploaded public key
        ```console
        root@hermes:/root#
        qm set 9001 --sshkey /etc/pve/pub_keys/rke_vm.pub
        ```
    - Change Hardware as required/desired
        ```console
        root@hermes:/root#
        qm set 9001 --cores 2 --memory 4096
        ```
    - Enable dhcp (supported) or optionally set static-ip (if you know what you are doing)
        ```console
        root@hermes:/root#
        qm set 9001 --ipconfig0 ip=dhcp
        # qm set 9001 --ipconfig0 ip=192.168.1.91/24,gw=192.168.1.1
        ```
    \# Note that, setting default user requires snippet support on a volume

    \# User is not configured as of now, default user is `ubuntu`.

    - Start VM (not a template yet)
        \# You are advised to check options on GUI beforehand, update as you wish via GUI/CLI
        ```console
        root@hermes:/root#
        qm start 9001
        ```
    - Exit from the node
        ```console
        root@hermes:/root#
        exit
        ```
- Enter into vm
    ```cbugra@workstation:/depot/ssh_keys/rke_vm$
    ssh -i ./rke_vm.ssh ubuntu@192.168.1.91
    ```
    - Obligatory apt update/upgrade
        ```console
        ubuntu@rke-base-template:/home/ubuntu$
        sudo apt update && sudo apt upgrade
        ```
    - Install Qemu Agent
        ```console
        ubuntu@rke-base-template:/home/ubuntu$
        sudo apt install qemu-guest-agent
        ```
    - Install DockerCE [dockerce]
        - Setup repository
            ```console
            ubuntu@rke-base-template:/home/ubuntu$
            sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
            ```
            ```console
            ubuntu@rke-base-template:/home/ubuntu$
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
            ```
            ```console
            ubuntu@rke-base-template:/home/ubuntu$
            sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
            ```
        - Install packages (might need to install a specific version)
            ```console
            ubuntu@rke-base-template:/home/ubuntu$
            sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io
            ```
    - Prepare RKE to installation [source:rke-prep-os,kubevirt-crio]
        ```console
        ubuntu@rke-base-template:/home/ubuntu$
        sudo usermod -aG docker $USER
        ```
    - Activate and enable modules on kernel
        \# following modules could not be found, thus removed

        \# (nt_conntrack_ipv4, nf_nat_ipv4), nf_nat_masquerade_ipv4)
        ```console
        ubuntu@rke-base-template:/home/ubuntu$
        sudo su
        ```
        ```console
        root@rke-base-template:/home/ubuntu#
        for module in br_netfilter ip6_udp_tunnel ip_set ip_set_hash_ip ip_set_hash_net iptable_filter iptable_nat iptable_mangle iptable_raw nf_conntrack_netlink nf_conntrack nf_defrag_ipv4 nf_nat nfnetlink udp_tunnel veth vxlan x_tables xt_addrtype xt_conntrack xt_comment xt_mark xt_multiport xt_nat xt_recent xt_set  xt_statistic xt_tcpudp; do
            if ! lsmod | grep -q $module; then
                modprobe $module && echo $module > /etc/modules-load.d/$module.conf;
            fi;
        done
        ```
        ```console
        root@rke-base-template:/home/ubuntu#
        cat > /etc/sysctl.d/99-rke.conf << EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
        ```
        ```console
        root@rke-base-template:/home/ubuntu#
        echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config
        ```
    - Erase history for `root`
        ```console
        root@rke-base-template:/home/ubuntu#
        cat /dev/null > ~/.bash_history && history -c && exit
        ```

    - Download RKE binary
    \# Check version from [ https://github.com/rancher/rke/releases ]
        ```console
        ubuntu@rke-base-template:/home/ubuntu$
        wget https://github.com/rancher/rke/releases/download/v1.2.0/rke_linux-amd64
        ```
        - Rename, make executable, and move into Path
        ```console
        ubuntu@rke-base-template:/home/ubuntu$
        mv ./rke_linux-amd64 ./rke && chmod +x ./rke && sudo mv ./rke /usr/local/bin/
        ```
    - Download Kubectl (version 1.19)
    \# You should not need to download onto base image, but onto workstation. This is chosen instead of installing on a x86 workstation, for convenience only.
        ```console
        ubuntu@rke-base-template:/home/ubuntu$
        curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.19.0/bin/linux/amd64/kubectl
        ```
        ```console
        ubuntu@rke-base-template:/home/ubuntu$
        chmod +x ./kubectl && sudo mv ./kubectl /usr/local/bin/kubectl
        ```
    - Exit from vm and Erase history for `ubuntu`
        ```console
        ubuntu@rke-base-template:/home/ubuntu$
        cat /dev/null > ~/.bash_history && history -c && exit
        ```

- Enter into node
    ```console
    cbugra@workstation:/depot/ssh_keys/rke_vm$
    ssh root@hermes.pve.cbk.lab
    ```
    - Enable qemu agent (installed earlier)
        ```console
        root@hermes:/root#
        qm set 9001 --agent 1
        ```
    - Shutdown vm before templating
        ```console
        root@hermes:/root#
        qm shutdown 9001
        ```
    - Convert into template
        ```console
        root@hermes:/root#
        qm template 9001
        ```
    - Exit from node
        ```console
        root@hermes:/root#
        exit
        ```

