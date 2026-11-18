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
# Instancia
#
# UNA sola maquina con todo el escenario. Es un requisito del enunciado: el
# socket Unix entre Nginx y Gunicorn solo funciona si ambos estan en la misma
# maquina (y el permiso de grupo del socket depende del grupo primario del
# proceso Gunicorn).
# ---------------------------------------------------------------------------

module "instances" {
  source = "./modules/instances"

  name               = "${var.project_name}-${var.environment}"
  ami_id             = data.aws_ami.ubuntu.id
  instance_type      = var.instance_type
  subnet_id          = local.subnet_id
  vpc_id             = data.aws_vpc.default.id
  security_group_ids = [local.sg_flask]
  key_name           = aws_key_pair.deploy.key_name
  volume_size        = var.volume_size

  tags = merge(
    {
      Role = "flask-apps"
    },
    var.tags,
  )
}
