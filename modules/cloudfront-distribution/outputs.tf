output "arn" {
  description = "The ARN of the Cloudfront distribution"
  value       = module.cloudfront_distribution.cloudfront_distribution_arn
}

output "domain_name" {
  description = "Domain name of the Cloudfront distribution"
  value       = module.cloudfront_distribution.cloudfront_distribution_domain_name
}
