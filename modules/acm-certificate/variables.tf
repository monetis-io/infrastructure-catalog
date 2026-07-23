variable "domain_name" {
  description = "A domain name for which the certificate should be issued"
  type        = string
  nullable    = false

  validation {
    condition     = length(var.domain_name) > 0
    error_message = "Invalid domain name"
  }
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  nullable    = true
}

