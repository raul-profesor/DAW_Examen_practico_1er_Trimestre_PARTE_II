# ---------------------------------------------------------------------------
# Security groups
#
#   SG "web" -> SSH (22) desde el mundo + HTTP (80) desde el mundo
#   SG "fpm" -> SSH (22) desde el mundo + FastCGI (9000) DESDE EL SG "web"
#
# En este escenario el security group de PHP-FPM es CORRECTO: abre el
# `fpm_fastcgi_port` (9000), que es donde realmente escucha PHP-FPM, y
# solo desde el SG de la maquina de NGINX.
#
# ERROR INTENCIONADO (a): NO esta aqui, sino en el cliente: la directiva
# fastcgi_pass del NGINX apunta al puerto 9001 (fpm_fastcgi_wrong_port),
# donde no escucha nadie -> 502 Bad Gateway.
# ---------------------------------------------------------------------------

resource "aws_security_group" "web" {
  name        = "${var.project_name}-${var.environment}-web-sg"
  description = "Acceso SSH y HTTP (nginx) - escenario ${var.environment}"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH desde cualquier origen (administracion)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP desde cualquier origen (sitio web publico)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Salida a Internet (apt, git clone)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-sg"
  }
}

resource "aws_security_group" "fpm" {
  name        = "${var.project_name}-${var.environment}-fpm-sg"
  description = "Acceso SSH y FastCGI (9000) restringido al SG de nginx - escenario ${var.environment}"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH desde cualquier origen (administracion)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Salida a Internet (apt, git clone)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-fpm-sg"
  }
}

# ---------------------------------------------------------------------------
# Regla FastCGI: el SG de PHP-FPM admite TODO el trafico TCP al puerto
# {{ var.fpm_fastcgi_port }} (9000) que venga del SG de la maquina de
# NGINX (el proxy). No se restringe por IP: el origen es el propio SG.
#
# Se usa el recurso "aws_vpc_security_group_ingress_rule" (y no el legacy
# "aws_security_group_rule") a proposito: el legacy hace UPSERT por
# (grupo, protocolo, puertos, origen) y se queda "satisfecho" si ya
# existe una regla equivalente, de modo que si alguien borra la regla a
# mano Terraform no la vuelve a crear y el escenario se queda sin
# permisos de entrada al FastCGI. El recurso moderno gestiona cada regla
# por su propio ID, asi que siempre se crea y siempre se destruye bien.
# ---------------------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "fpm_fastcgi" {
  description                  = "FastCGI (TCP ${var.fpm_fastcgi_port}) solo desde el SG de nginx"
  from_port                    = var.fpm_fastcgi_port
  to_port                      = var.fpm_fastcgi_port
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.fpm.id
  referenced_security_group_id = aws_security_group.web.id
}

# En este escenario siempre hay dos maquinas: la de NGINX usa el SG "web"
# y la de PHP-FPM el SG "fpm".
locals {
  sg_web = aws_security_group.web.id
  sg_fpm = aws_security_group.fpm.id
}
