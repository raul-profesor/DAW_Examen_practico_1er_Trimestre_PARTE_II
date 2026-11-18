provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Practice    = "P3.1"
    }
  }
}

# ---------------------------------------------------------------------------
# Red: reutilizamos la VPC y la subred publica por defecto de la cuenta.
#
# Asi el alumno no necesita crear VPC ni subredes: basta con tener una cuenta
# AWS con una VPC por defecto. Si la cuenta no tiene subred publica por
# defecto, se puede indicar una concreta con la variable `default_subnet_id`.
# ---------------------------------------------------------------------------

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Subred publica por defecto que usaran las instancias.
locals {
  default_subnet_ids = data.aws_subnets.default.ids
}
