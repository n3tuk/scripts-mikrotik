# -- templates/parts/firewall-raw-check-tcp.rsc.t
{{- /* vim:set ft=routeros: */}}

{{ template "item" "raw/check:tcp chain" }}

# Bad TCP Packet Processing
# Ensure that any TCP packets receive have the right combination of settings.

/ip firewall raw

add chain="$runId:check:tcp" \
    protocol=tcp tcp-flags=!fin,!syn,!rst,!ack \
    action=drop \
    comment="Filter packets with invalid TCP flags"
add chain="$runId:check:tcp" \
    protocol=tcp tcp-flags=fin,syn \
    action=drop \
    comment="Filter packets with invalid TCP flags"
add chain="$runId:check:tcp" \
    protocol=tcp tcp-flags=fin,rst \
    action=drop \
    comment="Filter packets with invalid TCP flags"
add chain="$runId:check:tcp" \
    protocol=tcp tcp-flags=fin,!ack \
    action=drop \
    comment="Filter packets with invalid TCP flags"
add chain="$runId:check:tcp" \
    protocol=tcp tcp-flags=fin,urg \
    action=drop \
    comment="Filter packets with invalid TCP flags"
add chain="$runId:check:tcp" \
    protocol=tcp tcp-flags=syn,rst \
    action=drop \
    comment="Filter packets with invalid TCP flags"
add chain="$runId:check:tcp" \
    protocol=tcp tcp-flags=rst,urg \
    action=drop \
    comment="Filter packets with invalid TCP flags"
add chain="$runId:check:tcp" \
    protocol=tcp port=0 \
    action=drop \
    comment="Drop TCP packets to port 0"

/ipv6 firewall raw

add chain="$runId:check:tcp" \
    protocol=tcp tcp-flags=!fin,!syn,!rst,!ack \
    action=drop \
    comment="Filter packets with invalid TCP flags"
add chain="$runId:check:tcp" \
    protocol=tcp tcp-flags=fin,syn \
    action=drop \
    comment="Filter packets with invalid TCP flags"
add chain="$runId:check:tcp" \
    protocol=tcp tcp-flags=fin,rst \
    action=drop \
    comment="Filter packets with invalid TCP flags"
add chain="$runId:check:tcp" \
    protocol=tcp tcp-flags=fin,!ack \
    action=drop \
    comment="Filter packets with invalid TCP flags"
add chain="$runId:check:tcp" \
    protocol=tcp tcp-flags=fin,urg \
    action=drop \
    comment="Filter packets with invalid TCP flags"
add chain="$runId:check:tcp" \
    protocol=tcp tcp-flags=syn,rst \
    action=drop \
    comment="Filter packets with invalid TCP flags"
add chain="$runId:check:tcp" \
    protocol=tcp tcp-flags=rst,urg \
    action=drop \
    comment="Filter packets with invalid TCP flags"
add chain="$runId:check:tcp" \
    protocol=tcp port=0 \
    action=drop \
    comment="Drop TCP packets to port 0"
