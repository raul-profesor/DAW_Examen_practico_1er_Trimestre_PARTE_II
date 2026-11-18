# ---------------------------------------------------------------------------
# Variables del escenario p3.5-flask
#
# Este repositorio despliega un unico escenario: una maquina Ubuntu 24.04 con
# Nginx y las DOS aplicaciones Flask (mi_app y atletismo), cada una con su
# servicio systemd, su socket Unix y su virtual host.
# ---------------------------------------------------------------------------

variable "aws_region" {
  description = "Region de AWS donde se despliega"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefijo de los recursos (nombres de SG, claves, tags)"
  type        = string
  default     = "flask-p35"
}

variable "environment" {
  description = "Nombre del escenario (solo se usa para nombrar los recursos)"
  type        = string
  default     = "p3.5-flask"
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.small"
}

variable "volume_size" {
  description = "Tamano (GiB) del volumen raiz"
  type        = number
  default     = 20
}

variable "default_subnet_id" {
  description = <<-EOT
    Subred publica por defecto donde se lanza la instancia.
    Si se deja vacio, se usa la primera subred de la VPC por defecto.
  EOT
  type        = string
  default     = ""
}

variable "allowed_cidr" {
  description = "CIDR desde el que se permite el trafico HTTP/SSH"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_port" {
  description = "Puerto SSH que abre el security group"
  type        = number
  default     = 22
}

variable "app_port" {
  description = "Puerto HTTP que abre el security group (lo escucha Nginx)"
  type        = number
  default     = 80
}

variable "tags" {
  description = "Tags adicionales para la instancia"
  type        = map(string)
  default     = {}
}
