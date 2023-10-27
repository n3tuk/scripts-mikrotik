# -- templates/parts/firewall-raw-prerouting.rsc.t
{{- /* vim:set ft=routeros: */}}
# Configure the prerouting chain to run the network and protocol checks needed
# to verify the packets processed by this device so we can drop anything invalid
# before connection tracking is added for the packets.

{{ template "item" "raw/prerouting jump" }}

/ip firewall raw

add chain="prerouting" \
    action=jump \
    jump-target="$runId:prerouting" \
    comment="Process all packets arriving via the PREROUTING chain"

/ipv6 firewall raw

add chain="prerouting" \
    action=jump \
    jump-target="$runId:prerouting" \
    comment="Process all packets arriving via the PREROUTING chain"

{{ template "item" "raw/prerouting chain" }}

/ip firewall raw

add chain="$runId:prerouting" \
    action=accept \
    disabled=yes \
    comment="ACCEPT all for temporary bypassing of RAW rules (when enabled)"

add chain="$runId:prerouting" \
    in-interface-list=internal \
    src-address=0.0.0.0 \
    dst-address=255.255.255.255 \
    protocol=udp \
    src-port=68 \
    dst-port=67 \
    action=accept \
    comment="ACCEPT DHCP discover packages"

add chain="$runId:prerouting" \
    action=jump \
    jump-target="$runId:check:bogons" \
    comment="Process packets for bogus network addresses"

add chain="$runId:prerouting" \
    protocol=tcp \
    action=jump \
    jump-target="$runId:check:tcp" \
    comment="Check TCP packets"

add chain="$runId:prerouting" \
    protocol=udp \
    action=jump \
    jump-target="$runId:check:udp" \
    comment="Check UDP packets"

add chain="$runId:prerouting" \
    action=accept \
    comment="ACCEPT all other packets"

/ipv6 firewall raw

add chain="$runId:prerouting" \
    action=accept \
    disabled=yes \
    comment="ACCEPT all for temporary bypassing of RAW rules (when enabled)"

add chain="$runId:prerouting" \
    action=jump \
    jump-target="$runId:check:bogons" \
    comment="Process packets for bogus network addresses"

add chain="$runId:prerouting" \
    protocol=tcp \
    action=jump \
    jump-target="$runId:check:tcp" \
    comment="Check TCP packets"

add chain="$runId:prerouting" \
    protocol=udp \
    action=jump \
    jump-target="$runId:check:udp" \
    comment="Check UDP packets"

add chain="$runId:prerouting" \
    action=accept \
    comment="ACCEPT all other packets"
