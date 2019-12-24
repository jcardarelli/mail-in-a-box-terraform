variable "do_token" {
	default = "****************************************************************"
}

variable "spaces_access_id" {
  default = "********************"
}

variable "spaces_secret_key" {
  default = "*******************************************"
}

variable "fqdn" {
  default = "yourdomain.com"
}

variable "droplet_image" {
  default = "ubuntu-18-04-x64"
}

variable "droplet_name" {
  default = "miab"
}

variable "droplet_private_networking" {
	default = "true"
}

variable "droplet_region" {
  default = "sfo2"
}

variable "droplet_size" {
  default = "s-1vcpu-1gb"
}

variable "ssh_private_key" {
  default = "/home/your_user/.ssh/id_rsa"
}
