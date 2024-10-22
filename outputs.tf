output "droplet_id" {
  description = "ID of MiaB droplet"
  value       = digitalocean_droplet.miab.id
}

output "ssh_port" {
  description = "SSH port for MiaB droplet"
  value       = random_integer.ssh_port.result
}
