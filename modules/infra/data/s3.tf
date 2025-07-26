# Local variable for bucket configurations
locals {
  s3_buckets = {
    experiment_results = "${var.project_name}-experiment-results-bucket-${data.aws_caller_identity.current.account_id}"
  }
}

# S3 Buckets
resource "aws_s3_bucket" "buckets" {
  for_each = local.s3_buckets

  bucket        = each.value
  force_destroy = true

  tags = merge(
    var.common_tags,
    {
      Name = each.value
    }
  )
}

# S3 Bucket Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "buckets" {
  for_each = aws_s3_bucket.buckets

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "buckets" {
  for_each = aws_s3_bucket.buckets

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
