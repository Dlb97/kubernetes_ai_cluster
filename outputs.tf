# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

# EKS Outputs
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

# Data Module Outputs
output "s3_bucket_names" {
  description = "Names of all S3 buckets"
  value       = module.data.s3_bucket_names
}

output "s3_bucket_arns" {
  description = "ARNs of all S3 buckets"
  value       = module.data.s3_bucket_arns
}

output "experiment_results_bucket_name" {
  description = "Name of the experiment results S3 bucket"
  value       = module.data.experiment_results_bucket_name
}

output "experiment_results_bucket_arn" {
  description = "ARN of the experiment results S3 bucket"
  value       = module.data.experiment_results_bucket_arn
}

output "efs_file_system_id" {
  description = "ID of the EFS file system"
  value       = module.data.efs_file_system_id
}

output "efs_file_system_arn" {
  description = "ARN of the EFS file system"
  value       = module.data.efs_file_system_arn
}

output "efs_mount_target_ids" {
  description = "IDs of the EFS mount targets"
  value       = module.data.efs_mount_target_ids
}

output "datasync_task_arn" {
  description = "ARN of the DataSync task"
  value       = module.data.datasync_task_arn
}

output "datasync_task_id" {
  description = "ID of the DataSync task"
  value       = module.data.datasync_task_id
}

# KubeRay Outputs
output "kuberay_iam_role_arn" {
  description = "ARN of the KubeRay IAM role"
  value       = module.ray.kuberay_iam_role_arn
}

output "kuberay_iam_role_name" {
  description = "Name of the KubeRay IAM role"
  value       = module.ray.kuberay_iam_role_name
} 