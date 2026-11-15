# ---------------------------------------------------------------------------
# Seleccion de la subred
#
# Si el alumno indica `default_subnet_id` se usa esa; si no, se toma la
# primera subred disponible de la VPC por defecto.
# ---------------------------------------------------------------------------

locals {
  subnet_id = var.default_subnet_id != "" ? var.default_subnet_id : local.default_subnet_ids[0]
}

# ---------------------------------------------------------------------------
# Par de claves EC2
#
# La clave privada se genera con el provider tls y se guarda en disco; el
# par publico se registra en EC2 para que las instancias la acepten.
# ---------------------------------------------------------------------------

resource "aws_key_pair" "deploy" {
  key_name   = "${var.project_name}-${var.environment}"
  public_key = tls_private_key.deploy.public_key_openssh

  tags = {
    Name = "${var.project_name}-${var.environment}"
  }
}

# ---------------------------------------------------------------------------
# Instancias
#
# El escenario de debugging usa siempre topologia "split": dos maquinas.
#   - "web": NGINX (la unica expuesta a Internet)
#   - "fpm": PHP-FPM + el codigo de la aplicacion
#
# Se comunican por FastCGI/TCP. El security group de FPM acepta el trafico
# en el puerto `fpm_fastcgi_port` (9000: el correcto) viniendo del
# security group de la maquina de NGINX.
# ---------------------------------------------------------------------------

module "instances" {
  source = "./modules/instances"

  count = 2

  name               = count.index == 0 ? "${var.project_name}-web" : "${var.project_name}-fpm"
  ami_id             = data.aws_ami.ubuntu.id
  instance_type      = var.instance_type
  subnet_id          = local.subnet_id
  vpc_id             = data.aws_vpc.default.id
  security_group_ids = count.index == 0 ? [local.sg_web] : [local.sg_fpm]
  key_name           = aws_key_pair.deploy.key_name
  volume_size        = var.volume_size

  tags = merge(
    {
      Role = count.index == 0 ? "web" : "fpm"
    },
    var.tags,
  )
}

locals {
  # IP privada de la maquina con PHP-FPM (la que usa NGINX para el FastCGI)
  fpm_private_ip = module.instances[1].private_ip
}
