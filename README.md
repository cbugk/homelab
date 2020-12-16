# Homelab
Its purpose is to document my bare-metal/cloud experiments, lately.
Currently a workstation and a server (Haswell laptops both) with Centos 8.

#### Current Goal:
- Get familiarized to selinux (to eventually fully migrate onto Centos/Rocky Linux)
- Get sufficient on ansible roles
  - [Ansible Centos 8 Workstation](https://github.com/cbugra/ansible_workstation)
  - [TODO: Kickstart + Ansible oVirt setup] 

#### Done:
- Three-node proxmox cluster with Ceph (enough for homelabbing, except cloud-init)
- Try vanilla Ceph (seems to be least hassle)
- Kubespray GCP Free Tier deployment (deserves more investigation)
- Thought experiment on a bare-metal K8s (it hurted)
  - Linux Round-Robin bonding (mode-0) over gigabit switch (via VLANs)
  - Rook for Ceph on K8s
  - Multus to isolate Ceph within private linux bond network
  - Kubespray to deploy with ease (not OOB with Multus yet)
  - Wait until a real necessity arises (as [obsman](https://github.com/cbugra/obsman) is stalled)

P.S. Documentation is provided on a per request basis, and might be lacking for subjectively trivial or hard to document processes.
