variable "namespace" {
  description = "Namespace for this Cloudfront distribution"
  type        = string
  nullable    = false
}

variable "name" {
  description = "Cloudfront distribution name"
  type        = string
  nullable    = false

  validation {
    condition     = length(var.name) > 0
    error_message = "Invalid name"
  }
}

variable "aliases" {
  description = "Alternative domain names for this Cloudfront distribution"
  type        = list(string)
  nullable    = false
  default     = []

  validation {
    condition     = var.acm_certificate_arn == null || length(var.aliases) > 0
    error_message = "At least one alias is required when using a custom ACM certificate"
  }
}

variable "http_version" {
  description = "The maximum HTTP version to support on this Cloudfront distribution"
  type        = string
  nullable    = false
  default     = "http2and3"

  validation {
    condition     = contains(["http1.1", "http2", "http2and3", "http3"], var.http_version)
    error_message = "Unrecognised HTTP version"
  }
}

variable "price_class" {
  description = "Cloudfront distribution price class"
  type        = string
  nullable    = false
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "Unrecognised price class"
  }
}

variable "origins" {
  description = "Origins for this Cloudfront distribution"
  type = object({
    S3 = optional(list(object({
      id          = string
      domain_name = string
      bucket_arn  = string
    })), [])
    API_GATEWAY = optional(list(object({
      id          = string
      domain_name = string
    })), [])
  })
  nullable = false
  default  = {}
}

variable "cache_behaviors" {
  description = "An ordered list of cache behaviors for this Cloudfront distribution"
  type = list(object({
    path                    = optional(string)
    type                    = string
    target_origin_id        = string
    cache_policy            = string
    origin_request_policy   = optional(string)
    response_headers_policy = optional(string)
    purpose                 = optional(string)
  }))
  nullable = false
  default  = []

  validation {
    condition     = length([for cache_behavior in var.cache_behaviors : cache_behavior if cache_behavior.path == null || cache_behavior.path == "*"]) == 1
    error_message = "Exactly one cache behavior must be the default one"
  }

  validation {
    condition     = alltrue([for cache_behavior in var.cache_behaviors : contains(["API_GATEWAY", "S3"], cache_behavior.type)])
    error_message = "Cache behavior type must be one of: API_GATEWAY, S3"
  }

  validation {
    condition = alltrue([
      for cache_behavior in var.cache_behaviors : contains([
        "Amplify",
        "CachingDisabled",
        "CachingOptimized",
        "CachingOptimizedForUncompressedObjects",
        "Elemental-MediaPackage",
        "UseOriginCacheControlHeaders",
        "UseOriginCacheControlHeaders-QueryStrings",
      ], cache_behavior.cache_policy)
    ])
    error_message = "Unrecognised AWS managed cache policy"
  }

  validation {
    condition = alltrue([
      for cache_behavior in var.cache_behaviors : cache_behavior.origin_request_policy == null || contains([
        "AllViewer",
        "AllViewerAndCloudFrontHeaders-2022-06",
        "AllViewerExceptHostHeader",
        "CORS-CustomOrigin",
        "CORS-S3Origin",
        "Elemental-MediaTailor-PersonalizedManifests",
        "HostHeaderOnly",
        "UserAgentRefererHeaders",
      ], cache_behavior.origin_request_policy)
    ])
    error_message = "Unrecognised AWS managed origin request policy"
  }

  validation {
    condition = alltrue([
      for cache_behavior in var.cache_behaviors : cache_behavior.response_headers_policy == null || contains([
        "CORS-and-SecurityHeadersPolicy",
        "CORS-With-Preflight",
        "CORS-with-preflight-and-SecurityHeadersPolicy",
        "SecurityHeadersPolicy",
        "SimpleCORS",
      ], cache_behavior.response_headers_policy)
    ])
    error_message = "Unrecognised AWS managed response headers policy"
  }

  validation {
    condition     = alltrue([for cache_behavior in var.cache_behaviors : (cache_behavior.type == "S3") == (cache_behavior.purpose != null)])
    error_message = "S3 cache behaviors must declare a purpose"
  }

  validation {
    condition     = alltrue([for cache_behavior in var.cache_behaviors : cache_behavior.purpose == null || contains(["spa", "static-assets"], cache_behavior.purpose)])
    error_message = "Unrecognised S3 cache behavior purpose"
  }
}

variable "custom_error_response" {
  description = "Custom error response configuration"
  type = list(object({
    error_code            = number
    error_caching_min_ttl = optional(number)
    response_code         = optional(number)
    response_page_path    = optional(string)
  }))
  nullable = true
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for this Cloudfront distribution"
  type        = string
  nullable    = true
  default     = null

  validation {
    condition     = length(var.aliases) == 0 || var.acm_certificate_arn != null
    error_message = "Missing ACM certificate for the provided aliases"
  }
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  nullable    = true
}
