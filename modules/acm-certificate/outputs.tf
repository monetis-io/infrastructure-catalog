output "arn" {
  description = "The ARN of the certificate"
  value       = module.acm_certificate.acm_certificate_arn
}
