terraform {
  backend "s3" {
    bucket         = "terraform-state-kubon-tech"
    key            = "terraform/states/test.tfstate"
    region         = "eu-central-1"
    # dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}