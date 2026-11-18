# ---------------------------------------------------------------------------
# Outputs
#
# Ademas de exponer las IPs, generamos el inventario de Ansible (formato INI)
# que consume el playbook. Es la union:
#
#   Terraform crea la infraestructura -> Terraform genera el inventario ->
#   Ansible configura el software.
# ---------------------------------------------------------------------------

output "instance_id" {
  description = "ID de la instancia creada"
  value       = module.instances.id
}

output "public_ip" {
  description = "IP publica de la instancia"
  value       = module.instances.public_ip
}

output "private_ip" {
  description = "IP privada de la instancia"
  value       = module.instances.private_ip
}

output "public_dns" {
  description = "DNS publico de la instancia"
  value       = module.instances.public_dns
}

output "site_url" {
  description = "URL publica de las aplicaciones"
  value       = "http://${module.instances.public_ip}/"
}

output "app_url_mi_app" {
  description = "URL de la aplicacion PoC (mi_app)"
  value       = "http://${module.instances.public_ip}/"
}

output "app_url_atletismo" {
  description = "URL de la aplicacion de atletismo"
  value       = "http://${module.instances.public_ip}/"
}

output "security_group_id" {
  description = "ID del security group de las aplicaciones Flask"
  value       = aws_security_group.flask.id
}

output "private_key_path" {
  description = "Ruta de la clave privada SSH generada"
  value       = local_file.deploy_private_key.filename
}

output "ansible_inventory_path" {
  description = "Ruta del inventario de Ansible generado"
  value       = local_file.ansible_inventory.filename
}

# ---------------------------------------------------------------------------
# Inventario de Ansible generado por Terraform
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
    # Escenario: ${var.environment}
    # NO EDITAR A MANO: se regenera en cada `terraform apply`.
    # ==========================================================

    [all:vars]
    scenario=${var.environment}
    flask_public_ip=${module.instances.public_ip}
    flask_private_ip=${module.instances.private_ip}

    [flask]
    ${module.instances.public_ip} ansible_host=${module.instances.public_ip}

    [flask:vars]
    ansible_user=ubuntu
    ansible_ssh_private_key_file=${abspath(local_file.deploy_private_key.filename)}
    ansible_python_interpreter=/usr/bin/python3
  EOT
}
