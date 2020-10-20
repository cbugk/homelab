resource "proxmox_vm_qemu" "node00" {
  name              = "node00"
  vmid              = 941
  target_node       = "apollo"

  clone             = "temp-ubuntu-2004-cloudinit"

  agent             = 1

  os_type           = "cloud-init"
  cores             = 2
  sockets           = 1
  cpu               = "kvm64"
  memory            = 8192
  scsihw            = "virtio-scsi-pci"
  bootdisk          = "scsi0"

  disk {
    id              = 1
    size            = 16
    type            = "virtio"
    storage         = "cephrbd"
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

