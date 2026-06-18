{{ template "parts/header.rsc.t" "Tayga NAT64" }}
{{- /* vim:set ft=routeros: */}}
# Update the Tayga NAT64 configuration for this host

{{ template "parts/containers.rsc.t" }}
{{ template "parts/tayga.rsc.t" }}
{{ template "parts/footer.rsc.t" }}
