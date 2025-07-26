# CloudWatch Log Group for DataSync
resource "aws_cloudwatch_log_group" "datasync_logs" {
  name              = "/aws/datasync/${var.project_name}-task"
  retention_in_days = 7

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-datasync-log-group"
    }
  )
}

# IAM Role for DataSync
resource "aws_iam_role" "datasync_role" {
  name = "${var.project_name}-datasync-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "datasync.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-datasync-role"
    }
  )
}

# IAM Policy for DataSync S3 Access
resource "aws_iam_role_policy" "datasync_s3_policy" {
  name = "${var.project_name}-datasync-s3-policy"
  role = aws_iam_role.datasync_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:ListMultipartUploadParts",
          "s3:PutObject",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging"
        ]
        Resource = [
          aws_s3_bucket.buckets["experiment_results"].arn,
          "${aws_s3_bucket.buckets["experiment_results"].arn}/*"
        ]
      }
    ]
  })
}

# IAM Policy for DataSync EFS Access
resource "aws_iam_role_policy" "datasync_efs_policy" {
  name = "${var.project_name}-datasync-efs-policy"
  role = aws_iam_role.datasync_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:DescribeAccessPoints",
          "elasticfilesystem:DescribeMountTargets",
          "elasticfilesystem:CreateAccessPoint",
          "elasticfilesystem:DeleteAccessPoint"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite"
        ]
        Resource = aws_efs_file_system.datasync_efs.arn
      }
    ]
  })
}

# IAM Policy for CloudWatch Logs
resource "aws_iam_role_policy" "datasync_cloudwatch_policy" {
  name = "${var.project_name}-datasync-cloudwatch-policy"
  role = aws_iam_role.datasync_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.datasync_logs.arn}:*"
      }
    ]
  })
}

# DataSync S3 Location
resource "aws_datasync_location_s3" "datasync_s3_location" {
  s3_bucket_arn = aws_s3_bucket.buckets["experiment_results"].arn
  subdirectory  = "/"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_role.arn
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-datasync-s3-location"
    }
  )
}

# DataSync EFS Location
resource "aws_datasync_location_efs" "datasync_efs_location" {
  efs_file_system_arn = aws_efs_file_system.datasync_efs.arn
  subdirectory        = "/"

  ec2_config {
    security_group_arns = [aws_security_group.efs.arn]
    subnet_arn          = "arn:aws:ec2:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:subnet/${aws_efs_mount_target.datasync_efs[0].subnet_id}"
  }

  depends_on = [aws_efs_mount_target.datasync_efs]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-datasync-efs-location"
    }
  )
}

# DataSync Task
resource "aws_datasync_task" "s3_to_efs" {
  name                     = "${var.project_name}-s3-to-efs-task"
  source_location_arn      = aws_datasync_location_s3.datasync_s3_location.arn
  destination_location_arn = aws_datasync_location_efs.datasync_efs_location.arn

  options {
    preserve_deleted_files = "REMOVE"
    verify_mode            = "ONLY_FILES_TRANSFERRED"
    task_queueing          = "ENABLED"
    log_level              = "TRANSFER"
  }

  cloudwatch_log_group_arn = aws_cloudwatch_log_group.datasync_logs.arn

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-s3-to-efs-task"
    }
  )
}