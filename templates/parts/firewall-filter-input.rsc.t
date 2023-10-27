# -- templates/parts/firewall-filter-input.rsc.t
{{- /* vim:set ft=routeros: */}}
# Process all traffic which is destined for this host, limiting what is accepted
# to the minimum needed, and taking into account traffic coming in from internal
# networks or external networks, for both IPv4 and IPv6 (especially as IPv6 can
# allow devices behind a router to be publicly accessible too).

{{ template "item" "filter/input jump" }}

# -> input
#  > check:icmp
#    > check:icmp:allowed
#      - accept allowed icmp packets
#      - drop all other icmp packets
#    > check:icmp:ping
#      - drop restricted hosts
#      - rate limit icmp echo packets
#      - add hosts to restricted list
#      - drop excess icmp echo packets
#  - established/invalid checks
#  - accept dhcp requests
#  > input:internal
#    - accept dns requests
#    - accept ntp requests
#    > check:ssh
#      - drop restricted hosts
#      - rate limit ssh connection attempts
#      - add hosts to restricted list
#      - drop excess ssh connections
#    > input:admin
#      - accept webfig access
#      - accept winbox access
#    > input:api
#      - accept api access
#    > reject
#      - drop with icmp-admin-prohibited
#  > input:external
#    > tarpit:drop
#      - tarpit/drop connection attempts from known bad hosts
#    > check:ssh
#      - drop restricted hosts
#      - rate limit ssh connection attempts
#      - add hosts to restricted list
#      - drop excess ssh connections
#    > input:admin
#      - accept webfig access
#      - accept winbox access
#    > input:api
#      - accept api access
#    > input:wireguard
#      - accept wireguard requests
#    > input:ipsec (disabled)
#      - accept ipsec-encapsulated packets
#      - accept esp+ah packets
#      - accept ikev2 requests
#    > tarpit:process
#      - rate limit drops with icmp-admin-prohibited
#      > tarpit:drop
#        - tarpit/drop connection attempts from known bad hosts

/ip firewall filter

add chain="input" \
    action=jump \
    jump-target="$runId:input" \
    comment="Process all packets arriving via the INPUT chain"

/ipv6 firewall filter

add chain="input" \
    action=jump \
    jump-target="$runId:input" \
    comment="Process all packets arriving via the INPUT chain"

{{ template "item" "filter/input chain" }}

/ip firewall filter

add chain="$runId:input" \
    protocol=icmp \
    action=jump \
    jump-target="$runId:check:icmp" \
    comment="Process all ICMP connections and packets"

add chain="$runId:input" \
    connection-state=established,related,untracked \
    action=accept \
    comment="ACCEPT packets on established, related, and untracked connections"

add chain="$runId:input" \
    connection-state=invalid \
    action=drop \
    comment="DROP packets from invalid connections"

add chain="$runId:input" \
    src-address-list="$runId:admin:trusted" \
    connection-state=new \
    action=jump \
    jump-target="$runId:input:admin" \
    comment="Process all Admin connections from trusted hosts"

add chain="$runId:input" \
    src-address-list="$runId:api:trusted" \
    connection-state=new \
    action=jump \
    jump-target="$runId:input:api" \
    comment="Process all API connections from trusted hosts"

add chain="$runId:input" \
    src-address-list="$runId:internal" \
    connection-state=new \
    action=jump \
    jump-target="$runId:input:internal" \
    comment="Process all connections and packets from internal networks (including VPNs)"

{{- if (ne (ds "host").export "netinstall") }}

add chain="$runId:input" \
    src-address-list="!$runId:internal" \
    connection-state=new \
    action=jump \
    jump-target="$runId:input:external" \
    comment="Process all connections and packets from external networks"

{{- end }}

/ipv6 firewall filter

add chain="$runId:input" \
    protocol=icmpv6 \
    action=accept \
    comment="ACCEPT all ICMPv6 connections and packets"

add chain="$runId:input" \
    connection-state=established,related,untracked \
    action=accept \
    comment="ACCEPT packets on established, related, and untracked connections"
add chain="$runId:input" \
    connection-state=invalid \
    action=drop \
    comment="DROP packets from invalid connections"

{{- if (eq (ds "host").type "router") }}

add chain="$runId:input" \
    src-address=fe80::/16 \
    protocol=udp \
    dst-port=547 \
    action=accept \
    comment="ACCEPT DHCPv6 server requests"

{{- end }}

add chain="$runId:input" \
    src-address-list="$runId:internal" \
    connection-state=new \
    action=jump \
    jump-target="$runId:input:internal" \
    comment="Process all connections and packets from internal networks (including VPNs)"

{{- if (ne (ds "host").export "netinstall") }}

add chain="$runId:input" \
    src-address-list="!$runId:internal" \
    connection-state=new \
    action=jump \
    jump-target="$runId:input:external" \
    comment="Process all connections and packets from external networks"

{{- end }}

add chain="$runId:input" \
    action=jump \
    jump-target="$runId:reject" \
    comment="REJECT all other connections and packets"
