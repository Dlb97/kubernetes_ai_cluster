# EFS File System
resource "aws_efs_file_system" "datasync_efs" {
  creation_token = "${var.project_name}-datasync-efs"
  encrypted      = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-datasync-efs"
    }
  )
}

# EFS Mount Targets
resource "aws_efs_mount_target" "datasync_efs" {
  count           = length(var.subnet_ids)
  file_system_id  = aws_efs_file_system.datasync_efs.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

# Security Group for EFS
resource "aws_security_group" "efs" {
  name_prefix = "${var.project_name}-efs-sg"
  vpc_id      = var.vpc_id

  ingress {
    description = "NFS from VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-efs-security-group"
    }
  )
}


