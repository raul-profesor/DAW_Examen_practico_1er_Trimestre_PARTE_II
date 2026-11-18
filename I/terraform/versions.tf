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

  # El estado se guarda localmente en cada entorno (terraform/environments/<escenario>).
  # Para uso classroom es suficiente; en producción se usaría un backend remoto con
  # bloqueo (ver Tema 1 -> intro-terraform.md, apartado "State").
}
