variable "proxmox_url" {
  type = string
}

variable "pm_api_username" {
  type = string
}

variable "pm_token" {
  type      = string
  sensitive = true
}

variable "pm_username" {
  type = string
}

variable "pm_password" {
  type      = string
  sensitive = true
}

variable "proxmox_node" {
  type = string
}

variable "ssh_username" {
  type = string
}

variable "ssh_password" {
  type = string
}

packer {
  required_plugins {
    proxmox = {
      version = ">= 1.0.1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "proxmox-ubuntu-22" {
  proxmox_url      = "${var.proxmox_url}/api2/json"
  vm_name          = "packer-ubuntu-22"
  iso_file         = "local:iso/ubuntu-22.04.4-live-server-amd64.iso"
  iso_storage_pool = "local"

  # iso_url          = "http://releases.ubuntu.com/22.04/ubuntu-22.04.4-live-server-amd64.iso"
  # iso_checksum     = "b8f31413336b9393ad5d8ef0282717b2ab19f007df2e9ed5196c13d8f9153c8b"

  username = "${var.pm_api_username}"
  token    = "${var.pm_token}"

  # username = "${var.pm_username}"
  # password = "${var.pm_password}"
  node = "${var.proxmox_node}"

  insecure_skip_tls_verify = true

  template_name        = "packer-ubuntu-20"
  template_description = "packer generated ubuntu-20.04-server-amd64"
  unmount_iso          = true

  # pool       = "packer"
  memory     = 2048
  cores      = 1
  sockets    = 1
  os         = "l26"
  qemu_agent = true

  scsi_controller = "virtio-scsi-pci"

  disks {
    type              = "scsi"
    disk_size         = "10G"
    storage_pool      = "local-lvm"
    storage_pool_type = "lvm"
    format            = "raw"
  }

  network_adapters {
    bridge   = "vmbr0"
    model    = "virtio"
    firewall = false
  }

  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"

  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    "<bs><bs><bs><bs><wait>",
    "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
    "<f10><wait>"
  ]
  boot      = "c"
  boot_wait = "5s"

  http_directory = "http"
  # Make sure this is your IP address (or the IP address of the machine running Packer)
  http_bind_address = "192.168.1.102"
  http_port_min     = 8250
  http_port_max     = 8250

  ssh_username = "${var.ssh_username} "
  # ssh_private_key_file = "~/.ssh/id_rsa"
  ssh_password = "${var.ssh_password}"

  ssh_timeout = "20m"
}

build {

  name    = "ubuntu-22"
  sources = ["proxmox-iso.proxmox-ubuntu-22"]

  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo apt -y autoremove --purge",
      "sudo apt -y clean",
      "sudo apt -y autoclean",
      "sudo cloud-init clean",
      "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      "sudo rm -f /etc/netplan/00-installer-config.yaml",
      "sudo sync"
    ]
  }

  provisioner "file" {
    source      = "files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }

  provisioner "shell" {
    inline = ["sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"]
  }

  # provisioner "shell" {
  #   inline = [
  #     "sudo apt-get update",

  #     # install docker
  #     "sudo apt-get install -y docker.io",
  #     "sudo systemctl enable docker",
  #     "sudo systemctl start docker",

  #     # install kubeadm, kubelet, kubectl
  #     "sudo apt-get update && sudo apt-get install -y apt-transport-https curl",
  #     "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
  #     "echo 'deb https://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee /etc/apt/sources.list.d/kubernetes.list",
  #     "sudo apt-get update",
  #     "sudo apt-get install -y kubelet kubeadm kubectl",
  #     "sudo apt-mark hold kubelet kubeadm kubectl",
  #   ]
  # }
}
