
# Karpenter Node Role
resource "aws_iam_role" "karpenter_node_role" {
  name = "KarpenterNodeRole-${var.cluster_name}"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach managed policies to Karpenter Node Role
resource "aws_iam_role_policy_attachment" "karpenter_node_role_cni_policy" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_role_worker_policy" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_role_ecr_policy" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_role_ssm_policy" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Karpenter Controller Policy
resource "aws_iam_policy" "karpenter_controller_policy" {
  name = "KarpenterControllerPolicy-${var.cluster_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowScopedEC2InstanceAccessActions"
        Effect = "Allow"
        Resource = [
          "arn:aws:ec2:${data.aws_region.current.id}::image/*",
          "arn:aws:ec2:${data.aws_region.current.id}::snapshot/*",
          "arn:aws:ec2:${data.aws_region.current.id}:*:security-group/*",
          "arn:aws:ec2:${data.aws_region.current.id}:*:subnet/*",
          "arn:aws:ec2:${data.aws_region.current.id}:*:capacity-reservation/*"
        ]
        Action = [
          "ec2:RunInstances",
          "ec2:CreateFleet"
        ]
      },
      {
        Sid      = "AllowScopedEC2LaunchTemplateAccessActions"
        Effect   = "Allow"
        Resource = "arn:aws:ec2:${data.aws_region.current.id}:*:launch-template/*"
        Action = [
          "ec2:RunInstances",
          "ec2:CreateFleet"
        ]
      },
      {
        Sid    = "AllowScopedEC2InstanceActionsWithTags"
        Effect = "Allow"
        Resource = [
          "arn:aws:ec2:${data.aws_region.current.id}:*:fleet/*",
          "arn:aws:ec2:${data.aws_region.current.id}:*:instance/*",
          "arn:aws:ec2:${data.aws_region.current.id}:*:volume/*",
          "arn:aws:ec2:${data.aws_region.current.id}:*:network-interface/*",
          "arn:aws:ec2:${data.aws_region.current.id}:*:launch-template/*",
          "arn:aws:ec2:${data.aws_region.current.id}:*:spot-instances-request/*",
          "arn:aws:ec2:${data.aws_region.current.id}:*:capacity-reservation/*"
        ]
        Action = [
          "ec2:RunInstances",
          "ec2:CreateFleet",
          "ec2:CreateLaunchTemplate"
        ]
      },
      {
        Sid    = "AllowScopedResourceCreationTagging"
        Effect = "Allow"
        Resource = [
          "arn:aws:ec2:${data.aws_region.current.id}:*:fleet/*",
          "arn:aws:ec2:${data.aws_region.current.id}:*:instance/*",
          "arn:aws:ec2:${data.aws_region.current.id}:*:volume/*",
          "arn:aws:ec2:${data.aws_region.current.id}:*:network-interface/*",
          "arn:aws:ec2:${data.aws_region.current.id}:*:launch-template/*",
          "arn:aws:ec2:${data.aws_region.current.id}:*:spot-instances-request/*"
        ]
        Action = "ec2:CreateTags"
      },
      {
        Sid      = "AllowScopedResourceTagging"
        Effect   = "Allow"
        Resource = "arn:aws:ec2:${data.aws_region.current.id}:*:instance/*"
        Action   = "ec2:CreateTags"
      },
      {
        Sid    = "AllowScopedDeletion"
        Effect = "Allow"
        Resource = [
          "arn:aws:ec2:${data.aws_region.current.id}:*:instance/*",
          "arn:aws:ec2:${data.aws_region.current.id}:*:launch-template/*"
        ]
        Action = [
          "ec2:TerminateInstances",
          "ec2:DeleteLaunchTemplate"
        ]
      },
      {
        Sid      = "AllowRegionalReadActions"
        Effect   = "Allow"
        Resource = "*"
        Action = [
          "ec2:DescribeCapacityReservations",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeSubnets"
        ]
      },
      {
        Sid      = "AllowSSMReadActions"
        Effect   = "Allow"
        Resource = "arn:aws:ssm:${data.aws_region.current.id}::parameter/aws/service/*"
        Action   = "ssm:GetParameter"
      },
      {
        Sid      = "AllowPricingReadActions"
        Effect   = "Allow"
        Resource = "*"
        Action   = "pricing:GetProducts"
      },
      {
        Sid      = "AllowInterruptionQueueActions"
        Effect   = "Allow"
        Resource = aws_sqs_queue.karpenter_interruption_queue.arn
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage"
        ]
      },
      {
        Sid      = "AllowPassingInstanceRole"
        Effect   = "Allow"
        Resource = aws_iam_role.karpenter_node_role.arn
        Action   = "iam:PassRole"
      },
      {
        Sid      = "AllowPassingInstanceRoleToInstanceProfile"
        Effect   = "Allow"
        Resource = aws_iam_role.karpenter_node_role.arn
        Action   = "iam:PassRole"
      },
      {
        Sid      = "AllowScopedInstanceProfileCreationActions"
        Effect   = "Allow"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*"
        Action = [
          "iam:CreateInstanceProfile"
        ]
      },
      {
        Sid      = "AllowScopedInstanceProfileTagActions"
        Effect   = "Allow"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*"
        Action = [
          "iam:TagInstanceProfile"
        ]
      },
      {
        Sid      = "AllowScopedInstanceProfileActions"
        Effect   = "Allow"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*"
        Action = [
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile"
        ]
      },
      {
        Sid      = "AllowInstanceProfileActionsForCreation"
        Effect   = "Allow"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*"
        Action = [
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile"
        ]
      },
      {
        Sid      = "AllowInstanceProfileReadActions"
        Effect   = "Allow"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*"
        Action   = "iam:GetInstanceProfile"
      },
      {
        Sid      = "AllowAPIServerEndpointDiscovery"
        Effect   = "Allow"
        Resource = "arn:aws:eks:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"
        Action   = "eks:DescribeCluster"
      }
    ]
  })
}

