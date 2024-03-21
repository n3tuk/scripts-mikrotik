# -- templates/parts/firewall-filter-input-internal.rsc.t
{{- /* vim:set ft=routeros: */}}

{{ template "item" "filter/input:internal chain" }}

/ip firewall filter

{{-  if (eq (ds "host").type "router") }}

add chain="$runId:input:internal" \
    protocol=udp \
    dst-port=53 \
    action=accept \
    comment="ACCEPT all DNS (UDP) connections"

add chain="$runId:input:internal" \
    protocol=tcp \
    dst-port=53 \
    action=accept \
    comment="ACCEPT all DNS (TCP) connections"

add chain="$runId:input:internal" \
    protocol=udp \
    dst-port=123  \
    action=accept \
    comment="ACCEPT all NTP packets"

add chain="$runId:input:internal" \
    protocol=udp \
    src-port=68 \
    dst-port=67 \
    action=accept \
    comment="ACCEPT all DHCP requests"

{{- end }}

{{- if (eq (ds "host").export "netinstall") }}

add chain="$runId:input:internal" \
    protocol=tcp \
    dst-port=22,443,8291,8728 \
    connection-state=new \
    action=accept \
    comment="ACCEPT all connections to administrative services"

{{- else }}

add chain="$runId:input:internal" \
    protocol=tcp \
    dst-port=22 \
    connection-state=new \
    action=jump \
    jump-target="$runId:check:ssh" \
    comment="Process all SSH connections and packets"

add chain="$runId:input:internal" \
    src-address-list="$runId:admin:trusted" \
    connection-state=new \
    action=jump \
    jump-target="$runId:input:admin" \
    comment="Process all Admin connections from trusted hosts"

add chain="$runId:input:internal" \
    src-address-list="$runId:api:trusted" \
    connection-state=new \
    action=jump \
    jump-target="$runId:input:api" \
    comment="Process all API connections from trusted hosts"

add chain="$runId:input:internal" \
    src-address-list="$runId:bgp:trusted" \
    connection-state=new \
    action=jump \
    jump-target="$runId:input:bgp" \
    comment="Process all BGP connections from trusted hosts"

{{- end }}

add chain="$runId:input:internal" \
    action=jump \
    jump-target="$runId:reject" \
    comment="REJECT all other connections and packets"

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

{{- if (eq (ds "host").export "netinstall") }}

add chain="$runId:input:internal" \
    protocol=tcp \
    dst-port=22,443,8291,8728 \
    connection-state=new \
    action=accept \
    comment="ACCEPT all connections to administrative services"

{{- else }}

add chain="$runId:input:internal" \
    protocol=tcp \
    dst-port=22 \
    connection-state=new \
    action=jump \
    jump-target="$runId:check:ssh" \
    comment="Process all SSH connections and packets"

add chain="$runId:input:internal" \
    src-address-list="$runId:admin:trusted" \
    connection-state=new \
    action=jump \
    jump-target="$runId:input:admin" \
    comment="Process all Admin connections from trusted hosts"

add chain="$runId:input:internal" \
    src-address-list="$runId:api:trusted" \
    connection-state=new \
    action=jump \
    jump-target="$runId:input:api" \
    comment="Process all API connections from trusted hosts"

add chain="$runId:input:internal" \
    src-address-list="$runId:bgp:trusted" \
    connection-state=new \
    action=jump \
    jump-target="$runId:input:bgp" \
    comment="Process all BGP connections from trusted hosts"

{{- end }}

add chain="$runId:input:internal" \
    action=jump \
    jump-target="$runId:reject" \
    comment="REJECT all other connections and packets"
