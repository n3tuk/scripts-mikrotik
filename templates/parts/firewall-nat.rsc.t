# -- templates/parts/firewall-nat.rsc.t
{{- /* vim:set ft=routeros: */}}

{{- $ports := coll.Slice }}
{{- if (and (has (ds "network").firewall "forwarding")
            (has (ds "network").firewall.forwarding "ports")) }}
{{-   range $port := (ds "network").firewall.forwarding.ports }}
{{-     if (has $port "ipv4") }}
{{-       $ports = $ports | append $port }}
{{-     end }}
{{-   end }}
{{- end }}

# The nat table for the firewall provides access to network address translations
# for outgoing connections to public network via external interfaces from
# internal hosts.
#
{{- if (gt (len $ports) 0) }}
# -> dstnat
#  - forward ports to internal hosts
{{- end }}
# -> srcnat
#  - masquerade internal connections to public networks via external interfaces

{{  template "component" "nat table" }}

# Add configuration to the NAT table which enabled network address translations
# for outgoing connections to public network via external interfaces from
# internal hosts.

{{- if (gt (len $ports) 0) }}

{{    template "item" "nat/dstnat chain" }}

# Configure port forwarding rules for IPv4, which are automatically approved by
# the forward chain under filter, so only need to be set here to forward traffic

/ip firewall nat

{{-   range $port := $ports }}

add chain="$runId:dstnat" \
    in-interface={{ $port.interface }} \
{{-     if (has $port "protocol") }}
    protocol={{ $port.protocol }} \
{{-     end }}
    dst-port={{ $port.port }} \
    to-addresses={{ $port.ipv4 }} \
    to-port={{ $port.port }} \
    action=dst-nat \
    comment="{{ if (has $port "comment") }}{{ $port.comment }}{{ end }}"
{{-   end }}
{{- end }}

{{  template "item" "nat/srcnat chain" }}

/ip firewall nat

add chain="$runId:srcnat" \
    src-address-list="$runId:internal" \
    dst-address-list="!$runId::internal" \
    ipsec-policy=out,none \
    out-interface-list=external \
    action=masquerade \
    comment="MASQUERADE all outgoing external connections"

{{- if (gt (len $ports) 0) }}

{{    template "item" "nat/dstnat jump" }}

add chain="dstnat" \
    action=jump jump-target="$runId:dstnat" \
    comment="Process all packets passing entering through the DSTNAT chain"

{{- end }}

{{  template "item" "nat/srcnat jump" }}

add chain="srcnat" \
    action=jump jump-target="$runId:srcnat" \
    comment="Process all packets passing leaving through the SRCNAT chain"

{{  template "parts/firewall-cleanup.rsc.t" (coll.Slice "nat" "dstnat" "input" "output" "srcnat") -}}
