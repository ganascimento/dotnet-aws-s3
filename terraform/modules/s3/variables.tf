variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "force_destroy" {
  description = "Allows you to destroy the bucket even if there are objects inside"
  type        = bool
  default     = false
}
