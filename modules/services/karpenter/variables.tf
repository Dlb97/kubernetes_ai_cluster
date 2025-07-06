variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_oidc_provider_arn" {
  description = "EKS cluster OIDC provider ARN"
  type        = string
}

variable "karpenter_version" {
  description = "Karpenter version to install"
  type        = string
  default     = "1.4.0"
}

variable "karpenter_namespace" {
  description = "Kubernetes namespace for Karpenter"
  type        = string
  default     = "kube-system"
}

variable "gpu_clusters" {
  type = list(object({
    instance_type    = string
    replicas         = number
    gpus_per_replica = number
  }))
}

variable "cluster_endpoint" {
  description = "EKS cluster API server endpoint"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "EKS cluster CA certificate"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}