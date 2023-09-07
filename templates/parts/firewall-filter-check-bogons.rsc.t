# -- templates/parts/firewall-filter-check-bogons.rsc.t
{{- /* vim:set ft=routeros: */}}

{{ template "item" "filter/check:bogons chain" }}

# Process all IP packets to filter out untrusted BOGONs; selected network ranges
# which should not be the source or destination of any IP packet routed over the
# internet or local networks. Permitted internal networks address ranges are
# explicitly not included in this list, rather than overridden, to ensure we
# catch BOGONs in traffic to/from internal network addresses.

/ip firewall filter

add chain="$runId:check:bogons" \
    src-address-list="$runId:bogons:allow" \
    dst-address-list="$runId:bogons:allow" \
    action=return \
    disabled=yes \
    comment="BOGONS: RETURN (Provisionally ALLOW) all packets between accepted bogus network addresses (i.e. known local private networks)"
add chain="$runId:check:bogons" \
    src-address-list="$runId:bogons:allow" \
    dst-address-list="!$runId:bogons:block" \
    action=return \
    disabled=yes \
    comment="BOGONS: RETURN (Provisionally ALLOW) all packets from local private networks to non-bogus network addresses"
add chain="$runId:check:bogons" \
    src-address-list="$runId:bogons:block" \
    dst-address-list="!$runId:bogons:allow" \
    action=return \
    disabled=yes \
    comment="BOGONS: RETURN (Provisionally ALLOW) all packets from non-bogus network addresses to local private networks"
add chain="$runId:check:bogons" \
    src-address-list="$runId:bogons:block" \
    action=jump jump-target="$runId:reject:admin" \
    disabled=yes \
    comment="BOGONS: REJECT all other packets to bogus network addresses"
add chain="$runId:check:bogons" \
    dst-address-list="$runId:bogons:block" \
    action=jump jump-target="$runId:reject:admin" \
    disabled=yes \
    comment="BOGONS: REJECT all other packets to bogus network addresses"

/ipv6 firewall raw

add chain="$runId:check:bogons" \
    src-address-list="$runId:bogons:allow" \
    dst-address-list="$runId:bogons:allow" \
    action=return \
    disabled=yes \
    comment="BOGONS: RETURN (Provisionally ALLOW) all packets between accepted bogus network addresses (i.e. known local private networks)"
add chain="$runId:check:bogons" \
    src-address-list="$runId:bogons:allow" \
    dst-address-list="!$runId:bogons:block" \
    action=return \
    disabled=yes \
    comment="BOGONS: RETURN (Provisionally ALLOW) all packets from local private networks to non-bogus network addresses"
add chain="$runId:check:bogons" \
    src-address-list="$runId:bogons:block" \
    dst-address-list="!$runId:bogons:allow" \
    action=return \
    disabled=yes \
    comment="BOGONS: RETURN (Provisionally ALLOW) all packets from non-bogus network addresses to local private networks"
add chain="$runId:check:bogons" \
    src-address-list="$runId:bogons:block" \
    action=jump jump-target="$runId:reject:admin" \
    disabled=yes \
    comment="BOGONS: REJECT all other packets to bogus network addresses"
add chain="$runId:check:bogons" \
    dst-address-list="$runId:bogons:block" \
    action=jump jump-target="$runId:reject:admin" \
    disabled=yes \
    comment="BOGONS: REJECT all other packets to bogus network addresses"
