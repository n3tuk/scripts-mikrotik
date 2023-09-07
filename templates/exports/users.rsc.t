{{ template "parts/header.rsc.t" "Users" }}
{{- /* vim:set ft=routeros: */ -}}

# Provide the configuration for the set up of Users and their SSH Public Keys

{{ template "parts/users.rsc.t" }}

{{ template "parts/footer.rsc.t" }}
