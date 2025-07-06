variable "node_group_role_arn" {
  description = "ARN of the EKS node group IAM role"
  type        = string
}

variable "karpenter_node_role_arn" {
  description = "ARN of the karpenter IAM role"
  type        = string
}