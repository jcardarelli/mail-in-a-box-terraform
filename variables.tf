variable "do_token" {
  default     = "****************************************************************"
  description = "Token to authenticate with your Digital Ocean account."
}

variable "do_region" {
  default     = "sfo2"
  description = "Digital Ocean region where the MiaB droplet will be hosted."
}

variable "spaces_access_id" {
  default     = "********************"
  description = "Digital Ocean Spaces access ID."
}

variable "spaces_secret_key" {
  default     = "*******************************************"
  description = "Digital Ocean Spaces secret key."
}

variable "fqdn" {
  default     = "yourdomain.com"
  description = "Domain name for your email server. This is typically box.example.com, and your email address would be you@example.com."
}

variable "droplet_image" {
  default     = "ubuntu-24-04-x64"
  description = "Base OS image to use for the MiaB droplet."
}

variable "droplet_private_networking" {
  default     = "true"
  description = "Enable private networking for miab droplet."
}

variable "droplet_region" {
  default     = "sfo2"
  description = "Digital Ocean region where the MiaB droplet will be hosted."
}

variable "droplet_size" {
  default     = "s-1vcpu-1gb"
  description = "CPU and memory sizing for the MiaB droplet."
}

variable "ssh_private_key" {
  default     = "$HOME/.ssh/id_rsa"
  description = "The path to the SSH key you'd like to access the MiaB host with."
}
