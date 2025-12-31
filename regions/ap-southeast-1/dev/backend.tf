terraform {
  backend "s3" {
    bucket = "nam-my-instance-tfstate-490004621103-ap-southeast-1"
    key = "terraform.tfstate"
    region = "ap-southeast-1"
  }
}