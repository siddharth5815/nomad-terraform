output "bastion_public_ip" {
  description = "Bastion public IP"
  value       = aws_instance.bastion.public_ip
}

output "nomad_server_private_ip" {
  description = "Nomad server private IP"
  value       = aws_instance.nomad_server.private_ip
}

output "nomad_server_public_ip" {
  description = "Nomad server public IP"
  value       = aws_instance.nomad_server.public_ip
}

output "client_public_ips" {
  value = [for c in aws_instance.nomad_client : c.public_ip]
}
