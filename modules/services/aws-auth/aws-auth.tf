# Apply the aws-auth configmap
resource "kubectl_manifest" "aws_auth" {
  yaml_body = templatefile(
    "${path.module}/templates/aws-auth.yaml",
    {
      NODE_GROUP_ROLE_ARN = var.node_group_role_arn
      KARPENTER_ROLE_ARN  = var.karpenter_node_role_arn
    }
  )
}