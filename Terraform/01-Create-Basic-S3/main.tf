terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1" 
}

variable "bucket_name" {
  default = "kubon-tech-terraform-bucket-123456"
}

resource "aws_s3_bucket" "s3_tmp" {
  bucket = var.bucket_name   
}

output "bucket_id" {
  value       = aws_s3_bucket.s3_tmp.id
}