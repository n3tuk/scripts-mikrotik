# -- templates/parts/firewall-filter-forward.rsc.t
{{- /* vim:set ft=routeros: */}}

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
