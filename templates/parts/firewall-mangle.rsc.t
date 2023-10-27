# -- templates/parts/firewall-mangle.rsc.t
{{- /* vim:set ft=routeros: */}}
# The mangle table for the firewall provides the ability to alter packets being
# processed by the firewall (for example, to manage TCP MSS values on new
# connections).

{{  template "component" "mangle table" }}

# -> forward
#  - ptmu clamping (ipv6)

/ipv6 firewall mangle

{{  template "item" "mangle/forward jump" }}

add chain="forward" \
    action=jump jump-target="$runId:forward" \
    comment="Process all packets arriving via the FORWARD chain"

{{  template "item" "mangle/forward chain" }}

add chain="$runId:forward" \
    src-address-list="$runId:vlans" \
    dst-address-list="!$runId:vlans" \
    protocol=tcp \
    tcp-flags=syn \
    action=change-mss \
    new-mss=clamp-to-pmtu \
    passthrough=yes \
    comment="Ensure all initial IPv6 packets leaving this network have their MTU clamped"

{{  template "parts/firewall-cleanup.rsc.t" (coll.Slice "mangle" "prerouting" "input" "forward" "output" "postrouting") -}}
