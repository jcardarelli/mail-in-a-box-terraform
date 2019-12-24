provider "digitalocean" {
  token = var.do_token
	spaces_access_id = var.spaces_access_id
  spaces_secret_key = var.spaces_secret_key
}

resource "digitalocean_domain" "miab" {
  name = var.fqdn
}

resource "digitalocean_record" "miab" {
  domain = digitalocean_domain.miab.name
  type   = "A"
  name   = var.droplet_name
  value  = digitalocean_droplet.miab.ipv4_address_private
}

resource "digitalocean_record" "miab_box" {
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

  # cors_rule {
  #   allowed_headers = ["*"]
  #   allowed_methods = ["*"]
  #   allowed_origins = [digitalocean_droplet.miab.ipv4_address_private]
  #   max_age_seconds = 3000
  # }
}

resource "digitalocean_droplet" "miab" {
  image    					 = var.droplet_image
  name     					 = var.droplet_name
  private_networking = var.droplet_private_networking
  region   					 = var.droplet_region
  size     					 = var.droplet_size
  ssh_keys 					 = [digitalocean_ssh_key.miab.fingerprint]

	depends_on = [digitalocean_spaces_bucket.miab]

	provisioner	"remote-exec" {
		connection {
			type = "ssh"
			user = "root"
			host = digitalocean_droplet.miab.ipv4_address
			private_key = file(var.ssh_private_key)
			agent = false
		}

		inline = [
      # Update, upgrade packages, and install S3 filesystem for DO Spaces
			"apt-get update && apt-get upgrade -y",
			"apt-get install -y s3fs",

      # Write Spaces access ID and secret key to remote filesystem
			"echo ${var.spaces_access_id}:${var.spaces_secret_key} > /root/.passwd-s3fs",
			"chmod 600 /root/.passwd-s3fs",
			"mkdir -p /home/user-data/backup",

      # TODO: Fix the double mount issue that this s3fs cmd, followed by the mount -a creates
			"s3fs ${var.droplet_name} /home/user-data/backup -ourl=https://${var.droplet_region}.digitaloceanspaces.com -ouse_cache=/tmp",
      "echo 's3fs#${var.droplet_name} /home/user-data/backup fuse _netdev,allow_other,use_path_request_style,url=https://${var.droplet_region}.digitaloceanspaces.com 0 0' >> /etc/fstab",
      "mount -a",

      # Install Mail-in-a-box
      "export NONINTERACTIVE=1",
      "export PRIMARY_HOSTNAME=box.${digitalocean_domain.miab.name}",
      "export PUBLIC_IP=auto",
      "export STORAGE_ROOT=/home/user-data",
      "export STORAGE_USER=${var.droplet_name}",
      "curl -s https://mailinabox.email/setup.sh | sudo -E bash",
		]
	}
}

output "floating_ip_address" {
  value     = digitalocean_floating_ip.miab.ip_address
  sensitive = true
}
