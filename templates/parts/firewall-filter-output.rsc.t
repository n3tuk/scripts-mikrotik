# -- templates/parts/firewall-filter-output.rsc.t
{{- /* vim:set ft=routeros: */}}
# Process all traffic which is leaving for this host, limiting what is accepted
# to the minimum needed.

{{ template "item" "filter/output jump" }}

# -> output
#  + established check
#  + invalid check
#  > check:icmp
#    > check:icmp:allowed
#      - accept allowed icmp packets
#    > check:icmp:ping
#      - drop restricted hosts
#      - rate limit allowed icmp echo packets
#      - add hosts to restricted list
#      - drop excess icmp echo packets
#    - drop all other icmp packets
#  > check:dns
#    - accept dns requests to selected hosts
#    > reject
#      - drop with icmp-admin-prohibited
#  > check:ntp
#    - accept ntp requests to selected hosts
#    > reject
#      - drop with icmp-admin-prohibited
#  > output:internal
#    - accept http(s) requests
#  > output:external
#    - accept http(s) requests
#    > output:external:wireguard
#      - accept wireguard requests
#    > output:external:ipsec (disabled)
#      - accept ipsec-encapsulated packets
#      - accept esp+ah packets
#      - accept ikev2 requests
#  > reject
#    - drop with icmp-admin-prohibited

/ip firewall filter

add chain="output" \
    action=jump \
    jump-target="$runId:output" \
    comment="Process all packets leaving via the OUTPUT chain"

/ipv6 firewall filter

add chain="output" \
    action=jump \
    jump-target="$runId:output" \
    comment="Process all packets leaving via the OUTPUT chain"

{{ template "item" "filter/output chain" }}

/ip firewall filter

add chain="$runId:output" \
    protocol=icmp \
    action=jump \
    jump-target="$runId:check:icmp" \
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
    action=jump \
    jump-target="$runId:check:dns" \
    comment="Process all DNS connections and packets"

add chain="$runId:output" \
    protocol=udp \
    dst-port=123 \
    action=jump \
    jump-target="$runId:check:ntp" \
    comment="Process all NTP connections and packets"

add chain="$runId:output" \
    dst-address-list="$runId:internal" \
    action=jump \
    jump-target="$runId:output:internal" \
    comment="Process all connections and packets to internal networks"

add chain="$runId:output" \
    dst-address-list="!$runId:internal" \
    action=jump \
    jump-target="$runId:output:external" \
    comment="Process all connections and packets to external networks"

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

{{- if (eq (ds "host").type "router") }}

add chain="$runId:output" \
    out-interface-list=external \
    src-address=fe80::1 \
    dst-address=ff02::/16 \
    protocol=udp \
    src-port=546 \
    dst-port=547 \
    action=accept \
    comment="ACCEPT DHCPv6 server requests via external interfaces"

add chain="$runId:output" \
    out-interface-list=internal \
    src-address=fe80::/16 \
    dst-address=fe80::/16 \
    protocol=udp \
    src-port=547 \
    dst-port=546 \
    action=accept \
    comment="ACCEPT DHCPv6 client responses via internal interfaces"

{{- end }}

add chain="$runId:output" \
    dst-address-list="$runId:dns:trusted" \
    action=jump \
    jump-target="$runId:check:dns" \
    comment="Process all DNS connections and packets"

add chain="$runId:output" \
    protocol=udp \
    dst-port=123 \
    action=jump \
    jump-target="$runId:check:ntp" \
    comment="Process all NTP connections and packets"

add chain="$runId:output" \
    dst-address-list="$runId:internal" \
    action=jump \
    jump-target="$runId:output:internal" \
    comment="Process all connections and packets to internal networks"

{{- if (ne (ds "host").export "netinstall") }}

add chain="$runId:output" \
    dst-address-list="!$runId:internal" \
    action=jump \
    jump-target="$runId:output:external" \
    comment="Process all connections and packets to external networks"

{{- end }}

add chain="$runId:output" \
    action=jump \
    jump-target="$runId:reject" \
    comment="REJECT all other connections and packets"
