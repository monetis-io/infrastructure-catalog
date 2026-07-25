variable "name" {
  description = "S3 bucket name"
  type        = string
  nullable    = false

  validation {
    condition     = length(var.name) > 0
    error_message = "Invalid S3 bucket name"
  }
}

variable "website" {
  description = "Static website configuration"
  type = object({
    redirect_all_requests_to = optional(object({
      protocol  = string
      host_name = string
    }))
  })
  nullable = true
  default  = null
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  nullable    = true
}

