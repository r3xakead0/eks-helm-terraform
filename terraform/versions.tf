terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.27"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.13"
    }
  }

  #   backend "s3" {
  #     bucket         = "eks-demo-4565-tf-state-files"
  #     key            = "eks/dev/terraform.tfstate"
  #     region         = "us-east-1"
  #     dynamodb_table = "eks-demo-4565-tf-locks"
  #     encrypt        = true
  #   }

}
