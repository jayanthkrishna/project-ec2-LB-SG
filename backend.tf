terraform {
  backend "s3" {
    bucket = "ec2-public-subnet-s3-with-lb"
    key    = "jayanth/terraform.tfstate"
    region = "ap-south-1"
  }
}