# -- templates/parts/firewall-filter-input-internal.rsc.t
{{- /* vim:set ft=routeros: */}}

{{ template "item" "filter/input:internal chain" }}

/ip firewall filter

{{-  if (eq (ds "host").type "router") }}

add chain="$runId:input:internal" \
    protocol=udp dst-port=53 \
    action=accept \
    comment="ACCEPT all DNS (UDP) connections"
add chain="$runId:input:internal" \
    protocol=tcp dst-port=53 \
    action=accept \
    comment="ACCEPT all DNS (TCP) connections"
add chain="$runId:input:internal" \
    protocol=udp dst-port=123  \
    action=accept \
    comment="ACCEPT all NTP packets"
{{- end }}

{{- if (ne (ds "host").export "netinstall") }}

add chain="$runId:input:internal" \
    protocol=tcp dst-port=22 \
    action=jump jump-target="$runId:check:ssh" \
    comment="Process all SSH connections"
add chain="$runId:input:internal" \
    src-address-list="$runId:admin:trusted" \
    action=jump jump-target="$runId:input:internal:admin" \
    comment="Process all Admin connections from trusted hosts"
add chain="$runId:input:internal" \
    src-address-list="$runId:api:trusted" \
    protocol=tcp dst-port=8728 \
    action=jump jump-target="$runId:input:internal:api" \
    comment="Process all API connections from trusted hosts"
{{- else }}

add chain="$runId:input:internal" \
    protocol=tcp dst-port=22,80,443,8291,8728 \
    action=accept \
    comment="ACCEPT all admin connections"
{{- end }}

add chain="$runId:input:internal" \
    action=jump jump-target="$runId:reject:admin" \
    comment="DROP all other connections and packets"

/ipv6 firewall filter

{{-  if (eq (ds "host").type "router") }}

add chain="$runId:input:internal" \
    protocol=udp dst-port=53 \
    action=accept \
    comment="ACCEPT all DNS (UDP) connections"
add chain="$runId:input:internal" \
    protocol=tcp dst-port=53 \
    action=accept \
    comment="ACCEPT all DNS (TCP) connections"
add chain="$runId:input:internal" \
    protocol=udp dst-port=123  \
    action=accept \
    comment="ACCEPT all NTP packets"
{{- end }}

{{- if (ne (ds "host").export "netinstall") }}

add chain="$runId:input:internal" \
    protocol=tcp dst-port=22 \
    action=jump jump-target="$runId:check:ssh" \
    comment="Process all SSH connections"
add chain="$runId:input:internal" \
    src-address-list="$runId:admin:trusted" \
    action=jump jump-target="$runId:input:internal:admin" \
    comment="Process all Admin connections from trusted hosts"
add chain="$runId:input:internal" \
    src-address-list="$runId:api:trusted" \
    protocol=tcp dst-port=8728 \
    action=jump jump-target="$runId:input:internal:api" \
    comment="Process all API connections from trusted hosts"
{{- else }}

add chain="$runId:input:internal" \
    protocol=tcp dst-port=22,443,8291,8728 \
    action=accept \
    comment="ACCEPT all connections to admin services"
{{- end }}

add chain="$runId:input:internal" \
    action=jump jump-target="$runId:reject:admin" \
    comment="DROP all other connections and packets"

{{- if (ne (ds "host").export "netinstall") }}

{{    template "item" "filter/input:internal:admin chain" }}

/ip firewall filter

add chain="$runId:input:internal:admin" \
    protocol=tcp dst-port=443 \
    action=accept \
    comment="ACCEPT WebFig HTTPS connections"
add chain="$runId:input:internal:admin" \
    protocol=tcp dst-port=8291 \
    action=accept \
    comment="ACCEPT WinBox connections"
add chain="$runId:input:internal:admin" \
    protocol=tcp dst-port=8728 \
    action=jump jump-target="$runId:input:internal:api" \
    comment="Process all API connections"

/ipv6 firewall filter

add chain="$runId:input:internal:admin" \
    protocol=tcp dst-port=443 \
    action=accept \
    comment="ACCEPT WebFig HTTPS connections"
add chain="$runId:input:internal:admin" \
    protocol=tcp dst-port=8291 \
    action=accept \
    comment="ACCEPT WinBox connections"
add chain="$runId:input:internal:admin" \
    protocol=tcp dst-port=8728 \
    action=jump jump-target="$runId:input:internal:api" \
    comment="Process all API connections"

{{    template "item" "filter/input:internal:api chain" }}

/ip firewall filter

add chain="$runId:input:internal:api" \
    protocol=tcp dst-port=8728 \
    action=accept \
    comment="ACCEPT API connections"

/ipv6 firewall filter

add chain="$runId:input:internal:api" \
    protocol=tcp dst-port=8728 \
    action=accept \
    comment="ACCEPT API connections"

{{- end }}
