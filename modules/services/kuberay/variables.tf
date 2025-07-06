variable "project_name" {
  description = "Name of the project for resource tagging"
  type        = string
}

variable "cluster_oidc_provider_arn" {
  description = "ARN of the EKS cluster OIDC provider"
  type        = string
}

variable "s3_bucket_arns" {
  description = "ARNs of the S3 buckets for Ray cluster access"
  type        = map(string)
}

variable "efs_file_system_id" {
  description = "ID of the file system"
  type        = string
}

variable "gpu_clusters" {
  description = "List of desired GPU Cluster configuration"
  type = list(object({
    instance_type    = string
    replicas         = number
    gpus_per_replica = number
  }))
}
