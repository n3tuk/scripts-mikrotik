# -- templates/parts/firewall-filter-input.rsc.t
{{- /* vim:set ft=routeros: */}}

{{ template "item" "filter/input chain" }}

/ip firewall filter

add chain="$runId:input" \
    connection-state=established,related,untracked \
    action=accept \
    comment="ACCEPT packets on established, related, and untracked connections"
add chain="$runId:input" \
    connection-state=invalid \
    action=drop \
    comment="DROP packets from invalid connections"

add chain="$runId:input" \
    protocol=icmp \
    action=jump jump-target="$runId:check:icmp" \
    comment="Process all ICMP connections and packets"

add chain="$runId:input" \
    src-address-list="$runId:internal" \
    action=jump jump-target="$runId:input:internal" \
    comment="Process all connections and packets from internal networks"
add chain="$runId:input" \
    src-address-list="!$runId:internal" \
    action=jump jump-target="$runId:input:external" \
    comment="Process all connections and packets from external networks"

/ipv6 firewall filter

add chain="$runId:input" \
    connection-state=established,related,untracked \
    action=accept \
    comment="ACCEPT packets on established, related, and untracked connections"
add chain="$runId:input" \
    connection-state=invalid \
    action=drop \
    comment="DROP packets from invalid connections"

add chain="$runId:input" \
    protocol=icmpv6 \
    action=accept \
    comment="ACCEPT all ICMPv6 connections and packets"
add chain="$runId:input" \
    src-address=fe80::/16 \
    protocol=udp dst-port=546 \
    action=accept \
    comment="ACCEPT DHCPv6-client prefix delegation packets"

add chain="$runId:input" \
    src-address-list="$runId:internal" \
    action=jump jump-target="$runId:input:internal" \
    comment="Process all connections and packets from internal networks"
add chain="$runId:input" \
    src-address-list="!$runId:internal" \
    action=jump jump-target="$runId:input:external" \
    comment="Process all connections and packets from external networks"

{{ template "item" "filter/input jump" }}

/ip firewall filter

add chain="input" action=jump jump-target="$runId:input" \
    comment="Process all packets arriving via the INPUT chain"

/ipv6 firewall filter

add chain="input" action=jump jump-target="$runId:input" \
    comment="Process all packets arriving via the INPUT chain"
