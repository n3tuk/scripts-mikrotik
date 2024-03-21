{{  template "parts/header.rsc.t" "Firewall" }}
{{- /* vim:set ft=routeros: */}}
# Update all the firewalls and address lists

{{  template "parts/firewall.rsc.t" }}
{{  template "parts/footer.rsc.t" }}
