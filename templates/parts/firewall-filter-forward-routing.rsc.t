# -- templates/parts/firewall-filter-forward-routing.rsc.t
{{- /* vim:set ft=routeros: */}}

{{- $ports := coll.Slice }}
{{- if (and (has (ds "network").firewall "forwarding")
            (has (ds "network").firewall.forwarding "ports")) }}
{{-   range $port := (ds "network").firewall.forwarding.ports }}
{{-     if (has $port "ipv6") }}
{{-       $ports = $ports | append $port }}
{{-     end }}
{{-   end }}
{{- end }}

# Add rules to the forward chain which allows the routing of traffic between
# Layer 3 networks, defined based on the network configuration.

/ip firewall filter

add chain="$runId:forward" \
    protocol=icmp \
    action=jump jump-target="$runId:check:icmp" \
    comment="Process all ICMP connections and packets"

add chain="$runId:forward" \
    connection-state=established,related,untracked \
    action=fasttrack-connection \
    hw-offload=yes \
    comment="ACCEPT packets on established, related, and untracked connections (with acceleration)"
add chain="$runId:forward" \
    connection-state=established,related,untracked \
    action=accept \
    comment="ACCEPT packets on established, related, and untracked connections (without acceleration, where not supported)"
add chain="$runId:forward" \
    connection-state=invalid \
    action=drop \
    comment="DROP packets from invalid connections"

add chain="$runId:forward" \
    dst-address-list="$runId:dns:trusted" \
    action=jump jump-target="$runId:check:dns" \
    comment="Process all DNS connections and packets"
add chain="$runId:forward" \
    protocol=udp dst-port=123 \
    action=jump jump-target="$runId:check:ntp" \
    comment="Process all NTP connections and packets"

/ipv6 firewall filter

add chain="$runId:forward" \
    protocol=icmpv6 \
    hop-limit=equal:1 \
    action=drop \
    comment="DROP all ICMPv6 with hop-limit set to 1 before processing"
add chain="$runId:forward" \
    protocol=icmpv6 \
    action=accept \
    comment="ACCEPT all ICMPv6 connections and packets"

add chain="$runId:forward" \
    connection-state=established,related,untracked \
    action=accept \
    comment="ACCEPT packets on established, related, and untracked connections (without acceleration)"
add chain="$runId:forward" \
    connection-state=invalid \
    action=drop \
    comment="DROP packets from invalid connections"

add chain="$runId:forward" \
    protocol=139 \
    action=accept \
    comment="defconf: accept HIP"

add chain="$runId:forward" \
    dst-address-list="$runId:dns:trusted" \
    action=jump jump-target="$runId:check:dns" \
    comment="Process all DNS connections and packets"
add chain="$runId:forward" \
    protocol=udp dst-port=123 \
    action=jump jump-target="$runId:check:ntp" \
    comment="Process all NTP connections and packets"
