# -- templates/parts/firewall-raw-check-bogons.rsc.t
{{- /* vim:set ft=routeros: */}}

{{ template "item" "raw/check:bogons chain" }}

# Process all IP packets to filter out untrusted BOGONs; selected network ranges
# which should not be the source or destination of any IP packet routed over the
# internet or local networks. Permitted internal networks address ranges are
# explicitly not included in this list, rather than overridden, to ensure we
# catch BOGONs in traffic to/from internal network addresses.

/ip firewall raw

add chain="$runId:check:bogons" \
    action=return \
    comment="RETURN (Provisionally ACCEPT) all networks for temporary bypassing of RAW rules (when enabled)"
add chain="$runId:check:bogons" \
    in-interface-list="external" \
    src-address-list="!$runId:bogons:block" \
    action=return \
    disabled=yes \
    comment="RETURN (Provisionally ACCEPT) all packets from non-bogus network addresses via external interfaces"
add chain="$runId:check:bogons" \
    in-interface-list="internal" \
    src-address-list="$runId:bogons:allow" \
    dst-address-list="$runId:bogons:allow" \
    action=return \
    disabled=yes \
    comment="RETURN (Provisionally ACCEPT) all packets between accepted bogon network addresses (i.e. known local private networks)"
add chain="$runId:check:bogons" \
    in-interface-list="internal" \
    src-address-list="$runId:bogons:allow" \
    dst-address-list="$runId:bogons:casting" \
    action=return \
    disabled=yes \
    comment="RETURN (Provisionally ACCEPT) all packets between accepted bogon network addresses and casting (broadcast, multicast) addresses"
add chain="$runId:check:bogons" \
    in-interface-list="internal" \
    src-address-list="$runId:bogons:allow" \
    dst-address-list="!$runId:bogons:block" \
    action=return \
    disabled=yes \
    comment="RETURN (Provisionally ACCEPT) all packets from local private networks to non-bogus network addresses"
add chain="$runId:check:bogons" \
    src-address-list="$runId:bogons:block" \
    action=drop \
    disabled=yes \
    comment="DROP all other packets to bogus network addresses"
add chain="$runId:check:bogons" \
    dst-address-list="$runId:bogons:block" \
    action=drop \
    disabled=yes \
    comment="DROP all other packets from bogus network addresses"

/ipv6 firewall raw

add chain="$runId:check:bogons" \
    action=return \
    comment="RETURN (Provisionally ACCEPT) all networks for temporary bypassing of RAW rules (when enabled)"
add chain="$runId:check:bogons" \
    in-interface-list="external" \
    src-address-list="!$runId:bogons:block" \
    action=return \
    disabled=yes \
    comment="RETURN (Provisionally ACCEPT) all packets from non-bogus network addresses via external interfaces"
add chain="$runId:check:bogons" \
    in-interface-list="internal" \
    src-address-list="$runId:bogons:allow" \
    dst-address-list="$runId:bogons:allow" \
    action=return \
    disabled=yes \
    comment="RETURN (Provisionally ACCEPT) all packets between accepted bogon network addresses (i.e. known local private networks, broadcasts)"
add chain="$runId:check:bogons" \
    in-interface-list="internal" \
    src-address-list="$runId:bogons:allow" \
    dst-address-list="$runId:bogons:casting" \
    action=return \
    disabled=yes \
    comment="RETURN (Provisionally ACCEPT) all packets between accepted bogon network addresses and casting (broadcast, multicast) addresses"
add chain="$runId:check:bogons" \
    in-interface-list="internal" \
    src-address-list="$runId:bogons:allow" \
    dst-address-list="!$runId:bogons:block" \
    action=return \
    disabled=yes \
    comment="RETURN (Provisionally ACCEPT) all packets from local private networks to non-bogus network addresses"
add chain="$runId:check:bogons" \
    src-address-list="$runId:bogons:block" \
    action=drop \
    disabled=yes \
    comment="DROP all other packets to bogus network addresses"
add chain="$runId:check:bogons" \
    dst-address-list="$runId:bogons:block" \
    action=drop \
    disabled=yes \
    comment="DROP all other packets from bogus network addresses"
