resource "proxmox_vm_qemu" "temp-rke-base" {
  name              = "temp-rke-base"
  target_node       = "hermes"

  clone             = "temp-ubuntu-2004-cloudinit"

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
    size            = 8
    type            = "scsi"
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
  ipconfig0         = "ip=192.168.1.40/24,gw=192.168.1.1"

  sshkeys = <<EOF
  ${var.ssh_pub}
  EOF
}

