terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}