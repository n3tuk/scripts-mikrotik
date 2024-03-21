{{ template "parts/header.rsc.t" "Network" }}
{{- /* vim:set ft=routeros: */}}

{{  template "parts/interfaces.rsc.t" }}
{{- if (and (eq (ds "host").type "ap")
            (not (eq (ds "host").export "netinstall"))) }}
{{    template "parts/wireless.rsc.t" }}
{{- end }}
{{  template "parts/bridge.rsc.t" }}
{{  template "parts/vlans.rsc.t" }}
{{  template "parts/footer.rsc.t" }}
