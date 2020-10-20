# Creating a Template for RKE VMs
This is the initial enchanced cloudinit image for RKE, in which necessary OS tweaks are performed, binaries installed, and docker images prepulled.

## Prerequisite(s)
- [temp-ubuntu-2004-cloudinit](./temp-ubuntu-2004-cloudinit.md)

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
      Storage: [ CephFS: cephfs, RBD: cephrds ]
      VMs:
      - 9000:
        template: true
        name: temp-ubuntu-2004-cloudinit

## End Result
RKE vm template (id: 100), with required packages/binaries installed and virtual hardware specified.

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
- Create vm via terraform (currently only working method)
    > TODO: perform equivelant manually on a Proxmox node.

    > Current workspace: `default`
    - Enter into directory
        ```console
        cbugra@workstation:/homelab/src/terraform$
        cd ./temp-rke-base
        ```

        - Create a dedicated workspace
            ```console
            cbugra@workstation:/homelab/src/terraform/temp-rke-base$
            terraform workspace new temp-rke-base
            ```
        - Switch to workspace (if already exists)
            ```console
            cbugra@workstation:/homelab/src/terraform/temp-rke-base$
            terraform workspace select temp-rke-base
            ```
        > After `terraform apply` created vm will have first available vmid, assumed to be `100` in this tutorial.
        - Apply `.tf` file
            ```console
            cbugra@workstation:/homelab/src/terraform/temp-rke-base$
            terraform init && terraform validate && terraform plan --out ./plan.tmp && terraform apply ./plan.tmp
            ```
        > If you have previously deployed then destroyed. Current workaround is deleting previous context and deploying afterwards.
        - Workaround for manually removed vm
            ```console 
            cbugra@workstation:/homelab/src/terraform/temp-rke-base$
            rm -r .terraform/ terraform.tfstate.d/ plan.tmp
            ```
        > Note that current cluster setup (gigabit switch, 1 OSD/host) throws a timeout for more than a single clone.

        > [temp-rke-base.tf](/src/terraform/temp-rke-base/temp-rke-base.tf) should be the only `.tf` file, so no workaround needed yet.

        - Exit from directory, get out of workspace
            ```console
            cbugra@workstation:/homelab/src/terraform/temp-rke-base$
            terraform workspace select default && cd ..
            ```
- Copy private key onto vm (temporarily)
    ```console
    cbugra@workstation:/homelab/src/terraform$
    ssh -i /depot/ssh_keys/rke_vm.ssh ubuntu@192.168.1.40 mkdir -p /home/ubuntu/.ssh/
    ```
    ```console
    cbugra@workstation:/homelab/src/terraform$
    scp -i /depot/ssh_keys/rke_vm.ssh /depot/ssh_keys/rke_vm.ssh ubuntu@192.168.1.40:/home/ubuntu/.ssh/
    ```

