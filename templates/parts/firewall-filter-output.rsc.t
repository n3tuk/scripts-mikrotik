# -- templates/parts/firewall-filter-output.rsc.t
{{- /* vim:set ft=routeros: */}}

{{ template "item" "filter/output chain" }}

/ip firewall filter

add chain="$runId:output" \
    protocol=icmp \
    action=jump jump-target="$runId:check:icmp" \
    comment="Process all ICMP connections and packets"

add chain="$runId:output" \
    connection-state=established,related,untracked \
    action=accept \
    comment="ACCEPT packets on established, related, and untracked connections"
add chain="$runId:output" \
    connection-state=invalid \
    action=drop \
    comment="DROP packets from invalid connections"

add chain="$runId:output" \
    dst-address-list="$runId:dns:trusted" \
    action=jump jump-target="$runId:check:dns" \
    comment="Process all DNS connections and packets"
add chain="$runId:output" \
    protocol=udp dst-port=123 \
    action=jump jump-target="$runId:check:ntp" \
    comment="Process all NTP connections and packets"

add chain="$runId:output" \
    dst-address-list="$runId:internal" \
    action=jump jump-target="$runId:output:internal" \
    comment="Process all connections and packets to internal networks"
add chain="$runId:output" \
    dst-address-list="!$runId:internal" \
    action=jump jump-target="$runId:output:external" \
    comment="Process all connections and packets to external networks"

add chain="$runId:output" \
    action=jump jump-target="$runId:reject:admin" \
    comment="Reject all other connections and packets"

/ipv6 firewall filter

add chain="$runId:output" \
    protocol=icmpv6 \
    action=accept \
    comment="ACCEPT all ICMPv6 connections and packets"

add chain="$runId:output" \
    connection-state=established,related,untracked \
    action=accept \
    comment="ACCEPT packets on established, related, and untracked connections"
add chain="$runId:output" \
    connection-state=invalid \
    action=drop \
    comment="DROP packets from invalid connections"

add chain="$runId:output" \
    dst-address-list="$runId:dns:trusted" \
    action=jump jump-target="$runId:check:dns" \
    comment="Process all DNS connections and packets"
add chain="$runId:output" \
    protocol=udp dst-port=123 \
    action=jump jump-target="$runId:check:ntp" \
    comment="Process all NTP connections and packets"

add chain="$runId:output" \
    dst-address-list="$runId:internal" \
    action=jump jump-target="$runId:output:internal" \
    comment="Process all connections and packets to internal networks"
add chain="$runId:output" \
    dst-address-list="!$runId:internal" \
    action=jump jump-target="$runId:output:external" \
    comment="Process all connections and packets to external networks"

add chain="$runId:output" \
    action=jump jump-target="$runId:reject:admin" \
    comment="Reject all other connections and packets"

{{ template "item" "filter/output jump" }}

/ip firewall filter

add chain="output" action=jump jump-target="$runId:output" \
    comment="Process all packets passing leaving via the OUTPUT chain"

/ipv6 firewall filter

add chain="output" action=jump jump-target="$runId:output" \
    comment="Process all packets passing leaving via the OUTPUT chain"
