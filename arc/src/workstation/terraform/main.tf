resource "proxmox_vm_qemu" "rke_master_1" {
  name              = "rke-m1"
  target_node       = "triton"

  clone             = "rke-base-template"

  agent             = 1

  os_type           = "cloud-init"
  cores             = "2"
  sockets           = "1"
  cpu               = "kvm64"
  memory            = "4096"
  scsihw            = "virtio-scsi-pci"
  bootdisk          = "scsi0"

  disk {
    id              = 0
    size            = 10
    type            = "scsi"
    storage         = "cephrds"
    storage_type    = "rbd"
    iothread        = true
  }

  network {
    id              = 0
    model           = "virtio"
    bridge          = "vmbr0"
  }

  lifecycle {
    ignore_changes  = [
      network,
    ]
  }

  # Cloud Init Settings
  ipconfig0         = "ip=192.168.1.41/24,gw=192.168.1.1"

  sshkeys = <<EOF
  ${var.ssh_pub}
  EOF
}

resource "proxmox_vm_qemu" "rke_worker_1" {
  name              = "rke-w1"
  target_node       = "apollo"

  clone             = "rke-base-template"

  agent             = 1

  os_type           = "cloud-init"
  cores             = 2
  sockets           = 1
  cpu               = "kvm64"
  memory            = 4096
  scsihw            = "virtio-scsi-pci"
  bootdisk          = "scsi0"

  disk {
    id              = 0
    size            = 10
    type            = "scsi"
    storage         = "cephrds"
    storage_type    = "rbd"
    iothread        = true
  }

  network {
    id              = 0
    model           = "virtio"
    bridge          = "vmbr0"
  }

  lifecycle {
    ignore_changes  = [
      network,
    ]
  }

  # Cloud Init Settings
  ipconfig0         = "ip=192.168.1.42/24,gw=192.168.1.1"

  sshkeys = <<EOF
  ${var.ssh_pub}
  EOF
}

resource "proxmox_vm_qemu" "rke_worker_2" {
  name              = "rke-w2"
  target_node       = "hermes"

  clone             = "rke-base-template"

  agent             = 1

  os_type           = "cloud-init"
  cores             = 2
  sockets           = 1
  cpu               = "kvm64"
  memory            = 4096
  scsihw            = "virtio-scsi-pci"
  bootdisk          = "scsi0"

  disk {
    id              = 0
    size            = 10
    type            = "scsi"
    storage         = "cephrds"
    storage_type    = "rbd"
    iothread        = true
  }

  network {
    id              = 0
    model           = "virtio"
    bridge          = "vmbr0"
  }

  lifecycle {
    ignore_changes  = [
      network,
    ]
  }

  # Cloud Init Settings
  ipconfig0         = "ip=192.168.1.43/24,gw=192.168.1.1"

  sshkeys = <<EOF
  ${var.ssh_pub}
  EOF
}
