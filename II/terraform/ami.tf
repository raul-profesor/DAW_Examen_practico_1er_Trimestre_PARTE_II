# ---------------------------------------------------------------------------
# AMI de Ubuntu Server 24.04 LTS (Canonical).
#
# Se busca la mas reciente para la region configurada, de forma que el
# despliegue no dependa de un identificador de AMI concreto que caduca.
# ---------------------------------------------------------------------------

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name = "name"
    # Canonical publica las imagenes de Ubuntu Server 24.04 (noble) en dos
    # rutas, segun el tipo de volumen EBS del AMI:
    #   hvm-ssd      -> imagenes con EBS classic
    #   hvm-ssd-gp3  -> imagenes con EBS gp3 (las nuevas)
    # Se aceptan ambas para no depender de la ruta usada por Canonical en el
    # momento del despliegue.
    values = [
      "ubuntu/images/hvm-ssd/ubuntu-noble-24.04-amd64-server-*",
      "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*",
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
