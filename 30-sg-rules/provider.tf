terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.18.0"
    }
  }

  backend "s3" {
    bucket = "remote-state-poguri-dev"
    key = "roboshop-dev-sg-rules"
    region = "us-east-1"
    use_lockfile = true
    encrypt =  true
  }
  }


provider "aws" {
  region = "us-east-1"
}