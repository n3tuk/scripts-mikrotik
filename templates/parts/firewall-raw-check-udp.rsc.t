# -- templates/parts/firewall-raw-check-udp.rsc.t
{{- /* vim:set ft=routeros: */}}

{{ template "item" "raw/check:udp chain" }}

# Bad UDP Packet Processing
# Ensure that any UDP packets receive have the right combination of settings.

/ip firewall raw

add chain="$runId:check:udp" \
    protocol=udp port=0 \
    action=drop \
    comment="Drop UDP packets to port 0"

/ipv6 firewall raw

add chain="$runId:check:udp" \
    protocol=udp port=0 \
    action=drop \
    comment="Drop UDP packets to port 0"
