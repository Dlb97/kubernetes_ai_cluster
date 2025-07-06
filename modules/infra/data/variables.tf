variable "project_name" {
  description = "Name of the project for resource tagging"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "IDs of the subnets for EFS mount targets"
  type        = list(string)
} 