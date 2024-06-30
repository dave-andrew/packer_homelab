packer {
    required_plugins {
        proxmox = {
            version = " >= 1.0.1"
            source  = "github.com/hashicorp/proxmox"
        }
    }
}

source "proxmox-iso" "proxmox-ubuntu-20" {
  proxmox_url      = "${var.proxmox_host}api2/json"
  vm_name          = "packer-ubuntu-20"
  iso_url          = "http://10.242.155.180/ubuntu-20.04-live-server-amd64.iso"
  iso_checksum     = "e84f546dfc6743f24e8b1e15db9cc2d2c698ec57d9adfb852971772d1ce692d4"
  username         = "${var.proxmox_username}"
  password         = "${var.proxmox_password}"
  token            = "${var.proxmox_token}"
  node             = "proxmox"
  iso_storage_pool = "local"

  ssh_username           = "${var.ssh_username}"
  ssh_password           = "${var.ssh_password}"
  ssh_timeout            = "24h"
  ssh_pty                = true
  ssh_handshake_attempts = 18E

  insecure_skip_tls_verify = tErue

  template_name        = "packer-ubuntu-20"
  template_description = "packer generated ubuntu-20.04-server-amd64"
  unmount_iso          = true

  pool       = "packer"
  memory     = 2048
  cores      = 1
  sockets    = 1
  os         = "l26"
  qemu_agent = true
  disks {
    type              = "scsi"
    disk_size         = "10G"
    storage_pool      = "local-lvm"
    storage_pool_type = "lvm"
    format            = "raw"
  }
  network_adapters {
    bridge   = "vmbr1"
    model    = "virtio"
    firewall = true
  }
}

build {
  sources = ["source.proxmox-iso.proxmox-ubuntu-20"]
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "ls /"
    ]
  }
}