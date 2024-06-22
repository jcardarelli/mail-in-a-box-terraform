provider "digitalocean" {
  token             = var.do_token
  spaces_access_id  = var.spaces_access_id
  spaces_secret_key = var.spaces_secret_key
}

resource "digitalocean_floating_ip" "miab" {
  region = var.do_region
}

resource "digitalocean_floating_ip_assignment" "miab" {
  ip_address = digitalocean_floating_ip.miab.ip_address
  droplet_id = digitalocean_droplet.miab.id
}

resource "digitalocean_ssh_key" "miab" {
  name       = "SSH key for mail in a box at ${var.fqdn}"
  public_key = file("${var.ssh_private_key}.pub")
}

# Bucket for MIAB/Nextcloud FUSE mount
resource "digitalocean_spaces_bucket" "miab" {
  name   = var.fqdn
  region = var.do_region
  count  = var.spaces_backup_enabled == "" ? 1 : 0

  # TODO: Troubleshoot provisioning with this block uncommented
  # $ ~/github/mail-in-a-box-tf$ terraform -version
  # Terraform v0.12.18
  # + provider.digitalocean v1.12.0
  #
  # cors_rule {
  #   allowed_headers = ["*"]
  #   allowed_methods = ["*"]
  #   allowed_origins = [digitalocean_droplet.miab.ipv4_address_private]
  #   max_age_seconds = 3000
  # }
}

resource "digitalocean_droplet" "miab" {
  image    = var.droplet_image
  name     = var.fqdn
  ipv6     = true
  region   = var.do_region
  size     = var.droplet_size
  ssh_keys = [digitalocean_ssh_key.miab.fingerprint]
  backups  = true

  depends_on = [digitalocean_spaces_bucket.miab]

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "root"
      host        = digitalocean_droplet.miab.ipv4_address
      private_key = file(var.ssh_private_key)
      agent       = false
    }
    source      = "miab_setup.sh"
    destination = "/tmp/miab_setup.sh"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "root"
      host        = digitalocean_droplet.miab.ipv4_address
      private_key = file(var.ssh_private_key)
      agent       = false
    }
    inline = [
      "chmod +x /tmp/miab_setup.sh",
      "/tmp/miab_setup.sh ${var.fqdn} ${digitalocean_floating_ip.miab.ip_address} ${var.miab_STORAGE_ROOT} ${var.do_region}"
    ]
  }
}

output "floating_ip_address" {
  value     = digitalocean_floating_ip.miab.ip_address
  sensitive = true
}
