# store the terraform state file in s3
terraform {
  backend "s3" {
    bucket = "tk-tfstate-remote-backend-dev-account001"
    key    = "jupiter-website-ecs.tfstate"
    region = "eu-west-2"
    #profile   = default
  }
}