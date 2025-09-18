terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }

  # Optional remote state (recommended in real projects)
  # backend "s3" {
  #   bucket = "your-tf-state-bucket"
  #   key    = "nomad/terraform.tfstate"
  #   region = "ap-south-1"
  #   encrypt = true
  # }
}

provider "aws" {
  region = var.aws_region
}
