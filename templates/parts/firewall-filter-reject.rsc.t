# -- templates/parts/firewall-filter-reject-admin.rsc.t
{{- /* vim:set ft=routeros: */}}

{{ template "item" "filter/reject:admin chain" }}

/ip firewall filter

add chain="$runId:reject:admin" \
    dst-address-list="$runId:broadcasts" \
    action=drop \
    comment="DROP all broadcast-directed connections silently"
add chain="$runId:reject:admin" \
    dst-limit=3/5m,5,src-and-dst-addresses/3h \
    action=reject reject-with=icmp-admin-prohibited \
    log=yes log-prefix="REJECT!" \
    comment="Politely REJECT all connections with ICMP response (rated limited to 5/min)"
add chain="$runId:reject:admin" \
    action=drop \
    log=no log-prefix="REJECT|" \
    comment="DROP rate-limited connection rejections silently"

/ipv6 firewall filter

add chain="$runId:reject:admin" \
    dst-limit=3/5m,5,src-and-dst-addresses/3h \
    action=reject reject-with=icmp-admin-prohibited \
    log=no log-prefix="REJECT!" \
    comment="Politely REJECT all connections with ICMPv6 response (rated limited to 5/min)"
add chain="$runId:reject:admin" \
    action=drop \
    log=no log-prefix="REJECT|" \
    comment="DROP rate-limited connections rejections silently"
