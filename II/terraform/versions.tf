# ---------------------------------------------------------------------------
# Versions de Terraform y providers
#
# Este escenario solo despliega INFRAESTRUCTURA (una maquina EC2). Todo lo
# que es software (Nginx, Gunicorn, Python, las aplicaciones) lo instala
# Ansible.
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }

  # El estado se guarda localmente. Para uso classroom es suficiente; en
  # produccion se usaria un backend remoto con bloqueo.
}
