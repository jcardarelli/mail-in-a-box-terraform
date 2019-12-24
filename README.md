# Mail in a box on Digital Ocean via terraform

## Requirements
* Terraform v12+
* Digital Ocean token
* Digital Ocean Spaces access id
* Digital Ocean Spaces secret key

## Infrastructure provisioned by Terraform
* `digitalocean_domain` - Digital Ocean DNS domain name to use for MIAB
* `digitalocean_record` - DNS A record for domain
* `digitalocean_floating_ip` - Static IP for Droplet
* `digitalocean_ssh_key` - Separate SSH key created for the droplet
* `digitalocean_spaces_bucket` - Block storage for MIAB backup directory
* `digitalocean_droplet` - VM that will run MIAB

## Usage
1. Install terraform version 12.
2. `cp example-vars.tf vars.tf`.
3. Write Digital Ocean keys to `vars.tf`, and replace variables as necessary.
4. Run `terraform init`.
5. Run `terraform plan`.
6. Run `terraform apply` if there were no errors during `terraform plan`.
