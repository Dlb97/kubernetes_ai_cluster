# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = true
    endpoint_private_access = false
    public_access_cidrs     = ["0.0.0.0/0"]
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
  ]


  tags = merge(
    var.common_tags,
    {
      Name = var.cluster_name
    }
  )
}

# OpenID Connect Provider for EKS
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(
    var.common_tags,
    {
      Name = "${var.cluster_name}-oidc-provider"
    }
  )
}

# EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

# EKS Cluster Policy Attachment
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# EKS VPC Resource Controller Policy Attachment
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

# EKS Node Group IAM Role
resource "aws_iam_role" "eks_node_group" {
  name = "${var.cluster_name}-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

# EKS Node Group Policy Attachments
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group.name
}

# Security Group for EKS Nodes
resource "aws_security_group" "eks_nodes" {
  name_prefix = "${var.cluster_name}-nodes-"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name                     = "${var.cluster_name}-nodes-sg"
      "karpenter.sh/discovery" = var.cluster_name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group Rule for EKS Nodes - Allow all traffic within the security group
resource "aws_security_group_rule" "eks_nodes_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.eks_nodes.id
}

# Security Group Rule for EKS Nodes - Allow traffic from EKS cluster
resource "aws_security_group_rule" "eks_nodes_from_cluster" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.eks_cluster.id
  security_group_id        = aws_security_group.eks_nodes.id
}

# Security Group for EKS Cluster
resource "aws_security_group" "eks_cluster" {
  name_prefix = "${var.cluster_name}-cluster-"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(
    var.common_tags,
    {
      Name                     = "${var.cluster_name}-cluster-sg"
      "karpenter.sh/discovery" = var.cluster_name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group Rule for EKS Cluster - Allow traffic from nodes
resource "aws_security_group_rule" "eks_cluster_from_nodes" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.eks_nodes.id
  security_group_id        = aws_security_group.eks_cluster.id
}

# Launch Template for EKS Node Group
resource "aws_launch_template" "eks_nodes" {
  name_prefix   = "${var.cluster_name}-nodes-"
  image_id      = data.aws_ami.eks_optimized.id
  instance_type = var.node_group_instance_types[0]

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.eks_nodes.id]
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    cluster_name           = var.cluster_name
    cluster_endpoint       = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = aws_eks_cluster.main.certificate_authority[0].data
    vpc_cidr               = var.vpc_cidr
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.common_tags,
      {
        Name = "${var.cluster_name}-node"
      }
    )
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.cluster_name}-launch-template"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}


# Data source for EKS optimized AMI
data "aws_ami" "eks_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-al2023-x86_64-standard-${var.kubernetes_version}-v20250419"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EKS Managed Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = var.subnet_ids

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  # Update configuration
  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_read_only,
  ]

  labels = {
    "ray_type" = "head"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.cluster_name}-node-group"
    }
  )
}


