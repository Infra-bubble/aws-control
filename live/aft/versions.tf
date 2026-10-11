terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# No provider block: the AFT module configures its own providers.
# Run with management account credentials (AWS_PROFILE / AWS_REGION);
# AFT assumes AWSControlTowerExecution into the other accounts itself.
