{{ template "parts/header.rsc.t" "Network" }}
{{- /* vim:set ft=routeros: */}}

{{ template "parts/interfaces.rsc.t" }}
{{ template "parts/bridge.rsc.t" }}
{{ template "parts/vlans.rsc.t" }}
{{ template "parts/footer.rsc.t" }}
