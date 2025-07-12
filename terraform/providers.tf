# root/providers.tf (or global/providers.tf)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Lock to a major version
    }
    kubernetes = { # You'll need this for Helm deployments later
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = { # You'll need this for Helm deployments later
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    # Add other providers as needed (e.g., cloudflare, random, null)
  }
}

provider "aws" {
  region = var.aws_region # Get region from a root variable, passed from environment .tfvars
  # You might define `profile` or `assume_role` here for authentication if not using environment variables
}

# Provider for Kubernetes, configured after EKS cluster is deployed
provider "kubernetes" {
  host                   = module.eks_cluster.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.eks_cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks_cluster.eks_cluster_id
}

# Provider for Helm, configured after Kubernetes provider
provider "helm" {
  kubernetes {
    host                   = module.eks_cluster.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.eks_cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

# It's good practice to define a variable for region at the root or within environments
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}