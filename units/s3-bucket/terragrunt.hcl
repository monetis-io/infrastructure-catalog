include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../..//modules/s3-bucket"

  update_source_with_cas = true
}

inputs = {
  name = values.name

  tags = merge(try(include.root.locals.tags, {}), try(values.tags, {}))
}
