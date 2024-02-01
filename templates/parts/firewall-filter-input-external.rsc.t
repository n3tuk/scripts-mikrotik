# -- templates/parts/firewall-filter-input-external.rsc.t
{{- /* vim:set ft=routeros: */}}

{{  template "item" "filter/input:external chain" }}

/ip firewall filter

# Add an explicit override
add chain="$runId:input:external" \
    src-address-list="dynamic:tarpit:restricted" \
    action=jump \
    jump-target="$runId:tarpit:drop" \
    comment="TARPIT (hold open) connections from restricted hosts"

add chain="$runId:input:external" \
    protocol=tcp \
    connection-state=new \
    dst-port=22 \
    action=jump \
    jump-target="$runId:check:ssh" \
    comment="Process all SSH connections and packets"

add chain="$runId:input:external" \
    src-address-list="$runId:admin:trusted" \
    connection-state=new \
    action=jump \
    jump-target="$runId:input:admin" \
    comment="Process all Admin connections from trusted hosts"

add chain="$runId:input:external" \
    src-address-list="$runId:api:trusted" \
    connection-state=new \
    action=jump \
    jump-target="$runId:input:api" \
    comment="Process all API connections from trusted hosts"

{{- if (eq (ds "host").type "router") }}

add chain="$runId:input:external" \
    src-address-list="$runId:wireguard:trusted" \
    action=jump \
    jump-target="$runId:input:wireguard" \
    comment="Process WireGuard connections from trusted hosts"

add chain="$runId:input:external" \
    src-address-list="$runId:ipsec:trusted" \
    action=jump \
    jump-target="$runId:input:ipsec" \
    disabled=yes \
    comment="Process all IPsec connections from trusted hosts"

{{- end }}

add chain="$runId:input:external" \
    action=jump jump-target="$runId:tarpit" \
    comment="TARPIT (hold open) all other connections and packets"

/ipv6 firewall filter

add chain="$runId:input:external" \
    src-address-list="dynamic:tarpit:restricted" \
    action=jump \
    jump-target="$runId:tarpit:drop" \
    comment="DROP connections from restricted hosts"

add chain="$runId:input:external" \
    protocol=tcp \
    dst-port=22 \
    action=jump \
    jump-target="$runId:check:ssh" \
    comment="Process all SSH connections"

{{- if (eq (ds "host").type "router") }}

add chain="$runId:input:external" \
    src-address-list="$runId:wireguard:trusted" \
    action=jump \
    jump-target="$runId:input:wireguard" \
    comment="Process WireGuard connections from trusted hosts"

add chain="$runId:input:external" \
    src-address-list="$runId:ipsec:trusted" \
    action=jump \
    jump-target="$runId:input:ipsec" \
    disabled=yes \
    comment="Process all IPsec connections from trusted hosts"

{{- end }}

add chain="$runId:input:external" \
    action=jump jump-target="$runId:tarpit:process" \
    comment="DROP all other connections and packets"

{{- if (eq (ds "host").type "router") }}

{{    template "item" "filter/input:wireguard chain" }}

/ip firewall filter

add chain="$runId:input:wireguard" \
    protocol=udp \
    dst-port=2133 \
    action=accept \
    comment="ACCEPT all WireGuard connections"

/ipv6 firewall filter

add chain="$runId:input:wireguard" \
    protocol=udp \
    dst-port=2133 \
    action=accept \
    comment="ACCEPT all WireGuard connections"

{{    template "item" "filter/input:ipsec chain" }}

/ip firewall filter

add chain="$runId:input:ipsec" \
    ipsec-policy=in,ipsec \
    action=accept \
    comment="ACCEPT all connections encrypted via IPsec"

add chain="$runId:input:ipsec" \
    protocol=ipsec-esp \
    action=accept \
    comment="ACCEPT all ESP encrypted connections"

add chain="$runId:input:ipsec" \
    protocol=ipsec-ah \
    action=accept \
    comment="ACCEPT all AH authenticated connections"

add chain="$runId:input:ipsec" \
    protocol=udp dst-port=4500 \
    action=accept \
    comment="ACCEPT IKEv2 requests"

/ipv6 firewall filter

add chain="$runId:input:ipsec" \
    ipsec-policy=in,ipsec \
    action=accept \
    comment="ACCEPT all connections encrypted via IPsec"

add chain="$runId:input:ipsec" \
    protocol=ipsec-esp \
    action=accept \
    comment="ACCEPT all ESP encrypted connections"

add chain="$runId:input:ipsec" \
    protocol=ipsec-ah \
    action=accept \
    comment="ACCEPT all AH authenticated connections"

add chain="$runId:input:ipsec" \
    protocol=udp \
    dst-port=4500 \
    action=accept \
    comment="ACCEPT IKEv2 requests"

{{- end }}
