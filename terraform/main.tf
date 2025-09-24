terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  backend "s3" {
    bucket = "ganascimento-terraform-state"
    key    = "DotnetAwsS3API/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}

module "s3" {
  source        = "./modules/s3"
  bucket_name   = "ganascimento-dotnetawss3app-bucket"
  force_destroy = true
}

module "api" {
  source      = "./modules/api"
  ami_id      = "ami-0360c520857e3138f"
  bucket_arn  = module.s3.bucket_arn
  bucket_name = module.s3.bucket_id
}

output "ec2_public_ip" {
  value = module.api.public_ip
}

output "private_key_pem" {
  value     = module.api.private_key_pem
  sensitive = true
}
