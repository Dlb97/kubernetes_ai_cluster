# VPC Configuration
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
availability_zones  = ["us-east-1a", "us-east-1b"]
project_name        = "eks-ai-cluster"

# EKS Cluster Configuration
cluster_name       = "eks-ai-cluster"
kubernetes_version = "1.32"

# EKS Node Group Configuration
node_group_desired_size   = 3
node_group_max_size       = 5
node_group_min_size       = 0
node_group_instance_types = ["m5.large"]

# Common tags for all resources
common_tags = {
  Environment = "main"
  Terraform   = "true"
  Project     = "eks-ai-cluster"
  Owner       = "terraform"
}

# GPU Cluster config. More info on instance types at (https://docs.aws.amazon.com/dlami/latest/devguide/gpu.html)
gpu_clusters = [
  {
    instance_type    = "p4de.24xlarge"
    replicas         = 1
    gpus_per_replica = 8
  },
  {
    instance_type    = "g6e.12xlarge"
    replicas         = 0
    gpus_per_replica = 4
  },
]