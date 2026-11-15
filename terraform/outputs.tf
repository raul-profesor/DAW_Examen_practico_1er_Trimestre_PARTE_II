# ---------------------------------------------------------------------------
# Outputs
#
# Ademas de exponer las IPs, generamos:
#   - el inventario de Ansible (formato INI) que consume el playbook
#   - un fichero .env con los datos de conexion (para SSH manual)
# ---------------------------------------------------------------------------

output "instance_ids" {
  description = "IDs de las instancias creadas"
  value       = module.instances[*].id
}

output "web_public_ip" {
  description = "IP publica de la instancia con nginx"
  value       = module.instances[0].public_ip
}

output "web_private_ip" {
  description = "IP privada de la instancia con nginx"
  value       = module.instances[0].private_ip
}

output "fpm_public_ip" {
  description = "IP publica de la instancia con php-fpm"
  value       = module.instances[1].public_ip
}

output "fpm_private_ip" {
  description = "IP privada de la instancia con php-fpm"
  value       = local.fpm_private_ip
}

output "site_url" {
  description = "URL publica de la aplicacion"
  value       = "http://${module.instances[0].public_ip}/"
}

output "private_key_path" {
  description = "Ruta de la clave privada SSH generada"
  value       = local_file.deploy_private_key.filename
}

output "ansible_inventory_path" {
  description = "Ruta del inventario de Ansible generado"
  value       = local_file.ansible_inventory.filename
}

output "fpm_security_group_id" {
  description = "ID del security group de la maquina de PHP-FPM"
  value       = aws_security_group.fpm.id
}

output "web_security_group_id" {
  description = "ID del security group de la maquina de NGINX"
  value       = aws_security_group.web.id
}

output "fpm_fastcgi_rule_id" {
  description = "ID de la regla de ingress FastCGI del SG de PHP-FPM"
  value       = aws_vpc_security_group_ingress_rule.fpm_fastcgi.security_group_rule_id
}

output "fpm_fastcgi_port" {
  description = "Puerto destino de la regla FastCGI del SG de PHP-FPM"
  value       = var.fpm_fastcgi_port
}

output "fpm_fastcgi_correct_port" {
  description = "Puerto en el que realmente escucha PHP-FPM (el correcto)"
  value       = var.fpm_fastcgi_correct_port
}

output "fpm_fastcgi_wrong_port" {
  description = "Puerto erroneo al que apunta el fastcgi_pass del NGINX"
  value       = var.fpm_fastcgi_wrong_port
}

# ---------------------------------------------------------------------------
# Inventario de Ansible generado por Terraform
#
# Este fichero se escribe en disco y es el que usa el playbook. Es launion
# "Terraform crea la infraestructura -> Terraform genera el inventario ->
# Ansible configura el software".
# ---------------------------------------------------------------------------

resource "local_file" "ansible_inventory" {
  filename             = "${path.module}/../ansible/inventory/hosts.ini"
  content              = local.ansible_inventory_content
  file_permission      = "0600"
  directory_permission = "0755"
}

locals {
  ansible_inventory_content = <<-EOT
    # ==========================================================
    # Inventario generado automaticamente por Terraform
    # Escenario: ${var.environment} (debugging)
    # NO EDITAR A MANO: se regenera en cada `terraform apply`.
    # ==========================================================

    [all:vars]
    scenario=${var.environment}
    fpm_private_ip=${local.fpm_private_ip}
    # Datos de la regla FastCGI del SG de PHP-FPM (para el escenario de debugging)
    fpm_sg_id=${aws_security_group.fpm.id}
    web_sg_id=${aws_security_group.web.id}
    fpm_fastcgi_rule_id=${aws_vpc_security_group_ingress_rule.fpm_fastcgi.security_group_rule_id}
    fpm_fastcgi_port=${var.fpm_fastcgi_port}
    fpm_fastcgi_correct_port=${var.fpm_fastcgi_correct_port}
    fpm_fastcgi_wrong_port=${var.fpm_fastcgi_wrong_port}

    [web]
    ${module.instances[0].public_ip} ansible_host=${module.instances[0].public_ip}

    [web:vars]
    ansible_user=ubuntu
    ansible_ssh_private_key_file=${abspath(local_file.deploy_private_key.filename)}
    ansible_python_interpreter=/usr/bin/python3

    [fpm]
    ${module.instances[1].public_ip} ansible_host=${module.instances[1].public_ip}

    [fpm:vars]
    ansible_user=ubuntu
    ansible_ssh_private_key_file=${abspath(local_file.deploy_private_key.filename)}
    ansible_python_interpreter=/usr/bin/python3
  EOT
}
