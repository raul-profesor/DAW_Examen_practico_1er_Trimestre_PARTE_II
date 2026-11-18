# ---------------------------------------------------------------------------
# Par de claves SSH
#
# En vez de subir una clave publica ya hecha, la generamos con Terraform y
# guardamos la privada en disco (con permisos 0600) para poder usarla con
# ssh/sftp. El fichero publico se registra en EC2 para que las instancias la
# acepten.
# ---------------------------------------------------------------------------

resource "tls_private_key" "deploy" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "deploy_private_key" {
  filename             = "${path.module}/.ssh/${var.project_name}-${var.environment}.pem"
  content              = tls_private_key.deploy.private_key_pem
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "local_file" "deploy_public_key" {
  filename             = "${path.module}/.ssh/${var.project_name}-${var.environment}.pub"
  content              = tls_private_key.deploy.public_key_openssh
  file_permission      = "0644"
  directory_permission = "0700"
}
