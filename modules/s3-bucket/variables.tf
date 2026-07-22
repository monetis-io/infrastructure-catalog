variable "name" {
  description = "S3 bucket name"
  type        = string
  nullable    = false

  validation {
    condition     = length(var.name) > 0
    error_message = "Invalid S3 bucket name"
  }
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  nullable    = true
}

