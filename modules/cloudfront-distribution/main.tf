locals {
  allowed_methods = {
    S3 = [
      "GET",
      "HEAD",
      "OPTIONS",
    ]
    API_GATEWAY = [
      "GET",
      "HEAD",
      "OPTIONS",
      "PUT",
      "POST",
      "PATCH",
      "DELETE",
    ]
  }

  cache_policies = {
    "Amplify"                                   = "2e54312d-136d-493c-8eb9-b001f22f67d2"
    "CachingDisabled"                           = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    "CachingOptimized"                          = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    "CachingOptimizedForUncompressedObjects"    = "b2884449-e4de-46a7-ac36-70bc7f1ddd6d"
    "Elemental-MediaPackage"                    = "08627262-05a9-4f76-9ded-b50ca2e3a84f"
    "UseOriginCacheControlHeaders"              = "83da9c7e-98b4-4e11-a168-04f0df8e2c65"
    "UseOriginCacheControlHeaders-QueryStrings" = "4cc15a8a-d715-48a4-82b8-cc0b614638fe"
  }

  origin_request_policies = {
    "AllViewer"                                   = "216adef6-5c7f-47e4-b989-5492eafa07d3"
    "AllViewerAndCloudFrontHeaders-2022-06"       = "33f36d7e-f396-46d9-90e0-52428a34d9dc"
    "AllViewerExceptHostHeader"                   = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
    "CORS-CustomOrigin"                           = "59781a5b-3903-41f3-afcb-af62929ccde1"
    "CORS-S3Origin"                               = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"
    "Elemental-MediaTailor-PersonalizedManifests" = "775133bc-15f2-49f9-abea-afb2e0bf67d2"
    "HostHeaderOnly"                              = "bf0718e1-ba1e-49d1-88b1-f726733018ae"
    "UserAgentRefererHeaders"                     = "acba4595-bd28-49b8-b9fe-13317c0390fa"
  }

  response_headers_policies = {
    "CORS-and-SecurityHeadersPolicy"                = "e61eb60c-9c35-4d20-a928-2b84e02af89c"
    "CORS-With-Preflight"                           = "5cc3b908-e619-4b99-88e5-2cf7f45965bd"
    "CORS-with-preflight-and-SecurityHeadersPolicy" = "eaab4381-ed33-4a86-88ca-d9558dc6cd63"
    "SecurityHeadersPolicy"                         = "67f7725c-6f97-4210-82d7-5512b31e9d03"
    "SimpleCORS"                                    = "60669652-455b-4ae9-85a4-c4c02393f86c"
  }
}

resource "aws_cloudfront_function" "spa_viewer_request" {
  name    = "${var.namespace}-spa-viewer-request"
  runtime = "cloudfront-js-2.0"
  code    = file("${path.module}/functions/spa-viewer-request.js")
}

module "cloudfront_distribution" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "6.7.0"

  aliases = var.aliases

  comment      = "${var.namespace}-${var.name}"
  http_version = var.http_version
  price_class  = var.price_class

  origin = merge(
    {
      for origin in var.origins.S3 : origin.id => {
        domain_name               = origin.domain_name
        origin_access_control_key = "s3"
      }
    },
    {
      for origin in var.origins.API_GATEWAY : origin.id => {
        domain_name = origin.domain_name
        custom_origin_config = {
          http_port              = 80
          https_port             = 443
          origin_protocol_policy = "https-only"
          origin_ssl_protocols = [
            "TLSv1.2",
          ]
        }
      }
    },
  )

  ordered_cache_behavior = [
    for cache_behavior in [for cache_behavior in var.cache_behaviors : cache_behavior if cache_behavior.path != null && cache_behavior.path != "*"] : {
      path_pattern = cache_behavior.path

      allowed_methods = local.allowed_methods[cache_behavior.type]

      viewer_protocol_policy = "redirect-to-https"

      cache_policy_id            = local.cache_policies[cache_behavior.cache_policy]
      origin_request_policy_id   = try(local.origin_request_policies[cache_behavior.origin_request_policy], null)
      response_headers_policy_id = try(local.response_headers_policies[cache_behavior.response_headers_policy], null)

      function_association = cache_behavior.purpose == "spa" ? {
        viewer-request = {
          function_arn = aws_cloudfront_function.spa_viewer_request.arn
        }
      } : {}

      target_origin_id = cache_behavior.target_origin_id
    }
  ]

  default_cache_behavior = one([
    for cache_behavior in [for cache_behavior in var.cache_behaviors : cache_behavior if cache_behavior.path == null || cache_behavior.path == "*"] : {
      allowed_methods = local.allowed_methods[cache_behavior.type]

      viewer_protocol_policy = "redirect-to-https"

      cache_policy_id            = local.cache_policies[cache_behavior.cache_policy]
      origin_request_policy_id   = try(local.origin_request_policies[cache_behavior.origin_request_policy], null)
      response_headers_policy_id = try(local.response_headers_policies[cache_behavior.response_headers_policy], null)

      function_association = cache_behavior.purpose == "spa" ? {
        viewer-request = {
          function_arn = aws_cloudfront_function.spa_viewer_request.arn
        }
      } : {}

      target_origin_id = cache_behavior.target_origin_id
    }
  ])

  custom_error_response = var.custom_error_response

  viewer_certificate = var.acm_certificate_arn != null ? {
    acm_certificate_arn = var.acm_certificate_arn
    ssl_support_method  = "sni-only"
    } : {
    cloudfront_default_certificate = true
  }

  tags = var.tags
}

data "aws_iam_policy_document" "policy" {
  for_each = { for origin in var.origins.S3 : origin.id => origin }

  statement {
    principals {
      type = "Service"
      identifiers = [
        "cloudfront.amazonaws.com",
      ]
    }

    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${each.value.bucket_arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values = [
        module.cloudfront_distribution.cloudfront_distribution_arn,
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "policy" {
  for_each = { for origin in var.origins.S3 : origin.id => origin }

  bucket = each.key
  policy = data.aws_iam_policy_document.policy[each.key].json
}
