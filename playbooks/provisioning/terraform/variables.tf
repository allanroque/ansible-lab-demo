# ==========================================================================
# Instance variables
# ==========================================================================
variable "aws_name_tag" {
  description = "Name tag for the EC2 instance"
  type        = string
}

variable "aws_instance_size" {
  description = "EC2 instance type (e.g. t2.micro, t3.medium)"
  type        = string
  default     = "t2.micro"
}

variable "aws_instance_count" {
  description = "Number of instances to provision"
  type        = number
  default     = 1
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-2"
}

variable "aws_server_role" {
  description = "Server role tag (e.g. webserver, database)"
  type        = string
}

variable "aws_server_group" {
  description = "Server group tag for inventory grouping"
  type        = string
}

variable "aws_instance_public_key" {
  description = "SSH public key for instance access"
  type        = string
}
