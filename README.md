# Mail-in-a-Box on Digital Ocean via terraform

This repo will create a Digital Ocean Droplet running Ubuntu 18.04 that has the following configuration:
* [Floating IP](https://www.digitalocean.com/docs/networking/floating-ips) for the Droplet address.
* [Spaces](https://www.digitalocean.com/docs/spaces) bucket for `/home/user-data/backups` to avoid filling up a small disk with backups.
  * Yes, you could definitely use `rsync`, but this way we don't have to ship the backup data anywhere.
* Domain and DNS configuration via [Digital Ocean DNS](https://www.digitalocean.com/docs/networking/dns).
* Reads your local SSH key and creates a new SSH key on Digital Ocean.

## Requirements
* Terraform version 0.12+
* Digital Ocean token
* Digital Ocean Spaces access id
* Digital Ocean Spaces secret key

## Infrastructure provisioned by Terraform
* `digitalocean_domain` - Digital Ocean DNS domain name to use for MIAB
* `digitalocean_record` - DNS A record for domain
* `digitalocean_floating_ip` - Static IP for Droplet
* `digitalocean_ssh_key` - Separate SSH key created for the droplet
* `digitalocean_spaces_bucket` - Object storage for MIAB backup directory
* `digitalocean_droplet` - VM that will run MIAB

## Usage
1. [Install terraform version 0.12](https://www.terraform.io/downloads.html).
2. Fill in the variables from Example Variables, and write them to `vars.tf`.
3. Write Digital Ocean keys to `vars.tf`, and replace variables as necessary.
4. Run `terraform init`.
5. Run `terraform plan`.
6. Run `terraform apply` if there were no errors during `terraform plan`.

## Example Variables
```
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
```
