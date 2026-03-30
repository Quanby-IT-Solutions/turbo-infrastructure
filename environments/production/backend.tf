terraform {
  backend "s3" {
    bucket         = "turbo-template-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "turbo-template-terraform-locks"
    encrypt        = true
  }
}
