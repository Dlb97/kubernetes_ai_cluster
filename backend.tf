terraform {
  backend "s3" {
    key    = "state/genai_gateway/terraform.tfstate"
    region = "us-east-1"
  }
}
