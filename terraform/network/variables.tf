variable "project" {
  description = "Project name for resource tagging"
  type        = string
}

variable "env" {
  description = "Environment name for resource tagging"
  type        = string
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "az_count" {
  description = "Number of availability zones to use for subnets"
  type        = number
  default     = 2
}