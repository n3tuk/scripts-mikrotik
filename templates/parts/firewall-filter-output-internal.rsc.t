# -- templates/parts/firewall-filter-output-internal.rsc.t
{{- /* vim:set ft=routeros: */}}

{{ template "item" "filter/output:internal chain" }}

/ip firewall filter

add chain="$runId:output:internal" \
    dst-address-list="$runId:https:trusted" \
    protocol=tcp dst-port=80,443 \
    action=accept \
    comment="ACCEPT all HTTP(S) connections to trusted hosts"

/ipv6 firewall filter

add chain="$runId:output:internal" \
    dst-address-list="$runId:https:trusted" \
    protocol=tcp dst-port=80,443 \
    action=accept \
    comment="ACCEPT all HTTP(S) connections to trusted hosts"
