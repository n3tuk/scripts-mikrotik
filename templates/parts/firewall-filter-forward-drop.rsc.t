# -- templates/parts/firewall-filter-forward-drop.rsc.t
{{- /* vim:set ft=routeros: */}}

# Add rules to DROP all traffic from being forwarded as this host is not to be
# configured to route traffic between Layer 3 networks, either as the host is
# being installed, or it is only a client (like a switch or access point).

/ip firewall filter

add chain="$runId:forward" \
    action=drop \
    comment="DROP all connections and packets being forwarded as this is not a routing host"

/ipv6 firewall filter

add chain="$runId:forward" \
    action=drop \
    comment="DROP all connections and packets being forwarded as this is not a routing host"
