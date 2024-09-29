# Mail-in-a-Box Digital Ocean Terraform module

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
1. `cp varfile.tfvars terraform.tfvars`
1. Add Digital Ocean API key and Digital Ocean Spaces key info.
1. Run `terraform init`.
1. Run `terraform plan`.
1. Run `terraform apply` if there were no errors during `terraform plan`.

## Pre-commit hook to generate terraform graph files
Requires `graphviz` on your local system, which can be installed with `sudo apt install graphviz` or `brew install graphviz`.

Put this script in the file `.git/hooks/pre-commit` and run `chmod +x` to automatically add graphs for every git commit.

```bash
#!/usr/bin/env bash
COMMIT_HASH=$(git rev-parse HEAD | cut -b 1-6)

if ! command dot > /dev/null 2>&1; then
  echo "graphviz not found, terraform graph will not be generated."
else
  # Only run terraform graph when *.tf files change
  git diff --cached --name-only | if grep --silent \.tf; then
    mkdir -p graphs
    terraform graph > graphs/miab-${COMMIT_HASH}.dot
    dot graphs/miab-${COMMIT_HASH}.dot -Tsvg -o graphs/miab-${COMMIT_HASH}.svg
    git add graphs/miab-${COMMIT_HASH}.{svg,dot}
  fi
fi
```
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_digitalocean"></a> [digitalocean](#requirement\_digitalocean) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_digitalocean"></a> [digitalocean](#provider\_digitalocean) | ~> 2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [digitalocean_droplet.miab](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/droplet) | resource |
| [digitalocean_floating_ip.miab](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/floating_ip) | resource |
| [digitalocean_floating_ip_assignment.miab](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/floating_ip_assignment) | resource |
| [digitalocean_spaces_bucket.miab](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/spaces_bucket) | resource |
| [digitalocean_ssh_key.miab](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/ssh_key) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_do_region"></a> [do\_region](#input\_do\_region) | Digital Ocean region where the MiaB droplet will be hosted. | `any` | n/a | yes |
| <a name="input_do_token"></a> [do\_token](#input\_do\_token) | Token to authenticate with your Digital Ocean account. | `any` | n/a | yes |
| <a name="input_droplet_image"></a> [droplet\_image](#input\_droplet\_image) | Base OS image to use for the MiaB droplet. | `string` | `"ubuntu-24-04-x64"` | no |
| <a name="input_droplet_private_networking"></a> [droplet\_private\_networking](#input\_droplet\_private\_networking) | Enable private networking for miab droplet. | `string` | `"true"` | no |
| <a name="input_droplet_size"></a> [droplet\_size](#input\_droplet\_size) | CPU and memory sizing for the MiaB droplet. | `string` | `"s-1vcpu-1gb"` | no |
| <a name="input_fqdn"></a> [fqdn](#input\_fqdn) | Domain name for your email server. This is typically box.example.com, and your email address would be you@example.com. | `any` | n/a | yes |
| <a name="input_miab_STORAGE_ROOT"></a> [miab\_STORAGE\_ROOT](#input\_miab\_STORAGE\_ROOT) | Base directory for MiaB files. | `string` | `"/root/miab/"` | no |
| <a name="input_spaces_access_id"></a> [spaces\_access\_id](#input\_spaces\_access\_id) | Digital Ocean Spaces access ID. | `any` | n/a | yes |
| <a name="input_spaces_backup_enabled"></a> [spaces\_backup\_enabled](#input\_spaces\_backup\_enabled) | If enabled, a spaces bucket will be created, and miab will send backups there. | `bool` | `false` | no |
| <a name="input_spaces_secret_key"></a> [spaces\_secret\_key](#input\_spaces\_secret\_key) | Digital Ocean Spaces secret key. | `any` | n/a | yes |
| <a name="input_ssh_port"></a> [ssh\_port](#input\_ssh\_port) | Non-default port for SSH | `any` | n/a | yes |
| <a name="input_ssh_private_key"></a> [ssh\_private\_key](#input\_ssh\_private\_key) | The path to the SSH key you'd like to access the MiaB host with. | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_droplet_ip"></a> [droplet\_ip](#output\_droplet\_ip) | IP address of MiaB droplet |
| <a name="output_floating_ip_address"></a> [floating\_ip\_address](#output\_floating\_ip\_address) | n/a |
