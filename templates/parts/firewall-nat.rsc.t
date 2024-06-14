# -- templates/parts/firewall-nat.rsc.t
{{- /* vim:set ft=routeros: */}}
# Set up the NAT table which enables selected network address translations for
# inbound connections from public networks when received via external
# interfaces.

{{  template "component" "nat table" }}

{{- $ports := coll.Slice }}
{{- if (and (has (ds "network").firewall "forwarding")
            (has (ds "network").firewall.forwarding "ports")) }}
{{-   range $port := (ds "network").firewall.forwarding.ports }}
{{-     if (has $port "ipv4") }}
{{-       $ports = $ports | append $port }}
{{-     end }}
{{-   end }}
{{  end }}

{{- if (gt (len $ports) 0) }}
# -> dstnat
#  - forward ports to internal hosts
{{- end }}
# -> srcnat
#  - masquerade internal connections to public networks via external interfaces

/ip firewall nat

{{  template "item" "nat/srcnat jump" }}

add chain="srcnat" \
    action=jump \
    jump-target="$runId:srcnat" \
    comment="Process all packets passing leaving through the SRCNAT chain"

{{- if (and (eq (ds "host").type "router")
            (gt (len $ports) 0)) }}

{{  template "item" "nat/dstnat jump" }}

add chain="dstnat" \
    action=jump \
    jump-target="$runId:dstnat" \
    comment="Process all packets passing entering through the DSTNAT chain"

{{    template "item" "nat/dstnat chain" }}

{{-   range $port := $ports }}

add chain="$runId:dstnat" \
    dst-address={{ index $port "dst-address" }} \
{{-     if (has $port "protocol") }}
    protocol={{ $port.protocol }} \
    dst-port={{ $port.port }} \
{{-     end }}
    to-addresses={{ $port.ipv4 }} \
    to-port={{ $port.port }} \
    action=dst-nat \
    comment="{{ if (has $port "comment") }}{{ $port.comment }}{{ end }}"

{{-     if (has $port "src-address-list") }}

# Add srcnat rule for src-address-list to allow for hairpin NAT
add chain="$runId:srcnat" \
    src-address-list="$runId:{{ index $port "src-address-list" }}" \
    dst-address={{ $port.ipv4 }} \
{{-       if (has $port "protocol") }}
    protocol={{ $port.protocol }} \
    dst-port={{ $port.port }} \
{{-       end }}
    action=masquerade \
    comment="{{ if (has $port "comment") }}{{ $port.comment }}{{ end }}"

{{-     end }}
{{-   end }}
{{- end }}

{{  template "item" "nat/srcnat chain" }}

add chain="$runId:srcnat" \
    src-address-list="$runId:internal" \
    dst-address-list="!$runId:internal" \
    ipsec-policy=out,none \
    out-interface-list=external \
    action=masquerade \
    comment="MASQUERADE all outgoing external connections"

{{  template "parts/firewall-cleanup.rsc.t" (coll.Slice "nat" "dstnat" "input" "output" "srcnat") -}}
