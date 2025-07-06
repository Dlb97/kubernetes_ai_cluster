output "kuberay_iam_role_arn" {
  description = "ARN of the KubeRay IAM role"
  value       = aws_iam_role.kuberay_iam_role.arn
}

output "kuberay_iam_role_name" {
  description = "Name of the KubeRay IAM role"
  value       = aws_iam_role.kuberay_iam_role.name
} 