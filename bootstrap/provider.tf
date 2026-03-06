terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = local.aws_region

  default_tags {
    tags = {
      Project   = local.name_prefix
      ManagedBY = "Terraform"
    }
  }
}
