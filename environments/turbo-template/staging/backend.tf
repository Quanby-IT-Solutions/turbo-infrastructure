terraform {
  backend "s3" {
    bucket         = "turbo-template-terraform-state"
    key            = "staging/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "turbo-template-terraform-locks"
    encrypt        = true
  }
}
