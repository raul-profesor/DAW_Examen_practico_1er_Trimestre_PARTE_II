# ---------------------------------------------------------------------------
# Modulo "instances": crea una instancia EC2 con Ubuntu Server 24.04 lista
# para Ansible (cloud-init instala python3, necesario para el agente SSH).
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "name" {
  description = "Nombre (tag Name) de la instancia"
  type        = string
}

variable "ami_id" {
  description = "AMI de Ubuntu a usar"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.small"
}

variable "subnet_id" {
  description = "Subred donde se lanza la instancia"
  type        = string
}

variable "vpc_id" {
  description = "VPC de la instancia"
  type        = string
}

variable "security_group_ids" {
  description = "Security groups asociados a la instancia"
  type        = list(string)
}

variable "key_name" {
  description = "Nombre del par de claves EC2"
  type        = string
}

variable "public_ip" {
  description = "Si la instancia tiene IP publica"
  type        = bool
  default     = true
}

variable "volume_size" {
  description = "Tamano (GiB) del volumen raiz"
  type        = number
  default     = 20
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default     = {}
}

resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.key_name

  associate_public_ip_address = var.public_ip

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.volume_size
    encrypted             = true
    delete_on_termination = true
  }

  # cloud-init: deja python3 instalado para que Ansible pueda conectarse
  # en cuanto la instancia arranque.
  user_data = <<-EOT
    #cloud-config
    package_update: true
    packages:
      - python3
      - python3-apt
      - ca-certificates
  EOT

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(
    {
      Name = var.name
    },
    var.tags,
  )
}
