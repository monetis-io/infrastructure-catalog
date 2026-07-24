include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../..//modules/acm-certificate"

  update_source_with_cas = true
}

inputs = {
  domain_name = include.root.locals.environment.domain_name

  tags = merge(try(include.root.locals.tags, {}), try(values.tags, {}))
}
