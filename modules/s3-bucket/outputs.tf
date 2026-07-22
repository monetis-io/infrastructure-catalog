
output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = module.s3_bucket.s3_bucket_arn
}

output "s3_bucket_id" {
  description = "The name of the S3 bucket"
  value       = module.s3_bucket.s3_bucket_id
}

output "s3_bucket_region" {
  description = "The AWS region the S3 bucket resides in"
  value       = module.s3_bucket.s3_bucket_region
}
