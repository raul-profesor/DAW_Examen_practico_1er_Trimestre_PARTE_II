# ---------------------------------------------------------------------------
# Provider de AWS
#
# Red: reutilizamos la VPC y la subred publica por defecto de la cuenta, para
# que no haga falta crear VPC ni subredes.
# ---------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Practice    = "P3.5"
    }
  }
}

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

locals {
  default_subnet_ids = data.aws_subnets.default.ids
}
