# -- templates/parts/firewall-filter-forward-chain.rsc.t
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
    action=jump \
    jump-target="$runId:check:icmp" \
    comment="Process all ICMP connections and packets"

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
    action=jump \
    jump-target="$runId:check:dns" \
    comment="Process all DNS connections and packets"

add chain="$runId:forward" \
    protocol=udp \
    dst-port=123 \
    action=jump \
    jump-target="$runId:check:ntp" \
    comment="Process all NTP connections and packets"

add chain="$runId:forward" \
    connection-state=new \
    action=jump \
    jump-target="$runId:forward:ports" \
    comment="Process requests to publicly accessible services from the internal network"

add chain="$runId:forward" \
    src-address-list="$runId:vlan:management" \
    dst-address-list="$runId:https:trusted" \
    protocol=tcp \
    dst-port=80,443 \
    action=accept \
    comment="ACCEPT all HTTP(S) connections to trusted hosts"

add chain="$runId:forward" \
    src-address-list="$runId:internal" \
    connection-state=new \
    action=jump \
    jump-target="$runId:forward:services" \
    comment="Process requests to required services within the internal network"

add chain="$runId:forward" \
    src-address-list="$runId:internal" \
    connection-state=new \
    action=jump \
    jump-target="$runId:forward:rules" \
    comment="Process general rules which should apply forwarding network traffic"

add chain="$runId:forward" \
    src-address-list="$runId:vlans" \
    connection-state=new \
    action=jump \
    jump-target="$runId:forward:vlans" \
    comment="Process rules for local VLANs"

add chain="$runId:forward" \
    action=jump \
    jump-target="$runId:reject" \
    comment="DROP all other connections"

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
    comment="Accept HIP connections and packets on IPv6"

add chain="$runId:forward" \
    dst-address-list="$runId:dns:trusted" \
    action=jump \
    jump-target="$runId:check:dns" \
    comment="Process all DNS connections and packets"

add chain="$runId:forward" \
    protocol=udp \
    dst-port=123 \
    action=jump \
    jump-target="$runId:check:ntp" \
    comment="Process all NTP connections and packets"

add chain="$runId:forward" \
    src-address-list="$runId:vlan:management" \
    dst-address-list="$runId:https:trusted" \
    protocol=tcp \
    dst-port=80,443 \
    action=accept \
    comment="ACCEPT all HTTP(S) connections to trusted hosts"

add chain="$runId:forward" \
    connection-state=new \
    action=jump \
    jump-target="$runId:forward:ports" \
    comment="Process requests to publicly accessible services from the internal network"

add chain="$runId:forward" \
    src-address-list="$runId:internal" \
    connection-state=new \
    action=jump \
    jump-target="$runId:forward:services" \
    comment="Process requests to required services within the internal network"

add chain="$runId:forward" \
    src-address-list="$runId:internal" \
    connection-state=new \
    action=jump \
    jump-target="$runId:forward:rules" \
    comment="Process general rules which should apply forwarding network traffic"

add chain="$runId:forward" \
    src-address-list="$runId:vlans" \
    connection-state=new \
    action=jump \
    jump-target="$runId:forward:vlans" \
    comment="Process rules for local VLANs"

add chain="$runId:forward" \
    action=jump \
    jump-target="$runId:tarpit:process" \
    comment="DROP all other connections and packets"
