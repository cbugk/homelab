# Homelab
A repository to document my progress on homelab. Currently 3 laptops and [Proxmox](https://pve.proxmox.com) Its main purpose is to provide a foundation for my [Obsman](https://github.com/cbugra/obsman) project.

Mind that, this is an experimentation, not a production-ready virtualization cluster. In case of different homelab settings, branching will be put to use. (check [r/homelab](https://reddit.com/r/homelab) if you have not come accross the term)
### Structure
Currently, `doc` directory is where simple .txt files are used for quick records, `arc` is for archiving dead-ends, and `src` for any configuration (.cfg, .yml, etc) or script.

#### Current Goal:
- Deploy an RKE cluster on one vm per node

#### Achieved:
- Install Proxmox
- Set Ceph (RADOS and Cephfs)
- Prepare ssh-key for Ansible
- Ssh banner for vms

P.S. Documentation is provided on a per request basis, and might be lacking for subjectively trivial or hard to document processes.
