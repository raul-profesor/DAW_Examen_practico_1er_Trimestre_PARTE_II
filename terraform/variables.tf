# ---------------------------------------------------------------------------
# Variables del escenario de DEBUGGING (v3-debug)
#
# Este repositorio despliega un unico escenario: NGINX y PHP-FPM en maquinas
# separadas (topologia "split") con dos errores introducidos a proposito.
# ---------------------------------------------------------------------------

variable "aws_region" {
  description = "Region de AWS donde se despliega"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefijo de los recursos (nombres de SG, claves, tags)"
  type        = string
  default     = "running-zones"
}

variable "environment" {
  description = "Nombre del escenario (solo se usa para nombrar los recursos)"
  type        = string
  default     = "v3-debug"
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
    Subred publica por defecto donde se lanzan las instancias.
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

variable "fpm_fastcgi_port" {
  description = <<-EOT
    Puerto TCP de FastCGI que abre el security group de la maquina de PHP-FPM
    (la regla tiene como ORIGEN el security group de la maquina de NGINX).

    En este repositorio vale 9000, que es donde realmente escucha PHP-FPM:
    el security group es CORRECTO.
  EOT
  type        = number
  default     = 9000
}

variable "fpm_fastcgi_wrong_port" {
  description = <<-EOT
    Puerto ERRONEO al que apunta la directiva fastcgi_pass del NGINX.

    ERROR INTENCIONADO: vale 9001, pero PHP-FPM escucha en el
    `fpm_fastcgi_correct_port` (9000). El unico que esta mal es el cliente.
  EOT
  type        = number
  default     = 9001
}

variable "fpm_fastcgi_correct_port" {
  description = "Puerto en el que realmente escucha PHP-FPM (el correcto)"
  type        = number
  default     = 9000
}

variable "tags" {
  description = "Tags adicionales para las instancias"
  type        = map(string)
  default     = {}
}
