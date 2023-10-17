# -- templates/parts/firewall-filter-forward-ports.rsc.t
{{- /* vim:set ft=routeros: */}}

{{- $ipv4_enable := false }}
{{- $ipv4_ports := coll.Slice }}
{{- $ipv6_enable := false }}
{{- $ipv6_ports := coll.Slice }}
{{- if (and (has (ds "network").firewall "forwarding")
            (has (ds "network").firewall.forwarding "ports")) }}
{{-   range $port := (ds "network").firewall.forwarding.ports }}
{{-     if (has $port "ipv4") }}
{{-       $ipv4_enable = true }}
{{-       $ipv4_ports = $ipv4_ports | append $port }}
{{-     end }}
{{-     if (has $port "ipv6") }}
{{-       $ipv6_enable = true }}
{{-       $ipv6_ports = $ipv6_ports | append $port }}
{{-     end }}
{{-   end }}
{{- end }}

{{- if (or $ipv4_enable $ipv6_enable) }}

{{    template "item" "filter/forward:ports chain" }}

{{- end }}

{{- if $ipv4_enable }}

# For IPv4 traffic to be "port forwarded", add a rule to automatically allow any
# packets which have been dstnat'd via the nat chain to be forwarded on into the
# network as in effect permission has already been granted.

/ip firewall filter

{{-   range $port := $ipv4_ports }}

add chain="$runId:forward:ports" \
    dst-address={{ $port.ipv4 }} \
    protocol={{ $port.protocol }} \
    dst-port={{ $port.port }} \
    action=accept \
    comment="{{ if (has $port "comment") }}{{ $port.comment }}{{ end }}"
{{-   end }}

add chain="$runId:forward" \
    connection-state=new \
    action=jump jump-target="$runId:forward:ports" \
    comment="Process requests to publicly accessible services from the internal network"

{{- end }}

{{- if $ipv6_enable }}

# For IPv6 traffic, add explicit rules for each address and port combination
# configured as "port forwarding" and allow them through as these are all public
# IP addresses and will not be managed by the nat chain normally.

/ipv6 firewall filter

{{-   range $port := $ipv6_ports }}

add chain="$runId:forward:ports" \
    in-interface={{ $port.interface }} \
    dst-address={{ $port.ipv6 }} \
    protocol={{ $port.protocol }} \
    dst-port={{ $port.port }} \
    action=accept \
    comment="{{ if (has $port "comment") }}{{ $port.comment }}{{ end }}"
{{-   end }}

add chain="$runId:forward" \
    connection-state=new \
    action=jump jump-target="$runId:forward:ports" \
    comment="Process all connections ports which should be available publicly"

{{- end }}