- Enter into vm
    ```console
    cbugra@workstation:/depot/ssh_keys/rke_vm$
    ssh -i ./rke_vm.ssh ubuntu@192.168.1.40
    ```
    - Obligatory apt update/upgrade
        ```console
        ubuntu@temp-rke-base:/home/ubuntu$
        sudo apt update && sudo apt upgrade -y
        ```
    - Install Qemu Agent
        ```console
        ubuntu@temp-rke-base:/home/ubuntu$
        sudo apt install -y qemu-guest-agent
        ```
    - Install DockerCE [dockerce]
        - Setup repository
            ```console
            ubuntu@temp-rke-base:/home/ubuntu$
            sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
            ```
            ```console
            ubuntu@temp-rke-base:/home/ubuntu$
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
            ```
            ```console
            ubuntu@temp-rke-base:/home/ubuntu$
            sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
            ```
        - Install packages (might prefer to install a specific version)
            ```console
            ubuntu@temp-rke-base:/home/ubuntu$
            sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io
            ```
    - Prepare RKE to installation [rke-prep-os,kubevirt-crio]
        ```console
        ubuntu@temp-rke-base:/home/ubuntu$
        sudo usermod -aG docker $USER
        ```
    - Exit from vm, to apply group change
        ```console
        ubuntu@temp-rke-base:/home/ubuntu$
        exit
        ```
 - Re-enter into vm
    ```console
    cbugra@workstation:/depot/ssh_keys/rke_vm$
    ssh -i ./rke_vm.ssh ubuntu@192.168.1.40
    ```
    - Activate and enable modules on kernel
        > Following modules could not be found, thus removed: (nt_conntrack_ipv4, nf_nat_ipv4), nf_nat_masquerade_ipv4)
        ```console
        ubuntu@temp-rke-base:/home/ubuntu$
        sudo su
        ```
        ```console
        root@temp-rke-base:/home/ubuntu#
        for module in br_netfilter ip6_udp_tunnel ip_set ip_set_hash_ip ip_set_hash_net iptable_filter iptable_nat iptable_mangle iptable_raw nf_conntrack_netlink nf_conntrack nf_defrag_ipv4 nf_nat nfnetlink udp_tunnel veth vxlan x_tables xt_addrtype xt_conntrack xt_comment xt_mark xt_multiport xt_nat xt_recent xt_set  xt_statistic xt_tcpudp; do
            if ! lsmod | grep -q $module; then
                modprobe $module && echo $module > /etc/modules-load.d/$module.conf;
            fi;
        done
        ```
        ```console
        root@temp-rke-base:/home/ubuntu#
        cat > /etc/sysctl.d/99-rke.conf << EOF
        net.bridge.bridge-nf-call-iptables  = 1
        net.ipv4.ip_forward                 = 1
        net.bridge.bridge-nf-call-ip6tables = 1
        EOF
        ```
    - TCP Forwarding
        ```console
        root@temp-rke-base:/home/ubuntu#
        echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config
        ```
    - Erase history for `root`
        ```console
        root@temp-rke-base:/home/ubuntu#
        cat /dev/null > ~/.bash_history && history -c && exit
        ```
    - Install RKE binary
        > Check version from [github.com/rancher/rke/releases](https://github.com/rancher/rke/releases)

        ```console
        ubuntu@temp-rke-base:/home/ubuntu$
        wget https://github.com/rancher/rke/releases/download/v1.2.0/rke_linux-amd64
        ```
        > Rename, make executable, and move into path
        ```console
        ubuntu@temp-rke-base:/home/ubuntu$
        mv ./rke_linux-amd64 ./rke && chmod +x ./rke && sudo mv ./rke /usr/local/bin/
        ```
    - Prepare permissions for private key
        ```console
        chmod 400 ~/.ssh/rke_vm.ssh
        ```
    - Create temporary directory
        ```console
        ubuntu@temp-rke-base:/home/ubuntu$
        mkdir ~/rke-conf && cd ~/rke-conf
        ```
    - Download docker images (indirectly)
        > Accept defaults except for those specified.
        ```console
        ubuntu@temp-rke-base:/home/ubuntu/rke-conf$
        rke config --name cluster.yml # sample is below
        ```
        - [+] Cluster Level SSH Private Key Path [~/.ssh/id_rsa]: `~/.ssh/rke_vm.ssh`
        - [+] SSH Address of host [none]: `localhost`
        - [+] Is host a Control Plane host (y/n)? `y`
        - [+] Is host a Worker host (y/n)? `y`
        - [+] Is host an etcd host (y/n)? `y`
        > `rke up` might throw errors or warnings, a succesful cluster setup takes three consequtive `rke up` currently.
        ```console
        ubuntu@temp-rke-base:/home/ubuntu/rke-conf$
        rke up
        ```
        > Tear it down; answer `y` when prompted.
        ```console
        ubuntu@temp-rke-base:/home/ubuntu/rke-conf$
        rke remove
        ```
    - Delete remnants
        ```console
        ubuntu@temp-rke-base:/home/ubuntu/rke-conf$
        cd && rm -rf ~/.ssh/rke_vm.ssh ~/rke-config ~/.ssh/known_hosts # just incase
        ```
        > Harmless here, yet use below command with care in general.
        ```console
        ubuntu@temp-rke-base:/home/ubuntu$
        docker stop $(docker ps -aq) && docker rm $(docker ps -aq)
        ```
    - Exit from vm, deleting history for `ubuntu`
        ```console
        ubuntu@temp-rke-base:/home/ubuntu$
        cat /dev/null > ~/.bash_history && history -c && exit 
        ```
- Enter into node
    ```console
    cbugra@workstation:/depot/ssh_keys/rke_vm$
    ssh root@hermes.pve.cbk.lab
    ```
    - Reset to activate guest agent
        > Necessary as `agent: 1` option was provided in terraform file.
        ```console
        root@hermes:/root#
        qm reset 100
        ```
    - Shutdown vm
        ```console
        root@hermes:/root#
        qm shutdown 100
        ```
    - Enable DHCP
        ```console 
        root@hermes:/root#
        qm set 100 --ipconfig0 ip=dhcp
        ```
    - Convert into template
        > Until terraform can clone the template, this is not recommended. Note that, bug currently does not let `qm clone <vmid> <clone-vmid> --full 1` command neither.
        ```console
        root@hermes:/root#
        # qm template 100
        ```
    - Exit from node
        ```console
        root@hermes:/root#
        exit
        ```

