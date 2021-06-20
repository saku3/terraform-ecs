terraform {
  backend "s3" {
    bucket = "aws-terraform-ecs-123454321"
    key    = "dev/terraform.tfstate"
    region = "ap-northeast-1"
  }

  required_providers {
    aws = {
      version = "~> 3.37"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      Name = var.project
    }
  }
}