# Karpenter Interruption Queue
resource "aws_sqs_queue" "karpenter_interruption_queue" {
  name                      = var.cluster_name
  message_retention_seconds = 300
  sqs_managed_sse_enabled   = true
}

# Karpenter Interruption Queue Policy
resource "aws_sqs_queue_policy" "karpenter_interruption_queue_policy" {
  queue_url = aws_sqs_queue.karpenter_interruption_queue.id

  policy = jsonencode({
    Id      = "EC2InterruptionPolicy"
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "events.amazonaws.com",
            "sqs.amazonaws.com"
          ]
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.karpenter_interruption_queue.arn
      },
      {
        Sid      = "DenyHTTP"
        Effect   = "Deny"
        Action   = "sqs:*"
        Resource = aws_sqs_queue.karpenter_interruption_queue.arn
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
        Principal = "*"
      }
    ]
  })
}

# EventBridge Rules for Interruptions
resource "aws_cloudwatch_event_rule" "scheduled_change_rule" {
  name = "karpenter-scheduled-change-${var.cluster_name}"

  event_pattern = jsonencode({
    source      = ["aws.health"]
    detail-type = ["AWS Health Event"]
  })
}

resource "aws_cloudwatch_event_target" "scheduled_change_target" {
  rule      = aws_cloudwatch_event_rule.scheduled_change_rule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue.arn
}

resource "aws_cloudwatch_event_rule" "spot_interruption_rule" {
  name = "karpenter-spot-interruption-${var.cluster_name}"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })
}

resource "aws_cloudwatch_event_target" "spot_interruption_target" {
  rule      = aws_cloudwatch_event_rule.spot_interruption_rule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue.arn
}

