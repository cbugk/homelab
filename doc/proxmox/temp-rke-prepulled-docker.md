# Preparing a Template with Required RKE Docker Images
This template is not strictly required, yet is highly recommended. [temp-rke-prepared-os](./temp-rke-prepared-os.md) can be used within terraform deployments, however, each node would then need to pull images around 2GB in size. Which could probably increase deployment time drastically, and cut bandwidth/quota down.

## Prerequisite(s)
- [temp-rke-prepared-os](./temp-rke-prepared-os.md)

## Source(s)
- [rke-install](https://rancher.com/docs/rke/latest/en/installation/)

## Environment
    Workstation:
      Shell: bash
      User: cbugra@workstation
    Proxmox_Cluster:
      Nodes: [ apollo, hermes, triton ]
      Domain: pve.cbk.lab
      Storage: [ CephFS: cephfs, RBD: cephrbd]
      VMs:
      - 9000:
        template: true
        name: temp-ubuntu-2004-cloudinit
      - 9001:
        template: true
        name: temp-rke-prepared-os

## End Result
RKE vm template (id: 9002), with required docker images pulled via a `rke up` and `rke remove` sequence.

## Procedure

- Create vm via terraform (currently only working method)
    \# TODO: perform equivelant manually on a Proxmox node.

    > Current workspace: `default`
    - Enter into directory
        ```console
        cbugra@workstation:/homelab/src/terraform$
        cd ./templates
        ```

        - Create a dedicated workspace
            ```console
            cbugra@workstation:/homelab/src/terraform/templates$
            terraform workspace new temp-rke-prepulled-docker
            ```
        - Switch to workspace
            ```console
            cbugra@workstation:/homelab/src/terraform/templates$
            terraform workspace select temp-rke-prepulled-docker
            ```

        - Apply `.tf` file
            ```console
            cbugra@workstation:/homelab/src/terraform/templates$
            terraform init && terraform validate && terraform plan --out ./plan.tmp && terraform apply ./plan.tmp
            ```
        > Note that current cluster setup (gigabit switch, 1 OSD/host) throws a timeout for more than a single clone.

        > [temp-rke-prepulled-docker.tf](/src/terraform/templates/temp-rke-prepulled-docker.tf) should be the only `.tf` file, so no workaround needed yet.

        - Exit from directory, get out of workspace
            ```console
            cbugra@workstation:/homelab/src/terraform/templates$
            terraform workspace select default && cd ..
            ```
- Get vm running

    > WebUI should enable you to both start and find out vm's IP address. Alternatively, you can ssh into embodying node

    - Enter into node
        ```console
        cbugra@workstation:/homelab/src/terraform$
        ssh root@apollo.pve.cbk.lab
        ```
        - Start vm
            ```console
            root@apollo:/root#
            qm list
            ```
            > Find out `<vmid>`

            ```console
            root@apollo:/root#
            qm start <vmid>
            ```
        - Learn IP Address
             ```console
            root@apollo:/root#
            qm guest cmd <vmid> network-get-interfaces | grep ip-address
            ```
            > A more general, yet harder to parse alternative

            ```console
            root@apollo:/root#
            qm guest exec <vmid> ip address
            ```
        - Exit from node
            ```console
            root@apollo:/root#
            exit
            ```
- Pull images

    - Copy private key onto vm (temporarily)
        ```console
        cbugra@workstation:/homelab/src/terraform$
        ssh -i /depot/ssh_keys/rke_vm.ssh ubuntu@<ipv4> mkdir -p /home/ubuntu/.ssh/
        ```
        ```console
        cbugra@workstation:/homelab/src/terraform$
        scp -i /depot/ssh_keys/rke_vm.ssh /depot/ssh_keys/rke_vm.ssh ubuntu@<ipv4>:/home/ubuntu/.ssh/
        ```
    - Enter into vm (with private key)
        ```console
        cbugra@workstation:/homelab/src/terraform$
        ssh -i /depot/ssh_keys/rke_vm.ssh ubuntu@<ipv4>
        ```
        - Prepare permissions for private key
            ```console
            chmod 400 ~/.ssh/rke_vm.ssh
            ```
        - Create temporary directory
            ```console
            ubuntu@temp-rke-prepulled-docker:/home/ubuntu$
            mkdir ~/rke-conf && cd ~/rke-conf
            ```
        - Download docker images (indirectly)
            > Accept defaults except for those specified.
            ```console
            ubuntu@temp-rke-prepulled-docker:/home/ubuntu/rke-conf$
            rke config --name cluster.yml # sample is below
            ```
            - [+] Cluster Level SSH Private Key Path [~/.ssh/id_rsa]: `~/.ssh/rke_vm.ssh`
            - [+] SSH Address of host [none]: `localhost`
            - [+] Is host a Control Plane host (y/n)? `y`
            - [+] Is host a Worker host (y/n)? `y`
            - [+] Is host an etcd host (y/n)? `y`
             
            > `rke up` might throw errors or warnings, a succesful cluster setup takes three consequtive `rke up` currently.
            ```console
            ubuntu@temp-rke-prepulled-docker:/home/ubuntu/rke-conf$
            rke up
            ```
            > Tear it down after succesful install, when prompted answer `y`.
            ```console
            ubuntu@temp-rke-prepulled-docker:/home/ubuntu/rke-conf$
            rke remove
            ```
        - Delete remnants
            ```console
            ubuntu@temp-rke-prepulled-docker:/home/ubuntu/rke-conf$
            cd && rm -rf ~/.ssh/rke_vm.ssh ~/rke-config ~/.ssh/known_hosts # just incase
            ```
            > Harmless here, yet do not get accostumed to the command below

            ```console
            ubuntu@temp-rke-prepulled-docker:/home/ubuntu$
            docker stop $(docker ps -aq) && docker rm $(docker ps -aq)
            ```
        - Exit from vm, deleting history for `ubuntu`
            ```console
            ubuntu@temp-rke-prepulled-docker:/home/ubuntu$
            cat /dev/null > ~/.bash_history && history -c && exit 
            ```






