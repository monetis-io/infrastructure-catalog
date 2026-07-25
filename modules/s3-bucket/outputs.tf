
output "arn" {
  description = "The ARN of the S3 bucket"
  value       = module.s3_bucket.s3_bucket_arn
}

output "id" {
  description = "The name of the S3 bucket"
  value       = module.s3_bucket.s3_bucket_id
}

output "region" {
  description = "The AWS region the S3 bucket resides in"
  value       = module.s3_bucket.s3_bucket_region
}

output "regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = module.s3_bucket.s3_bucket_bucket_regional_domain_name
}
