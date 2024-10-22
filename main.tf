# TODO: Remove provider and put in the docs so it is documented for calling
# this module
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
  name       = "SSH key for mail in a box at ${var.miab_primary_hostname}"
  public_key = file("${var.ssh_private_key}.pub")
}

# Bucket for MIAB/Nextcloud FUSE mount
resource "digitalocean_spaces_bucket" "miab" {
  name   = var.miab_primary_hostname
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

resource "random_integer" "ssh_port" {
  min = 1025
  max = 65535
}
resource "digitalocean_droplet" "miab" {
  backups    = true
  depends_on = [digitalocean_spaces_bucket.miab]
  image      = var.droplet_image
  ipv6       = false
  name       = var.miab_primary_hostname
  region     = var.do_region
  size       = var.droplet_size
  ssh_keys   = [digitalocean_ssh_key.miab.fingerprint]

  user_data = templatefile("${path.module}/miab-setup.tftpl", {
    miab_primary_hostname = var.miab_primary_hostname
    miab_public_ip        = digitalocean_floating_ip.miab.ip_address
    miab_storage_root     = var.miab_storage_root
    miab_storage_user     = var.miab_storage_user
    ssh_port              = random_integer.ssh_port.result
  })
}
