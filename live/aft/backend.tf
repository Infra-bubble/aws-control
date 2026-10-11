terraform {
  # Backend blocks can't use var. or local. - values must be literals
  backend "s3" {
    bucket       = "meridian-payments-ltd-management-tfstate-bucket"
    key          = "aft/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
}
