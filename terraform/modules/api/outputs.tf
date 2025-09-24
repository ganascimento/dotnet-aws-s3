output "instance_id" {
  description = "ID da instância EC2 criada"
  value       = aws_instance.api.id
}

output "public_ip" {
  description = "IP público da instância EC2"
  value       = aws_instance.api.public_ip
}

output "ec2_public_ip" {
  value = aws_instance.api.public_ip
}

output "private_key_pem" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}