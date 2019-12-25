provider "digitalocean" {
  token = var.do_token
  spaces_access_id = var.spaces_access_id
  spaces_secret_key = var.spaces_secret_key
}

resource "digitalocean_domain" "miab" {
  name = var.fqdn
}

resource "digitalocean_record" "ssh" {
  domain = digitalocean_domain.miab.name
  type   = "A"
  name   = var.droplet_name
  value  = digitalocean_droplet.miab.ipv4_address
}

resource "digitalocean_record" "box" {
  domain = digitalocean_domain.miab.name
  type   = "A"
  name   = "box"
  value  = digitalocean_floating_ip.miab.ip_address
}

resource "digitalocean_floating_ip" "miab" {
  droplet_id = digitalocean_droplet.miab.id
  region     = digitalocean_droplet.miab.region
}

resource "digitalocean_ssh_key" "miab" {
  name       = "Mail in a box"
  public_key = file("${var.ssh_private_key}.pub")
}

# Bucket for MIAB/Nextcloud FUSE mount
resource "digitalocean_spaces_bucket" "miab" {
  name          = var.droplet_name
  region        = var.droplet_region

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
  image               = var.droplet_image
  name                = var.droplet_name
  private_networking  = var.droplet_private_networking
  region              = var.droplet_region
  size                = var.droplet_size
  ssh_keys            = [digitalocean_ssh_key.miab.fingerprint]

  depends_on = [digitalocean_spaces_bucket.miab]

  provisioner  "remote-exec" {
    connection {
      type = "ssh"
      user = "root"
      host = digitalocean_droplet.miab.ipv4_address
      private_key = file(var.ssh_private_key)
      agent = false
    }

    inline = [
      # Mail-in-a-Box environment variables
      "export NONINTERACTIVE=1",
      "export PRIMARY_HOSTNAME=box.${digitalocean_domain.miab.name}",
      "export PUBLIC_IP=auto",
      "export STORAGE_ROOT=${var.miab_STORAGE_ROOT}",
      "export STORAGE_USER=${var.droplet_name}",

      # Update, upgrade packages, and install S3 filesystem for DO Spaces
      "apt-get update && apt-get upgrade -y",
      "apt-get install -y s3fs",

      # Write Spaces access ID and secret key to remote filesystem
      "echo ${var.spaces_access_id}:${var.spaces_secret_key} > /root/.passwd-s3fs",
      "chmod 600 /root/.passwd-s3fs",
      "mkdir -p ${var.miab_STORAGE_ROOT}/backup",

      # Mount Spaces bucket using s3fs
      "echo 's3fs#${var.droplet_name} ${var.miab_STORAGE_ROOT}/backup fuse _netdev,allow_other,use_path_request_style,url=https://${var.droplet_region}.digitaloceanspaces.com 0 0' >> /etc/fstab",
      "mount -a",

      # Install Mail-in-a-box
      "curl -s https://mailinabox.email/setup.sh | sudo -E bash",

      # Install Digital Ocean metrics agent
      "curl -sSL https://repos.insights.digitalocean.com/install.sh | sudo bash",
    ]
  }
}

output "floating_ip_address" {
  value     = digitalocean_floating_ip.miab.ip_address
  sensitive = true
}
