resource "helm_release" "kuberay_operator" {
  name             = "kuberay-operator"
  repository       = "https://ray-project.github.io/kuberay-helm/"
  chart            = "kuberay-operator"
  version          = "1.3.2"
  create_namespace = true
  namespace        = "kuberay-operator"
}


# KubeRay IAM Role
resource "aws_iam_role" "kuberay_iam_role" {
  name = "${var.project_name}-ray-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.cluster_oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.cluster_oidc_provider_arn, "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/", "")}:sub" = "system:serviceaccount:default:${var.project_name}"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ray-cluster-role"
  }
}

# IAM Policy for S3 Access
resource "aws_iam_role_policy" "kuberay_s3_policy" {
  name = "${var.project_name}-ray-s3-policy"
  role = aws_iam_role.kuberay_iam_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = concat(
          [for bucket_arn in values(var.s3_bucket_arns) : bucket_arn],
          [for bucket_arn in values(var.s3_bucket_arns) : "${bucket_arn}/*"]
        )
      }
    ]
  })
}


#Provides access to the S3 buckets
resource "kubectl_manifest" "service_account" {
  yaml_body = templatefile(
    "${path.module}/templates/service_account.yaml",
    {
      ROLE_NAME      = aws_iam_role.kuberay_iam_role.name,
      AWS_ACCOUNT_ID = data.aws_caller_identity.current.account_id,
      PROJECT_NAME   = var.project_name
    }
  )
}

resource "kubectl_manifest" "ray_cluster" {
  for_each = { for idx, cluster in var.gpu_clusters : cluster.instance_type => cluster }

  yaml_body = templatefile(
    "${path.module}/templates/ray_cluster.yaml",
    {
      CLUSTER_NAME   = "${var.project_name}-${replace(each.key, ".", "-")}",
      PROJECT_NAME   = var.project_name,
      FILE_SYSTEM_ID = var.efs_file_system_id,
      REPLICAS       = each.value.replicas,
      GPUs           = each.value.gpus_per_replica,
      INSTANCE_TYPE  = each.key
    }
  )

  depends_on = [
    helm_release.kuberay_operator,
    kubectl_manifest.ray_pv,
    kubectl_manifest.ray_pvc,
    kubectl_manifest.efs_storage_class
  ]
}

# Persistent Volume
resource "kubectl_manifest" "ray_pv" {
  yaml_body = templatefile(
    "${path.module}/templates/persistent_volume.yaml",
    {
      PROJECT_NAME   = var.project_name,
      FILE_SYSTEM_ID = var.efs_file_system_id
    }
  )
}

# Persistent Volume Claim
resource "kubectl_manifest" "ray_pvc" {
  yaml_body = templatefile(
    "${path.module}/templates/persistent_volume_claim.yaml",
    {
      PROJECT_NAME = var.project_name
    }
  )

  depends_on = [kubectl_manifest.ray_pv]
}

# Storage Class
resource "kubectl_manifest" "efs_storage_class" {
  yaml_body = templatefile(
    "${path.module}/templates/storage_class.yaml",
    {
      FILE_SYSTEM_ID = var.efs_file_system_id
    }
  )
}