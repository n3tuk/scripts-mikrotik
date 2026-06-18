# -- templates/parts/firewall-filter-output-internal.rsc.t
{{- /* vim:set ft=routeros: */}}

{{ template "item" "filter/output:internal chain" }}

/ip firewall filter

add chain="$runId:output:internal" \
    dst-address-list="$runId:https:trusted" \
    protocol=tcp \
    dst-port=80,443 \
    action=accept \
    comment="ACCEPT all HTTP(S) connections to trusted hosts"

add chain="$runId:output:internal" \
    dst-address-list="$runId:bgp:trusted" \
    protocol=tcp \
    dst-port=179 \
    action=accept \
    comment="ACCEPT BGP connections for routing"

add chain="$runId:output:internal" \
    dst-address-list="$runId:bgp:trusted" \
    protocol=udp \
    dst-port=3784,3785,4784 \
    action=accept \
    comment="ACCEPT BFP connections for routing"

/ipv6 firewall filter

add chain="$runId:output:internal" \
    dst-address-list="$runId:https:trusted" \
    protocol=tcp \
    dst-port=80,443 \
    action=accept \
    comment="ACCEPT all HTTP(S) connections to trusted hosts"

add chain="$runId:output:internal" \
    dst-address-list="$runId:bgp:trusted" \
    protocol=tcp \
    dst-port=179 \
    action=accept \
    comment="ACCEPT BGP connections for routing"

add chain="$runId:output:internal" \
    dst-address-list="$runId:bgp:trusted" \
    protocol=udp \
    dst-port=3784,3785,4784 \
    action=accept \
    comment="ACCEPT BFP connections for routing"
