# ---------------------------------------------------------------------------
# Security group
#
# La topologia de este escenario es "una maquina con todo": Nginx, Gunicorn
# (mi_app) y Gunicorn (atletismo) viven en la MISMA EC2.
#
# Por eso solo hay UN security group, con dos reglas de entrada:
#   - SSH  (22): administracion
#   - HTTP (80): las dos aplicaciones se publican por ahi
#
# NO hay ninguna regla de entrada para Gunicorn: Nginx y Gunicorn se
# comunican por un SOCKET UNIX (/run/flask-app/mi_app.sock y
# /run/flask-atletismo/atletismo.sock), no por TCP. Esa es la diferencia
# clave respecto al escenario NGINX + PHP-FPM, donde si habia que abrir un
# puerto (9000) entre dos maquinas.
# ---------------------------------------------------------------------------

resource "aws_security_group" "flask" {
  name        = "${var.project_name}-${var.environment}-sg"
  description = "SSH y HTTP para las aplicaciones Flask - escenario ${var.environment}"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH desde cualquier origen (administracion)"
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "HTTP desde cualquier origen (las dos aplicaciones Flask)"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    description = "Salida a Internet (apt, git clone, API de Open-Meteo)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-sg"
  }
}

locals {
  sg_flask = aws_security_group.flask.id
}
