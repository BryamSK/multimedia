module "debian-base" {
  source = "./../modules/debian-base"

    proxmox_api_url         = var.proxmox_api_url
    proxmox_username        = var.proxmox_username
    proxmox_token_id        = var.proxmox_token_id
    proxmox_token           = var.proxmox_token
    proxmox_password        = var.proxmox_password

    storage_pool            = var.storage_pool
    vmid                    = var.vmid
    password                = var.password
    user                    = var.user
    node                    = var.node
    template_name           = var.template_name
    template_path           = var.template_path
    public_key_path         = var.public_key_path
    private_key_path        = var.private_key_path
    memory                  = var.memory
    disk_size               = var.disk_size
    arch                    = var.arch
    cores                   = var.cores
    cpulimit                = var.cpulimit
    swap                    = var.swap
    onboot                  = var.onboot
    start                   = var.start
    ip                      = var.ip
    gw                      = var.gw
    tags                    = var.tags
    host                    = var.ip
    name                    = var.name
    description             = var.description
    unprivileged            = var.unprivileged
}

resource "null_resource" "configure_bind_mount" {
  depends_on = [module.debian-base]

  provisioner "local-exec" {
    command = <<-EOT
      ssh root@${var.node_ip} "pct set ${var.vmid} -mp0 /mnt/nfs-media,mp=/mnt/docker && pct set ${var.vmid} -features nesting=1 && pct reboot ${var.vmid}"
      sleep 30
    EOT
  }
}

module "install_docker" {
  source = "./../modules/install-docker"
    user                  = var.user
    private_key_path      = var.private_key_path
    host                  = var.ip
    depends_on = [module.debian-base]
}

resource "null_resource" "debian" {
  depends_on = [module.debian-base]

  provisioner "file" {
    source      = "./deploy/docker-compose.yml"
    destination = "/tmp/docker-compose.yml"
    connection {
      type        = "ssh"
      host        = var.ip
      user        = var.user
      private_key = file(var.private_key_path)
    }
  }

  provisioner "remote-exec" {
    inline = [
      "mv /tmp/docker-compose.yml .",
      "chmod +x docker-compose.yml",
      "docker compose up -d"
    ]
    connection {
      type        = "ssh"
      host        = var.ip
      user        = var.user
      private_key = file(var.private_key_path)
    }
  }
}