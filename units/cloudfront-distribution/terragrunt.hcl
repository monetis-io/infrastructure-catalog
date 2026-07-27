include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../..//modules/cloudfront-distribution"

  update_source_with_cas = true
}

inputs = {
  namespace = include.root.locals.namespace
  name      = values.name

  aliases = [
    values.domain_name,
    "www.${values.domain_name}",
  ]

  origins = values.origins

  cache_behaviors = values.cache_behaviors

  custom_error_response = values.custom_error_response

  acm_certificate_arn = values.acm_certificate_arn

  tags = merge(try(include.root.locals.tags, {}), try(values.tags, {}))
}
