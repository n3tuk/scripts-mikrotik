# -- templates/parts/firewall-filter-check-ntp.rsc.t
{{- /* vim:set ft=routeros: */}}
# Provide controls for managing connections to NTP services outside the network.

{{  template "item" "filter/check:ntp chain" }}

/ip firewall filter

add chain="$runId:check:ntp" \
    dst-address-list="$runId:ntp:trusted" \
    action=accept \
    comment="ACCEPT NTP requests to trusted hosts"

add chain="$runId:check:ntp" \
    action=jump \
    jump-target="$runId:reject" \
    comment="REJECT all other NTP requests"

/ipv6 firewall filter

add chain="$runId:check:ntp" \
    dst-address-list="$runId:ntp:trusted" \
    action=accept \
    comment="ACCEPT NTP requests to trusted hosts"

add chain="$runId:check:ntp" \
    action=jump \
    jump-target="$runId:reject" \
    comment="REJECT all other NTP requests"
