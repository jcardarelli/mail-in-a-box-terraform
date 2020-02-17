provider "digitalocean" {
  token = var.do_token
  spaces_access_id = var.spaces_access_id
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
  name       = "Mail in a box"
  public_key = file("${var.ssh_private_key}.pub")
}

# Bucket for MIAB/Nextcloud FUSE mount
resource "digitalocean_spaces_bucket" "miab" {
  name   = "box.${var.fqdn}"
  region = var.do_region

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
  name                = "box.${var.fqdn}"
  private_networking  = var.droplet_private_networking
  region              = var.do_region
  size                = var.droplet_size
  ssh_keys            = [digitalocean_ssh_key.miab.fingerprint]

  depends_on = [digitalocean_spaces_bucket.miab]

  provisioner  "remote-exec" {
    connection {
      type        = "ssh"
      user        = "root"
      host        = digitalocean_droplet.miab.ipv4_address
      private_key = file(var.ssh_private_key)
      agent       = false
    }

    inline = [<<EOF
#!/bin/bash
set -e

# Mail-in-a-Box environment variables
export NONINTERACTIVE=1
export PRIMARY_HOSTNAME=box.${var.fqdn}
export PUBLIC_IP=${digitalocean_floating_ip.miab.ip_address}
export STORAGE_ROOT=${var.miab_STORAGE_ROOT}

# Update, upgrade packages, and install S3 filesystem for DO Spaces
apt-get update && apt-get upgrade -y
apt-get install -y s3fs jq

# Write Spaces access ID and secret key to remote filesystem
echo ${var.spaces_access_id}:${var.spaces_secret_key} > /root/.passwd-s3fs
chmod 600 /root/.passwd-s3fs
mkdir -p ${var.miab_STORAGE_ROOT}/backup

# Mount Spaces bucket using s3fs
echo 's3fs#box.${var.fqdn} ${var.miab_STORAGE_ROOT}/backup fuse _netdev,allow_other,use_path_request_style,url=https://${var.do_region}.digitaloceanspaces.com 0 0' >> /etc/fstab
mount -a

# Get the IDs for all ns*.digitalocean.com nameserver records
ids=$(curl -s -X GET \
-H "Content-Type: application/json" \
-H "Authorization: Bearer ${var.do_token}" \
"https://api.digitalocean.com/v2/domains/${var.fqdn}/records" \
| jq '.domain_records[] | select (.data|test("ns[1,2,3].digitalocean.com")) | .id')

if [[ -z $ids ]]; then
  echo "Could not find nameserver IDs"
  exit 1
fi

for id in $ids; do
  echo "Deleting NS record with ID $id"

  if curl -X DELETE -H \
    "Content-Type: application/json" \
    -H "Authorization: Bearer ${var.do_token}" \
    "https://api.digitalocean.com/v2/domains/${var.fqdn}/records/$id"; then
    echo "Removed default nameserver record $ns with ID $id"
  fi
done

# Install Mail-in-a-box
curl -s https://mailinabox.email/setup.sh | sudo -E bash

# Install Digital Ocean metrics agent
curl -sSL https://repos.insights.digitalocean.com/install.sh | sudo bash

# Only allow SSH connections via the Droplet IP
sed -i 's/#ListenAddress 0.0.0.0/ListenAddress ${digitalocean_droplet.miab.ipv4_address}/' /etc/ssh/sshd_config
sed -i 's/#Port 22/Port ${var.ssh_port}/' /etc/ssh/sshd_config
echo 'restart SSH to reload with new settings: service sshd restart'
EOF
    ]
  }
}

output "floating_ip_address" {
  value     = digitalocean_floating_ip.miab.ip_address
  sensitive = true
}
