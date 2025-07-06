output "s3_bucket_names" {
  description = "Names of the S3 buckets"
  value = {
    for k, v in aws_s3_bucket.buckets : k => v.bucket
  }
}

output "s3_bucket_arns" {
  description = "ARNs of the S3 buckets"
  value = {
    for k, v in aws_s3_bucket.buckets : k => v.arn
  }
}

output "datasync_bucket_name" {
  description = "Name of the DataSync S3 bucket"
  value       = aws_s3_bucket.buckets["datasync"].bucket
}

output "datasync_bucket_arn" {
  description = "ARN of the DataSync S3 bucket"
  value       = aws_s3_bucket.buckets["datasync"].arn
}

output "experiment_results_bucket_name" {
  description = "Name of the experiment results S3 bucket"
  value       = aws_s3_bucket.buckets["experiment_results"].bucket
}

output "experiment_results_bucket_arn" {
  description = "ARN of the experiment results S3 bucket"
  value       = aws_s3_bucket.buckets["experiment_results"].arn
}

output "efs_file_system_id" {
  description = "ID of the EFS file system"
  value       = aws_efs_file_system.datasync_efs.id
}

output "efs_file_system_arn" {
  description = "ARN of the EFS file system"
  value       = aws_efs_file_system.datasync_efs.arn
}

output "efs_mount_target_ids" {
  description = "IDs of the EFS mount targets"
  value       = aws_efs_mount_target.datasync_efs[*].id
}

output "datasync_task_arn" {
  description = "ARN of the DataSync task"
  value       = aws_datasync_task.s3_to_efs.arn
}

output "datasync_task_id" {
  description = "ID of the DataSync task"
  value       = aws_datasync_task.s3_to_efs.id
} 