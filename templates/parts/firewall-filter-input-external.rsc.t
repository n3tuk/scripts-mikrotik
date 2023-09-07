# -- templates/parts/firewall-filter-input-external.rsc.t
{{- /* vim:set ft=routeros: */}}

{{  template "item" "filter/input:external chain" }}

/ip firewall filter

{{- if (and (ne (ds "host").export "netinstall")
            (eq (ds "host").type "router")) }}

add chain="$runId:input:external" \
    src-address-list="dynamic:tarpit:restricted" \
    action=jump jump-target="$runId:tarpit:drop" \
    comment="TARPIT (hold open) connections from restricted hosts"
add chain="$runId:input:external" \
    protocol=tcp dst-port=22 \
    action=jump jump-target="$runId:check:ssh" \
    comment="Process all SSH connections"
add chain="$runId:input:external" \
    src-address-list="$runId:wireguard:trusted" \
    action=jump jump-target="$runId:input:external:wireguard" \
    comment="Process WireGuard connections from trusted hosts"
add chain="$runId:input:external" \
    src-address-list="$runId:ipsec:trusted" \
    action=jump jump-target="$runId:input:external:ipsec" \
    disabled=yes \
    comment="Process all IPsec connections from trusted hosts"

add chain="$runId:input:external" \
    action=jump jump-target="$runId:tarpit:process" \
    comment="TARPIT (hold open) all other connections and packets"
{{- else }}
add chain="$runId:input:external" \
    action=drop \
    comment="DROP all other connections and packets"
{{- end }}

{{- if (ne (ds "host").export "netinstall") }}

/ipv6 firewall filter

add chain="$runId:input:external" \
    src-address-list="dynamic:tarpit:restricted" \
    action=jump jump-target="$runId:tarpit:drop" \
    comment="DROP connections from restricted hosts"
add chain="$runId:input:external" \
    protocol=tcp dst-port=22 \
    action=jump jump-target="$runId:check:ssh" \
    comment="Process all SSH connections"
{{-   if (eq (ds "host").type "router") }}
add chain="$runId:input:external" \
    src-address-list="$runId:wireguard:trusted" \
    action=jump jump-target="$runId:input:external:wireguard" \
    comment="Process WireGuard connections from trusted hosts"
add chain="$runId:input:external" \
    src-address-list="$runId:ipsec:trusted" \
    action=jump jump-target="$runId:input:external:ipsec" \
    disabled=yes \
    comment="Process all IPsec connections from trusted hosts"
{{-   end }}

add chain="$runId:input:external" \
    action=jump jump-target="$runId:tarpit:process" \
    comment="DROP all other connections and packets"
{{- end }}

{{- if (and (ne (ds "host").export "netinstall")
            (eq (ds "host").type "router")) }}

{{    template "item" "filter/input:external:wireguard chain" }}

/ip firewall filter

add chain="$runId:input:external:wireguard" \
    protocol=udp dst-port=52729 \
    action=accept \
    comment="ACCEPT all WireGuard connections"

/ipv6 firewall filter

add chain="$runId:input:external:wireguard" \
    protocol=udp dst-port=52729 \
    action=accept \
    comment="ACCEPT all WireGuard connections"

{{    template "item" "filter/input:external:ipsec chain" }}

/ip firewall filter

add chain="$runId:input:external:ipsec" \
    ipsec-policy=in,ipsec \
    action=accept \
    comment="ACCEPT all connections encrypted via IPsec"
add chain="$runId:input:external:ipsec" \
    protocol=ipsec-esp \
    action=accept \
    comment="ACCEPT all ESP encrypted connections"
add chain="$runId:input:external:ipsec" \
    protocol=ipsec-ah \
    action=accept \
    comment="ACCEPT all AH authenticated connections"
add chain="$runId:input:external:ipsec" \
    protocol=udp dst-port=4500 \
    action=accept \
    comment="ACCEPT IKEv2 requests"
add chain="$runId:input:external:ipsec" \
    protocol=udp dst-port=500 \
    action=accept \
    disabled=yes \
    comment="ACCEPT IKE requestes (deprecated)"

/ipv6 firewall filter

add chain="$runId:input:external:ipsec" \
    ipsec-policy=in,ipsec \
    action=accept \
    comment="ACCEPT all connections encrypted via IPsec"
add chain="$runId:input:external:ipsec" \
    protocol=ipsec-esp \
    action=accept \
    comment="ACCEPT all ESP encrypted connections"
add chain="$runId:input:external:ipsec" \
    protocol=ipsec-ah \
    action=accept \
    comment="ACCEPT all AH authenticated connections"
add chain="$runId:input:external:ipsec" \
    protocol=udp dst-port=4500 \
    action=accept \
    comment="ACCEPT IKEv2 requests"
add chain="$runId:input:external:ipsec" \
    protocol=udp dst-port=500 \
    action=accept \
    disabled=yes \
    comment="ACCEPT IKE requestes (deprecated)"

{{- end }}
