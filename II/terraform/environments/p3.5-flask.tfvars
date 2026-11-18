# ---------------------------------------------------------------------------
# Escenario p3.5-flask - DOS aplicaciones Flask en una sola maquina
#
# Topologia: una EC2 con Nginx + Gunicorn(mi_app) + Gunicorn(atletismo).
# Nginx se comunica con cada Gunicorn por un socket Unix distinto.
#
# Uso:
#   make deploy        (equivalente a terraform apply + ansible-playbook)
# ---------------------------------------------------------------------------

aws_region    = "us-east-1"
environment   = "p3.5-flask-debug"
instance_type = "t3.small"
volume_size   = 20
allowed_cidr  = "0.0.0.0/0"

ssh_port = 22
app_port = 80

tags = {
  Scenario    = "p3.5-flask-debug"
  Description = "Escenario Flask + Gunicorn + Nginx con dos aplicaciones"
}
