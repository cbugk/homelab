# Setting Proxmox 6.2 Cluster Up

## Source(s)

   [proxmox-buster](https://pve.proxmox.com/wiki/Install_Proxmox_VE_on_Debian_Buster)

   [hostname-resolv](https://forum.proxmox.com/threads/how-do-nodes-resolve-other-nodes-hostname.27847/)

## Environment
    workstation:
      model: "Samsung NC10"
      drive0: /dev/sda #SSD-250GB-Evo860
      system: Antix_x86
      user: cbugra@workstation
    proxmox-cluster:
      domain: pve.cbk.lab
      nodes:
      - apollo:
          model: "Acer Aspire v3-371"
          other_systems: []
          installer: proxmox6.2.iso
          uefi: true
          lvm: true
          drive0: /dev/sdb #Usb3-16gb-KingstonDT50
          drive1: /dev/sda #SSHD-500GB-Seagate
      - hermes:
          model: "HP Probook 450 G2"
          other_systems: [win10, xubuntu2004]
          installer: debian_buster_standard_nonfree.iso
          uefi: true
          lvm: false
          drive0: /dev/sda #HDD-320GB-WDBlack
          drive1: /dev/sdb #SSHD-1TB-Seagate
      - triton:
          model: "Toshiba Satellite L830-127"
          other_systems: []
          installer: proxmox6.2.iso
          uefi: false
          lvm: true
          drive0: /dev/sda #HDD-160GB-Samsung
          drive1: /dev/sdb #HDD-500GB-Toshiba 

## End Result
    Proxmox 6.2 Cluster
      Nodes: [ apollo, hermes, triton ]
      Domain: pve.cbk.lab
      Storage: [ CephFS: cephfs, RBD: cephrbd ]

## Prerequisites

### Download ISO images
[Debian Buster non-free standard live](http://cdimage.debian.org/cdimage/unofficial/non-free/cd-including-firmware/10.6.0-live+nonfree/amd64/iso-hybrid/debian-live-10.6.0-amd64-standard+nonfree.iso)

[Proxmox 6.2-1](https://www.proxmox.com/en/downloads/item/proxmox-ve-6-2-iso-installer)

### Write to disk
[Rufus](https://rufus.ie) was used.

For Proxmox, [dd](https://linux.die.net/man/1/dd) is enough (use dd method in rufus as well)

For Debian, see their [documentation](https://www.debian.org/releases/stable/installmanual) or StackOverflow for other than Rufus.

[balenaEtcher](https://www.balena.io/etcher/) can also be used (need to verify MBR vs GPT manually).

## Procedure
\# Password for linux users on Proxmox nodes: `cbkcloud`

\# Remember to use a secure (preferably random) password, and your [password manager](https://en.wikipedia.org/wiki/List_of_password_managers) of choice.


### Apollo
#### Installation:
- Select `Install Proxmox VE`
- Acceppt licence: `I agree`
- Options for `Target Harddisk: /dev/sdc`  (installer usb registers as /dev/sdb)
    - Filesystem: `ext4`
    - swapsize: `0`
    - maxroot:  ` `
    - minfree:  `0`
    - minvz:    `0`
    - `Ok`
- Set Locale
    - Country: `Turkey`
    - Timezone: `Istanbul`
    - Keyboard: `US-English`
    - `Next`
- Root User
    - Enter password (twice)
    - mail: `root@apollo.pve.cbk.lab`
    - `Next`
- Network `ethernet: enp1s0`
    - FQDN:    `apollo.pve.cbk.lab`
    - IP Addr: `192.168.1.251`
    - Netmask: `255.255.255.0`
    - Gateway: `192.168.1.1`
    - DNS:     `192.168.1.2`
    - `Next`
- `Install`
- `Reboot`.

\#Ready for WebUI

\#Ready for cluster

Disable logging in an effort to not shorten Usb drive's life

`systemctl stop rsyslog`

`systemctl disable rsyslog`

### Triton
####   Installation:
- Select `Install Proxmox VE`
- Acceppt licence: `I agree`
- Options for `Target Harddisk: /dev/sda`
    - Filesystem: `ext4`
    - swapsize: `8`
    - maxroot:  `32`
    - minfree:  `0`
    - minvz:    ` `
    - `Ok`
- Set Locale
    - Country: `Turkey`
    - Timezone: `Istanbul`
    - Keyboard: `US-English`
    - `Next`
- Root User
    - Enter password (twice)
    - mail: `root@triton.pve.cbk.lab`
    - `Next`
- Network `ethernet: enp9s0`
    - FQDN:    `triton.pve.cbk.lab`
    - IP Addr: `192.168.1.253`
    - Netmask: `255.255.255.0`
    - Gateway: `192.168.1.1`
    - DNS:     `192.168.1.2`
    - `Next`
- `Install`
- `Reboot`

\#Ready for WebUI

\#Ready for cluster

### Hermes

Defaults will be used, for the sake of not falling into localization pithole.

Customize at your own risk, keyboard layout is the only exception.

#### System Installation
- Select `Debian Installer`
- Set Locale
    - `English-English`
    - `United States`
    - `American English`
- Network `ethernet: enp8s0`
    - Hostname: `hermes`
    - Domain: `pve.cbk.lab` # it is observed to be still overwritten by DNS server
- Root User
    - Provide password (twice)
- Non-priviledged User
    - Full Name: `cbkadm`
    - Username: `cbkadm`
    - Provide password (twice)
- Time Zone: `Eastern`
- Partitioning: `manual`
    > \# Drive0 had free space at the end for root and swap, and ESP at /dev/sda1
      # Drive1 might be a previous ceph disk, clear using `Configure the Logical Volume Manager`
      # Encryption was not desired, nor previously setup

    - /dev/sda1: # automatically set, not edited
        - Name: `EFI system partition`
        - Use as: `EFI System Partition`
        - Bootable flag: `on`
    - /dev/sda6:
        - Name: `buster-root`
        - Size: `32.0GB` 
        - Use as: `ext4`
        - Format: `yes`
        -  mount-point: `/`
        - \# leave other options as default
    - /dev/sda7:
        - Name: `swappy`
        - Size: `4.0GB`
        - Use as: `swap area`
- Finish partitioning and write changes to disk

\# Hereafter is written from memory, will be edited when reinstalled 

- Network mirror: `Turkey`
    - Repository: `ftp.tr.debian.org`
- `Reboot`

#### Proxmox Installation: [proxmox-buster]
- Login as `root`
- Install OpenSSH Server, Editor, wget and curl (just in case)
    - `apt update && apt install -y openssh-server vim nano wget curl`
- Enable root login
    - `echo "PermitRootLogin yes" >> /etc/ssh/sshd_config`
- Edit host IP
    - `vim /etc/hosts` \# sample is bellow
        >127.0.0.1       localhost

        >192.168.1.252   hermes.pve.cbk.lab      hermes
    - `hostname --ip-address` # should return 192.168.1.252
- Add repo
    - `echo "deb http://download.proxmox.com/debian/pve buster pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list`
    - `wget http://download.proxmox.com/debian/proxmox-ve-release-6.x.gpg -O /etc/apt/trusted.gpg.d/proxmox-ve-release-6.x.gpg`
    - `apt update && apt -y full-upgrade` \# takes awhile
    - `apt install -y proxmox-ve postfix open-iscsi` \# takes awhile
\#Ready for WebUI
    - `apt remove os-prober`
- Set default `vmbr0` linux bridge, either from WebUI or below example (former is suggested)
    - `vim /etc/network/interfaces` \# sample is below
        >source /etc/network/interfaces.d/*
        >         
        >auto lo
        >iface lo inet loopback
        > 
        >iface enp8s0 inet manual #previously was dhcp 
        > 
        >auto vmbr0
        >iface vmbr0 inet static
        >        address 192.168.1.252/24
        >        gateway 192.168.1.1
        >        bridge-ports enp8s0
        >        bridge-stp off
        >        bridge-fd 0
- Set DNS server and domain, so that hostnames are resolvable  [hostname-resolv]
    - vim /etc/resolv.conf \# sample below
        >search pve.cbk.lab
        >nameserver 192.168.1.2
- Reboot
\# At this point, check your node is accessible (physically, via ping, via switch console, etc.)
- Remove old kernel
    - `apt remove -y linux-image-amd64 'linux-image-4.19*'`
    - `update-grub`
- Reboot
\# Ready for cluster

## Setup the Cluster
\# `Accept Risk and Continue` or `Continue Anyway` into self-signed management dashboards, when necessary.

### Create Cluster (apollo)
- Visit `https://apollo.pve.cbk.lab:8006`
- Login
    - User Name: `root`
    - Password: `cbkcloud`
    - Realm: `Linux PAM` 
- @LeftPane `Server View` -> `Folder View` from drop-down
- @LeftPane `Datacenter` -> @InnerLeftPane `Cluster` -> @MainView `Create Cluster`
- @MainView `Join Information` -> `Copy Information` -> CloseDialog

TODO add images

### Join to Cluster (hermes, triton)
- Visit `https://hermes.pve.cbk.lab:8006`
- Login
    - User Name: `root`
    - Password: `cbkcloud`
    - Realm: `Linux PAM`
- @LeftPane ClickOn `Server View` -> Select `Folder View` from drop-down
- @LeftPane ClickOn `Datacenter` -> @InnerLeftPane ClickOn `Cluster` -> `Join Cluster` ->  Paste (copy info from `apollo`) -> Provide root password of `apollo` -> `Join`

\# Web page will reissue its TLS certificate, reload should fix the freeze

\# Not to reload too early, check if node apollo is visible from `apollo`'s WebUI.

Repeat for `https://triton.pve.cbk.lab:8006`

## CephRBD and CephFS
\# For all nodes do
- @LeftPane `Datacenter`+`Nodes`+`<node>` -> @InnerLeftPane `Ceph` -> NotInstalledInfoBox -> InstallationDialog

\# For very first encounter, configuration must be set (defaults are good enough for single ethernet NIC laptops)


\# Note that, OSD are only visible when active manager node is selected from LeftPane.

\# Altough not convinient, is not a problem.

\#For all nodes do
- @LeftPane `Datacenter`+`Nodes`+`<node>` -> @InnerLeftPane `Ceph`+`Monitor` ->
    - `Create Manager` for `<node>`
    - `Create Monitor` for `<node>`
- @LeftPane `Datacenter`+`Nodes`+`<node>` -> @InnerLeftPane `Ceph`+`OSD` ->
    `Create OSD` (dialog pops) -> Disk: (auto-selected) -> `Create`

\# If disk not auto-selected, ssh into <node>, identify disk via `lsblk` (e.g. /dev/sdX)

\# then `ceph-volume lvm zap --destroy /dev/sdX`

### CepRBD
\# From any node do (once)
- @InnerLeftPane `Ceph`+`Pools` --> `Create` (dialog pops)
    - Name: `cephrbd`
    - Size: `3`
    - Minsize: `2`
    - Crush Rule: `replicated_rule`
    - pg_num: `64`
    - Add as Storage: `yes`

### CephFS
\# From any node do for all nodes
- @InnerLeftPane `Ceph`+`CephFS` -> `Metadata Servers` -> `Create` (dialog pops)

\# all should be `up:standby`
- @InnerLeftPane `Ceph`+`CephFS` -> `Create CephFS` (dialog pops) -> `Create` #with below config -> CloseDialog
    - Name: `cephfs`
    - Placement Groups: `64`
    - Add as Storage: `yes`

\# Should create pools `cephfs`(pg: 64) and `cephfs_metadata`(pg: 16)  

\# Check
- Ceph pools exist @InnerLeftPane `Ceph`+`Pools`
- Storages created  @LeftPane `Storage`
- Ceph status       @InnerLeftPane `Ceph`

    

  
  
