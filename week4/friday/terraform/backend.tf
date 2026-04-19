terraform {
  backend "s3" {
    bucket         = "kijanikiosk-tfstate"
    key            = "week4/friday/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "kijanikiosk-tfstate-lock"
    encrypt        = true
  }
}
