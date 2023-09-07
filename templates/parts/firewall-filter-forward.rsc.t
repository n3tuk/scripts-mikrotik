# -- templates/parts/firewall-filter-forward.rsc.t
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

{{  template "item" "filter/forward chain" }}

{{- if (ne (ds "host").export "netinstall") }}
{{-   if (eq (ds "host").type "router") }}

/ip firewall filter

add chain="$runId:forward" \
    connection-state=established,related,untracked \
    action=fasttrack-connection \
    hw-offload=yes \
    comment="ACCEPT packets on established, related, and untracked connections (without acceleration)"
add chain="$runId:forward" \
    connection-state=established,related,untracked \
    action=accept \
    comment="ACCEPT packets on established, related, and untracked connections (without acceleration)"
add chain="$runId:forward" \
    connection-state=invalid \
    action=drop \
    comment="DROP packets from invalid connections"

add chain="$runId:forward" \
    protocol=icmp \
    action=jump jump-target="$runId:check:icmp" \
    comment="Process all ICMP connections and packets"
add chain="$runId:forward" \
    dst-address-list="$runId:dns:trusted" \
    action=jump jump-target="$runId:check:dns" \
    comment="Process all DNS connections and packets"
add chain="$runId:forward" \
    protocol=udp dst-port=123 \
    action=jump jump-target="$runId:check:ntp" \
    comment="Process all NTP connections and packets"

add chain="$runId:forward" \
    connection-state=new connection-nat-state=dstnat \
    action=accept \
    comment="Automatically ACCEPT all DNAT'd connections"

/ipv6 firewall filter

add chain="$runId:forward" \
    connection-state=established,related,untracked \
    action=accept \
    comment="ACCEPT packets on established, related, and untracked connections (without acceleration)"
add chain="$runId:forward" \
    connection-state=invalid \
    action=drop \
    comment="DROP packets from invalid connections"

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

add chain="$runId:forward" \
    src-address-list="$runId:vlans" connection-state=new \
    action=jump jump-target="$runId:forward:vlans" \
    comment="Process all connections from local VLAN networks"
add chain="$runId:forward" \
    src-address-list="$runId:internal" connection-state=new \
    action=jump jump-target="$runId:forward:internal" \
    comment="Process all connections from internal/remote networks"

{{  template "item" "filter/forward:vlans chain" }}

/ip firewall filter

add chain="$runId:forward" \
    src-address-list="$runId:vlans" connection-state=new \
    action=jump jump-target="$runId:forward:vlans" \
    comment="Process all connections from local VLAN networks"

add chain="$runId:forward:vlans" \
    action=accept \
    comment="ACCEPT all connections"

/ipv6 firewall filter

add chain="$runId:forward" \
    src-address-list="$runId:vlans" connection-state=new \
    action=jump jump-target="$runId:forward:vlans" \
    comment="Process all connections from local VLAN networks"

add chain="$runId:forward:vlans" \
    action=accept \
    comment="ACCEPT all connections"

{{  template "item" "filter/forward:internal chain" }}

/ip firewall filter

add chain="$runId:forward" \
    src-address-list="$runId:internal" connection-state=new \
    action=jump jump-target="$runId:forward:internal" \
    comment="Process all connections from internal networks"

add chain="$runId:forward:internal" \
    action=accept \
    comment="ACCEPT all connections"

/ipv6 firewall filter

add chain="$runId:forward" \
    src-address-list="$runId:internal" connection-state=new \
    action=jump jump-target="$runId:forward:internal" \
    comment="Process all connections from internal networks"
add chain="$runId:forward" \
    src-address-list="!$runId:internal" connection-state=new \
    action=jump jump-target="$runId:forward:external" \
    comment="Process all connections from external networks"

add chain="$runId:forward:internal" \
    action=accept \
    comment="ACCEPT all connections"

{{- if (gt (len $ports) 0) }}

# Configure port forwarding rules for IPv6, explicitly allowing selected traffic
# from external networks into internal networks over the router
{{-   range $port := $ports }}

add chain="$runId:forward:external" \
    in-interface={{ $port.interface }} \
    dst-address={{ $port.ipv6 }} \
{{-     if (has $port "protocol") }}
    protocol={{ $port.protocol }} \
{{-     end }}
    dst-port={{ $port.port }} \
    action=accept \
    comment="{{ if (has $port "comment") }}{{ $port.comment }}{{ end }}"
{{-   end }}
{{- end }}

add chain="$runId:forward:external" \
    action=jump jump-target="$runId:tarpit:drop" \
    comment="DROP all other connections"

/ip firewall filter

add chain="$runId:forward" \
    action=jump jump-target="$runId:reject:admin" \
    comment="DROP all packets to prevent forwarding during installation and configuration"

/ipv6 firewall filter

add chain="$runId:forward" \
    action=jump jump-target="$runId:reject:admin" \
    comment="DROP all packets to prevent forwarding during installation and configuration"

{{-   else }}

# Add temporary rules to block all forwarded traffic when the host is not
# configured with a firewall. These rules will be cleared out when the final
# firewall is configured.

/ip firewall filter

add chain="$runId:forward" \
    action=drop \
    comment="DROP all connections and packets being forwarded as this is not a routing host"

/ipv6 firewall filter

add chain="$runId:forward" \
    action=drop \
    comment="DROP all connections and packets being forwarded as this is not a routing host"

{{-   end }}
{{- else }}

/ip firewall filter

add chain="$runId:forward" \
    action=drop \
    comment="DROP all connections and packets being forwarded as this not yet configured"

/ipv6 firewall filter

add chain="$runId:forward" \
    action=drop \
    comment="DROP all connections and packets being forwarded as this not yet configured"

{{- end }}

{{  template "item" "filter/forward jump" }}

/ip firewall filter

add chain="forward" \
    action=jump jump-target="$runId:forward" \
    comment="Process all packets passing through the FORWARD chain"

/ipv6 firewall filter

add chain="forward" \
    action=jump jump-target="$runId:forward" \
    comment="Process all packets passing through the FORWARD chain"
