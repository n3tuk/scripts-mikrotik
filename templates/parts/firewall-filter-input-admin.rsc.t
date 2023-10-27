# -- templates/parts/firewall-filter-input-internal.rsc.t
{{- /* vim:set ft=routeros: */}}
# Process all traffic which is for administrative services on this host,
# including WebFig, WinBox, and the API.

{{- if (ne (ds "host").export "netinstall") }}

{{    template "item" "filter/input:admin chain" }}

/ip firewall filter

add chain="$runId:input:admin" \
    protocol=tcp dst-port=443 \
    action=accept \
    comment="ACCEPT WebFig HTTPS connections"
add chain="$runId:input:admin" \
    protocol=tcp dst-port=8291 \
    action=accept \
    comment="ACCEPT WinBox connections"
add chain="$runId:input:admin" \
    protocol=tcp dst-port=8728 \
    action=jump jump-target="$runId:input:internal:api" \
    comment="Process all API connections"

/ipv6 firewall filter

add chain="$runId:input:admin" \
    protocol=tcp dst-port=443 \
    action=accept \
    comment="ACCEPT WebFig HTTPS connections"
add chain="$runId:input:admin" \
    protocol=tcp dst-port=8291 \
    action=accept \
    comment="ACCEPT WinBox connections"
add chain="$runId:input:admin" \
    protocol=tcp dst-port=8728 \
    action=jump jump-target="$runId:input:internal:api" \
    comment="Process all API connections"

{{    template "item" "filter/input:api chain" }}

/ip firewall filter

add chain="$runId:input:api" \
    protocol=tcp \
    dst-port=8728 \
    action=accept \
    comment="ACCEPT API connections over HTTPS"

/ipv6 firewall filter

add chain="$runId:input:api" \
    protocol=tcp \
    dst-port=8728 \
    action=accept \
    comment="ACCEPT API connections over HTTPS"

{{- end }}
