# Preparation of Ubuntu cloud-init template on Proxmox

## Source(s)
- [brandStetter](https://norocketscience.at/deploy-proxmox-virtual-machines-using-cloud-init/)
- [oliveira](https://medium.com/swlh/provision-proxmox-vms-with-terraform-quick-and-easy-5ad1975df1de)

## Environment
    Workstation:
      Shell: bash
      User: cbugra@workstation
    Proxmox_Cluster:
      Nodes: [ apollo, hermes, triton ]
      Domain: pve.cbk.lab
      Storage: [ CephFS: cephfs, RBD: cephrbd ]

## End Result
Official cloud-init image for Ubuntu_20.04 is uploaded to CephRBD.

## Procedure
- Download official cloudimage from Canonical (Focal Fossa 20.04)
    ```console
    cbugra@workstation:/depot/boot_img/qcow2$
    wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
    ```
- Do NOT forget to rename extention from `.img` to `.qcow2` as also described in proxmox forum
    ```console
    cbugra@workstation:/depot/boot_img/qcow2$
    mv focal-server-cloudimg-amd64.img focal-server-cloudimg-amd64.qcow2
    ```
- Upload file to a cluster node
    ```console
    cbugra@workstation:/depot/boot_img/qcow2$
    scp ./focal-server-cloudimg-amd64.qcow2 root@hermes.pve.cbk.lab:/root/
    ```
- Enter into the node
    ```console
    cbugra@workstation:/depot/boot_img/qcow2$
    ssh root@hermes.pve.cbk.lab
    ```
    - Create vm scaffold
        ```console
        root@hermes:/root#
        qm create 9000 --name ubuntu-2004-cloudinit-template --memory 1024 --net0 virtio,bridge=vmbr0 --cores 1 --sockets 1 --cpu cputype=kvm64 -description “ubuntu-2004-cloudinit-template” --kvm 1 --numa 1
        ```
    - Import .qcow2 image as disk
        ```console
        root@hermes:/root#
        qm importdisk 9000 /root/focal-server-cloudimg-amd64.qcow2 cephrbd
        ```
    - Optionally, delete image (not recommended)
        ```console
        root@hermes:/root#
        rm /root/focal-server-cloudimg-amd64.qcow2
        ```
    - Set vm template to use disk
        ```console
        root@hermes:/root#
        qm set 9000 --scsihw virtio-scsi-pci --virtio0 cephrbd:vm-9000-disk-0
        ```
    - Set serial, told it is required for OpenStack cloudinit images
        ```console
        root@hermes:/root#
        qm set 9000 --serial0 socket
        ```
    - Set vga
        ```console
        root@hermes:/root#
        qm set 9000 --vga qxl
        ```
    - Cloudinit configuration is handed from CD-Rom
        ````console
        root@hermes:/root#
        qm set 9000 --ide2 cephrbd:cloudinit
        ```
    - Set boot order (boot disk only)
        ```console
        root@hermes:/root#
        qm set 9000 --boot c --bootdisk scsi0
        ```
    -  Acknowlegde image does not have qemu-agent support (aware of being a vm)
        ```console
        root@hermes:/root#
        qm set 9000 --agent 0
        ```
    - Turn into template at last
        ```console
        root@hermes:/root#
        qm template 9000
        ```
    - Exit from the node
        ```console
        root@hermes:/root#
        exit
        ```

