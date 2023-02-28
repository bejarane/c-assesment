terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 4.0"
    }
  }
    backend "s3" {
    bucket = "bejarane-bucket"
    key    = "terraform/CM/postbuild"
    region = "us-east-1"
    //dynamodb_table = "terraform_state"
  }
}