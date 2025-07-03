output "karpenter_node_role_arn" {
  description = "ARN of the Karpenter node role"
  value       = aws_iam_role.karpenter_node_role.arn
}

output "karpenter_controller_role_arn" {
  description = "ARN of the Karpenter controller role"
  value       = aws_iam_role.karpenter_controller_role.arn
}

output "karpenter_node_instance_profile_name" {
  description = "Name of the Karpenter node instance profile"
  value       = aws_iam_instance_profile.karpenter_node_instance_profile.name
}

output "karpenter_interruption_queue_arn" {
  description = "ARN of the Karpenter interruption queue"
  value       = aws_sqs_queue.karpenter_interruption_queue.arn
}

output "karpenter_interruption_queue_url" {
  description = "URL of the Karpenter interruption queue"
  value       = aws_sqs_queue.karpenter_interruption_queue.url
} 