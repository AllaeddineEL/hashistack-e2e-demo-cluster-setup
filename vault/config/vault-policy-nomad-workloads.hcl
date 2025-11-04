path "kv/data/{{identity.entity.aliases.AUTH_METHOD_ACCESSOR.metadata.nomad_namespace}}/{{identity.entity.aliases.AUTH_METHOD_ACCESSOR.metadata.nomad_job_id}}/*" {
  capabilities = ["read"]
}

path "kv/data/{{identity.entity.aliases.AUTH_METHOD_ACCESSOR.metadata.nomad_namespace}}/{{identity.entity.aliases.AUTH_METHOD_ACCESSOR.metadata.nomad_job_id}}" {
  capabilities = ["read"]
}

path "kv/metadata/{{identity.entity.aliases.AUTH_METHOD_ACCESSOR.metadata.nomad_namespace}}/*" {
  capabilities = ["list"]
}

path "kv/metadata/*" {
  capabilities = ["list"]
}
