##################
### VPC MODULE ###
##################

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones for the subnets"
  type        = list(string)
}

variable "project_name" {
  description = "Name of the project for resource tagging"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

##################
### EKS MODULE ###
##################

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.32"
}

variable "node_group_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_group_instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
  default     = ["m5.large"]
}

#####################################
### Karpenter and Kuberay modules ###
#####################################

variable "gpu_clusters" {

  type = list(object({
    instance_type    = string
    replicas         = number
    gpus_per_replica = number
  }))
}