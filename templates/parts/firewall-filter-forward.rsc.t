# -- templates/parts/firewall-filter-forward.rsc.t
{{- /* vim:set ft=routeros: */}}

{{  template "item" "filter/forward chain" }}

{{- if (and (ne (ds "host").export "netinstall")
            (eq (ds "host").type "router")) }}

{{    template "parts/firewall-filter-forward-routing.rsc.t" }}
{{    template "parts/firewall-filter-forward-ports.rsc.t" }}
{{    template "parts/firewall-filter-forward-services.rsc.t" }}
{{    template "parts/firewall-filter-forward-rules.rsc.t" }}
{{    template "parts/firewall-filter-forward-vlans.rsc.t" }}
{{    template "parts/firewall-filter-forward-reject.rsc.t" }}

{{- else }}

{{    template "parts/firewall-filter-forward-drop.rsc.t" }}

{{- end }}
{{  template "item" "filter/forward jump" }}

/ip firewall filter

add chain="forward" \
    action=jump jump-target="$runId:forward" \
    comment="Process all packets passing through the FORWARD chain"

/ipv6 firewall filter

add chain="forward" \
    action=jump jump-target="$runId:forward" \
    comment="Process all packets passing through the FORWARD chain"
