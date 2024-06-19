#!/usr/bin/env bash
set -e
cleanup() { echo "cleaned up"; }
error_handler() { echo "error at line: $1"; }
trap cleanup EXIT
trap 'error_handler $LINENO' ERR

SSH_PORT=24224

# Mail-in-a-Box environment variables
export NONINTERACTIVE=1
export PRIMARY_HOSTNAME="$1"
export PUBLIC_IP="$2"
PRIVATE_IP="$3"
export STORAGE_ROOT="$4"
DO_REGION="$5"

# Update, upgrade packages, and install S3 filesystem for DO Spaces
apt-get update && apt-get upgrade -y
apt-get install -y \
  jq \
  s3fs

# Write Spaces access ID and secret key to remote filesystem
echo "$SPACES_ACCESS_ID:$SPACES_SECRET_KEY" >/root/.passwd-s3fs
chmod 600 /root/.passwd-s3fs
mkdir -p "$STORAGE_ROOT/backup"

# Mount Spaces bucket using s3fs
echo "s3fs#$PRIMARY_HOSTNAME $STORAGE_ROOT/backup fuse _netdev,allow_other,use_path_request_style,url=https://$DO_REGION.digitaloceanspaces.com 0 0" >>/etc/fstab
mount -a

# Install Mail-in-a-box
curl -s https://mailinabox.email/setup.sh | sudo -E bash

# Install Digital Ocean metrics agent
curl -sSL https://repos.insights.digitalocean.com/install.sh | sudo bash

# Only allow SSH connections via the private Droplet IP
sed -i "s/#ListenAddress 0.0.0.0/ListenAddress $PRIVATE_IP/" /etc/ssh/sshd_config

# Change SSH to non-standard port
sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
ufw delete allow 22/tcp
ufw allow "$SSH_PORT"
echo 'restart SSH to reload with new settings: service sshd restart'
