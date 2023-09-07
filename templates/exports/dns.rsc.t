{{ template "parts/header.rsc.t" "DNS" }}
{{- /* vim:set ft=routeros: */}}
# Update the DNS configuration for this host

{{ template "parts/dns.rsc.t" }}
{{ template "parts/footer.rsc.t" }}
