# Specify the AWS provider and the region where resources will be created
provider "aws" {
  region = "us-weast-2"  # Region where you wanted to deploy
}


## Terraform requires unique naming for every cluster. 
## Generate a random string suffix for unique naming of resources
resource "random_string" "suffix" {
  length  = 8            # Length of the random string 
  special = false        # Exclude special characters
}


# Using an existing VPC by its ID
data "aws_vpc" "existing_vpc" {
  id = "vpc-abcdef0789" 
}


# Fetching existing subnets
data "aws_subnet" "public_subnets" {
  count = 2                    # Number of public subnets
  id    = element(["subnet-09ab12cd", "subnet-12ab09cd"], count.index) 
}
data "aws_subnet" "private_subnets" {
  count = 2                    # Number of private subnets
  id    = element(["subnet-34ef87gh", "subnet-78ef43gh"], count.index)
}


# Use an existing security group by its ID
variable "existing_security_group_id" {
  description = "The ID of an existing security group to use for the EKS cluster"
  type        = string
}

# Create the EKS (Elastic Kubernetes Service) Cluster
resource "aws_eks_cluster" "eks" {
    name     = "eks-cluster-${random_string.suffix.result}"  # Name of the EKS cluster
    role_arn = "arn:aws:iam::123456789012:role/eksClusterRole"  # USing existing IAM role
  
    # Configure the VPC settings for the EKS cluster
    vpc_config { 
      subnet_ids         = module.vpc.private_subnets  # Use private subnets for the EKS cluster
      security_group_ids = [var.existing_security_group_id]  # Referencing the existing security group
    }

    # Tags are used for resource identification
    tags = {
      Name = "eks-cluster"  # Name of the EKS cluster
    }
  }
 

# We only create worker nodes. In EKS Master nodes are managed by Amazon, and not created or managed manually by users 
# Create a Node Group (Worker Nodes) for the EKS Cluster
resource "aws_eks_node_group" "node_group" {
    cluster_name    = aws_eks_cluster.eks.name  # Associate with the created EKS cluster
    node_group_name = "eks-nodes-${random_string.suffix.result}"  # Name of the node group
    node_role_arn   = "arn:aws:iam::123456789012:role/eksNodeRole"  # Existing IAM role that you want to assign
    subnet_ids      = module.vpc.private_subnets  # Use private subnets for worker nodes
  
    # Configure the scaling for the node group
    scaling_config {  
      desired_size = 2  # Desired number of worker nodes
      max_size     = 4  
      min_size     = 1  
      # Min and Max sizes of the nodes are written for the purpose of Auto-scaling
    }
  
    tags = {  # Tags are used for resource identification
      Name = "eks-node-group"  # Name of the node group
    }
  }
  
  # Output the EKS Cluster Endpoint for access
  output "eks_cluster_endpoint" {
    value = aws_eks_cluster.eks.endpoint  # EKS cluster endpoint (URL)
  }
  
  # Output the EKS Cluster Name
  output "eks_cluster_name" {
    value = aws_eks_cluster.eks.name  # EKS cluster name
  }