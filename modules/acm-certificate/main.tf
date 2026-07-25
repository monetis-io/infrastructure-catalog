provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

data "aws_route53_zone" "this" {
  name = var.domain_name
}

module "acm_certificate" {
  source = "terraform-aws-modules/acm/aws"

  providers = {
    aws = aws.us_east_1
  }

  zone_id = data.aws_route53_zone.this.zone_id

  domain_name = var.domain_name

  subject_alternative_names = [
    "*.${var.domain_name}",
  ]

  validation_method = "DNS"

  tags = var.tags
}
