output "id" {
  description = "ID de la instancia"
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "IP privada de la instancia"
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "IP publica de la instancia"
  value       = aws_instance.this.public_ip
}

output "public_dns" {
  description = "DNS publico de la instancia"
  value       = aws_instance.this.public_dns
}
