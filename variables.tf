provider "aws" {
  region = var.region
}

# CIDR Range
variable "vpc_cidr" {
  default = "10.0"
}

variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "organization_name" {
  description = "Organization name"
  type        = string
  default     = "kasha"
}

variable "max_capacity" {
  description = "Maximum capacity"
  type        = number
  default     = 4
}

variable "min_capacity" {
  description = "Minimum capacity"
  type        = number
  default     = 2
}