# -- templates/parts/firewall-filter-output-external.rsc.t
{{- /* vim:set ft=routeros: */}}

{{ template "item" "filter/output:external chain" }}

/ip firewall filter

add chain="$runId:output:external" \
    dst-address-list="$runId:https:trusted" \
    protocol=tcp \
    dst-port=80,443 \
    action=accept \
    comment="ACCEPT all HTTP(S) connections to trusted hosts"

{{- if (and (ne (ds "host").export "netinstall")
            (eq (ds "host").type "router")) }}

add chain="$runId:output:external" \
    dst-address-list="$runId:wireguard:trusted" \
    action=jump \
    jump-target="$runId:output:wireguard" \
    comment="Process WireGuard connections to trusted hosts"

add chain="$runId:output:external" \
    dst-address-list="$runId:ipsec:trusted" \
    action=jump \
    jump-target="$runId:output:ipsec" \
    disabled=yes \
    comment="Process all IPsec connections to trusted hosts"

{{- end }}

/ipv6 firewall filter

add chain="$runId:output:external" \
    dst-address-list="$runId:https:trusted" \
    protocol=tcp \
    dst-port=80,443 \
    action=accept \
    comment="ACCEPT all HTTP(S) connections to trusted hosts"

{{- if (and (ne (ds "host").export "netinstall")
            (eq (ds "host").type "router")) }}

add chain="$runId:output:external" \
    dst-address-list="$runId:wireguard:trusted" \
    action=jump \
    jump-target="$runId:output:wireguard" \
    comment="Process WireGuard connections to trusted hosts"

add chain="$runId:output:external" \
    dst-address-list="$runId:ipsec:trusted" \
    action=jump \
    jump-target="$runId:output:ipsec" \
    disabled=yes \
    comment="Process all IPsec connections to trusted hosts"

{{- end }}

{{- if (and (ne (ds "host").export "netinstall")
            (eq (ds "host").type "router")) }}

{{ template "item" "filter/output:wireguard chain" }}

/ip firewall filter

add chain="$runId:output:wireguard" \
    protocol=udp \
    dst-port=2133 \
    action=accept \
    comment="ACCEPT all WireGuard connections"

/ipv6 firewall filter

add chain="$runId:output:wireguard" \
    protocol=udp \
    dst-port=2133 \
    action=accept \
    comment="ACCEPT all WireGuard connections"

{{ template "item" "filter/output:ipsec chain" }}

/ip firewall filter

add chain="$runId:output:ipsec" \
    ipsec-policy=out,ipsec \
    action=accept \
    comment="ACCEPT all connections encrypted via IPsec"

add chain="$runId:output:ipsec" \
    protocol=ipsec-esp \
    action=accept \
    comment="ACCEPT all ESP connections encrypted"

add chain="$runId:output:ipsec" \
    protocol=ipsec-ah \
    action=accept \
    comment="ACCEPT all AH connections encrypted"

add chain="$runId:output:ipsec" \
    protocol=udp \
    dst-port=4500 \
    action=accept \
    comment="ACCEPT IKEv2 connections"

add chain="$runId:output:ipsec" \
    protocol=udp \
    dst-port=500 \
    action=accept \
    disabled=yes \
    comment="ACCEPT IKE connections (deprecated)"

/ipv6 firewall filter

add chain="$runId:output:ipsec" \
    ipsec-policy=out,ipsec \
    action=accept \
    comment="ACCEPT all connections encrypted via IPsec"

add chain="$runId:output:ipsec" \
    protocol=ipsec-esp \
    action=accept \
    comment="ACCEPT all ESP connections encrypted"

add chain="$runId:output:ipsec" \
    protocol=ipsec-ah \
    action=accept \
    comment="ACCEPT all AH connections encrypted"

add chain="$runId:output:ipsec" \
    protocol=udp \
    dst-port=4500 \
    action=accept \
    comment="ACCEPT IKEv2 connections"

add chain="$runId:output:ipsec" \
    protocol=udp \
    dst-port=500 \
    action=accept \
    disabled=yes \
    comment="ACCEPT IKE connections (deprecated)"

{{- end }}
