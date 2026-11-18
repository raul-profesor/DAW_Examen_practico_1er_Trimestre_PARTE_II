# ---------------------------------------------------------------------------
# Escenario v3-debug - NGINX + PHP-FPM en maquinas separadas
#
# Uso:
#   make deploy        (equivalente a terraform apply + ansible-playbook)
# ---------------------------------------------------------------------------

aws_region    = "us-east-1"
environment   = "v3-debug"
instance_type = "t3.small"
volume_size   = 20
allowed_cidr  = "0.0.0.0/0"

# Puertos de FastCGI.
fpm_fastcgi_port         = 9000
fpm_fastcgi_correct_port = 9000
fpm_fastcgi_backend_port = 9001

tags = {
  Scenario    = "v3-debug"
  Description = "Escenario NGINX + PHP-FPM en maquinas separadas"
}
