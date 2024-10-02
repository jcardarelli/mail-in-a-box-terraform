variable "do_token" {
  description = "Token to authenticate with your Digital Ocean account."
}

variable "do_region" {
  description = "Digital Ocean region where the MiaB droplet will be hosted."
}

variable "spaces_backup_enabled" {
  default     = false
  description = "If enabled, a spaces bucket will be created, and miab will send backups there."
}

variable "spaces_access_id" {
  description = "Digital Ocean Spaces access ID."
}

variable "spaces_secret_key" {
  description = "Digital Ocean Spaces secret key."
}

variable "fqdn" {
  description = "Domain name for your email server. This is typically box.example.com, and your email address would be you@example.com."
}

variable "droplet_image" {
  default     = "ubuntu-22-04-x64"
  description = "Base OS image to use for the MiaB droplet."
}

variable "droplet_private_networking" {
  default     = "true"
  description = "Enable private networking for miab droplet."
}

variable "droplet_size" {
  default     = "s-1vcpu-1gb"
  description = "CPU and memory sizing for the MiaB droplet."
}

variable "ssh_private_key" {
  description = "The path to the SSH key you'd like to access the MiaB host with."
}

variable "miab_STORAGE_ROOT" {
  default     = "/root/miab/"
  description = "Base directory for MiaB files."
}

variable "ssh_port" {
  description = "Non-default port for SSH"
}
