# -- templates/parts/firewall-filter-forward-reject.rsc.t
{{- /* vim:set ft=routeros: */}}

# Add rules to DROP all traffic from being forwarded as this host is not to be
# configured to route traffic between Layer 3 networks, either as the host is
# being installed, or it is only a client (like a switch or access point).

/ip firewall filter

add chain="$runId:forward" \
    action=jump jump-target="$runId:admin:reject" \
    comment="DROP all other connections"

/ipv6 firewall filter

add chain="$runId:forward" \
    action=jump jump-target="$runId:tarpit:drop" \
    comment="DROP all other connections"