resource "aws_cloudwatch_event_rule" "rebalance_rule" {
  name = "karpenter-rebalance-${var.cluster_name}"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance Rebalance Recommendation"]
  })
}

resource "aws_cloudwatch_event_target" "rebalance_target" {
  rule      = aws_cloudwatch_event_rule.rebalance_rule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue.arn
}

resource "aws_cloudwatch_event_rule" "instance_state_change_rule" {
  name = "karpenter-instance-state-change-${var.cluster_name}"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
  })
}

resource "aws_cloudwatch_event_target" "instance_state_change_target" {
  rule      = aws_cloudwatch_event_rule.instance_state_change_rule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue.arn
}

# Karpenter Controller Role
resource "aws_iam_role" "karpenter_controller_role" {
  name = "KarpenterControllerRole-${var.cluster_name}"

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
            "${replace(var.cluster_oidc_provider_arn, "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/", "")}:sub" = "system:serviceaccount:kube-system:karpenter"
          }
        }
      }
    ]
  })
}

# Attach Karpenter Controller Policy to Controller Role
resource "aws_iam_role_policy_attachment" "karpenter_controller_policy_attachment" {
  role       = aws_iam_role.karpenter_controller_role.name
  policy_arn = aws_iam_policy.karpenter_controller_policy.arn
}

# Karpenter Node Instance Profile
resource "aws_iam_instance_profile" "karpenter_node_instance_profile" {
  name = "KarpenterNodeInstanceProfile-${var.cluster_name}"
  role = aws_iam_role.karpenter_controller_role.id
}

# Install Karpenter Helm Chart
resource "null_resource" "install_karpenter" {
  triggers = {
    cluster_name        = var.cluster_name
    karpenter_version   = var.karpenter_version
    karpenter_namespace = var.karpenter_namespace
    karpenter_node_role = aws_iam_role.karpenter_controller_role.arn
  }

  provisioner "local-exec" {
    command = <<-EOT
      chmod +x ${path.module}/install_helm_chart.sh
      export KARPENTER_VERSION="${var.karpenter_version}"
      export KARPENTER_NAMESPACE="${var.karpenter_namespace}"
      export CLUSTER_NAME="${var.cluster_name}"
      export KARPENTER_IAM_ROLE_ARN="${aws_iam_role.karpenter_controller_role.arn}"
      ${path.module}/install_helm_chart.sh
    EOT
  }

  depends_on = [
    aws_iam_role.karpenter_controller_role,
    aws_iam_role_policy_attachment.karpenter_controller_policy_attachment,
    aws_sqs_queue.karpenter_interruption_queue,
    aws_sqs_queue_policy.karpenter_interruption_queue_policy,
    aws_cloudwatch_event_rule.scheduled_change_rule,
    aws_cloudwatch_event_rule.spot_interruption_rule,
    aws_cloudwatch_event_rule.rebalance_rule,
    aws_cloudwatch_event_rule.instance_state_change_rule
  ]
}

resource "kubectl_manifest" "cpu_class" {
  yaml_body = templatefile(
    "${path.module}/nodepools/cpu_class.yaml",
    {
      CLUSTER_NAME = var.cluster_name
    }
  )

  depends_on = [null_resource.install_karpenter]
}

resource "kubectl_manifest" "cpu_node_pool" {
  yaml_body = templatefile(
    "${path.module}/nodepools/cpu_pool.yaml", {}
  )

  depends_on = [null_resource.install_karpenter]
}


resource "kubectl_manifest" "gpu_class" {
  yaml_body = templatefile(
    "${path.module}/nodepools/gpu_class.yaml",
    {
      CLUSTER_NAME = var.cluster_name
    }
  )

  depends_on = [null_resource.install_karpenter]
}



resource "kubectl_manifest" "gpu_node_pool" {
  yaml_body = templatefile(
    "${path.module}/nodepools/gpu_pool.yaml",
    {}
  )

  depends_on = [null_resource.install_karpenter]
}