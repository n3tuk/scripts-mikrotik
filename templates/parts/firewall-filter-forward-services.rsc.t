# -- templates/parts/firewall-filter-forward-services.rsc.t
{{- /* vim:set ft=routeros: */}}

# Add rules for common services which should be generally accessible from all
# internal hosts through this router

{{- $ipv4_enable := false }}
{{- $ipv4_services := coll.Slice }}
{{- $ipv6_enable := false }}
{{- $ipv6_services := coll.Slice }}
{{- if (and (has (ds "network").firewall "forwarding")
            (has (ds "network").firewall.forwarding "services")) }}
{{-   range $service := (ds "network").firewall.forwarding.services }}
{{-     if (has $service "ipv4") }}
{{-       $ipv4_enable = true }}
{{-       $ipv4_services = $ipv4_services | append $service }}
{{-     end }}
{{-     if (has $service "ipv6") }}
{{-       $ipv6_enable = true }}
{{-       $ipv6_services = $ipv6_services | append $service }}
{{-     end }}
{{-   end }}
{{- end }}

{{- if (or $ipv4_enable $ipv6_enable) }}

{{    template "item" "filter/forward:services chain" }}

{{- end }}

{{- if $ipv4_enable }}

/ip firewall filter

{{-   range $service := $ipv4_services }}

add chain="$runId:forward:services" \
    dst-address={{ $service.ipv4 }} \
    protocol={{ $service.protocol }} \
    dst-port={{ $service.port }} \
    action=accept \
    comment="{{ if (has $service "comment") }}{{ $service.comment }}{{ end }}"
{{-   end }}

{{- end }}

{{- if $ipv6_enable }}

/ipv6 firewall filter

{{-   range $service := $ipv6_services }}

add chain="$runId:forward:services" \
    dst-address={{ $service.ipv6 }} \
    protocol={{ $service.protocol }} \
    dst-port={{ $service.port }} \
    action=accept \
    comment="{{ if (has $service "comment") }}{{ $service.comment }}{{ end }}"

{{-   end }}

{{- end }}
