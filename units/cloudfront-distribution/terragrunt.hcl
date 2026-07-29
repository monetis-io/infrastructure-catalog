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

  aliases = try(values.aliases, [])

  origins = try(values.origins, {})

  cache_behaviors = try(values.cache_behaviors, [])

  custom_error_response = values.custom_error_response

  acm_certificate_arn = try(values.acm_certificate_arn, null)

  tags = merge(try(include.root.locals.tags, {}), try(values.tags, {}))
}
