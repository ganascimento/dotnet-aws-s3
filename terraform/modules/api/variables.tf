variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI for EC2 instance"
  type        = string
}

variable "bucket_arn" {
  description = "S3 bucket ARN to access"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name to access"
  type        = string
}
