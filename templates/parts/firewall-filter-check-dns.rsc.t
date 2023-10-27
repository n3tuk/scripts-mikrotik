# -- templates/parts/firewall-filter-check-dns.rsc.t
{{- /* vim:set ft=routeros: */}}
# Provide controls for managing connections to DNS services outside the network,
# permitting access using standard DNS protocols over UDP and TCP, as well as
# DNS over TLS and DNS over HTTPS services too. In the latter case, the rules
# are careful not to block other HTTPS connections.

{{  template "item" "filter/check:dns chain" }}

/ip firewall filter

add chain="$runId:check:dns" \
    dst-address-list="$runId:dns:trusted" \
    protocol=udp \
    dst-port=53 \
    action=accept \
    comment="ACCEPT DNS requests on udp/53 via trusted hosts"

add chain="$runId:check:dns" \
    protocol=udp \
    dst-port=53 \
    action=jump \
    jump-target="$runId:reject" \
    comment="REJECT all other DNS requests on udp/53"

add chain="$runId:check:dns" \
    dst-address-list="$runId:dns:trusted" \
    protocol=tcp \
    dst-port=53 \
    action=accept \
    comment="ACCEPT DNS requests on tcp/53 via trusted hosts"

add chain="$runId:check:dns" \
    protocol=tcp \
    dst-port=53 \
    action=jump \
    jump-target="$runId:reject" \
    comment="REJECT all other DNS requests on tcp/53"

add chain="$runId:check:dns" \
    dst-address-list="$runId:dns:trusted" \
    protocol=tcp \
    dst-port=853 \
    action=accept \
    comment="ACCEPT DNS over TLS requests on tcp/853 via trusted hosts"

add chain="$runId:check:dns" \
    protocol=tcp \
    dst-port=853 \
    action=jump \
    jump-target="$runId:reject" \
    comment="REJECT all other DNS over TLS requests on tcp/853"

# There is no REJECT for this port as it is HTTPS, and there may be other rules
# and controls associated with it, as such it just allow requests to these
# trusted endpoints as an explicit allow, regardless of other rules around HTTPS
add chain="$runId:check:dns" \
    dst-address-list="$runId:dns:trusted" \
    protocol=tcp \
    dst-port=443 \
    action=accept \
    comment="ACCEPT DNS requests over HTTPS on tcp/443 via trusted hosts"

# Implicit RETURN

/ipv6 firewall filter

add chain="$runId:check:dns" \
    dst-address-list="$runId:dns:trusted" \
    protocol=udp \
    dst-port=53 \
    action=accept \
    comment="ACCEPT DNS requests on udp/53 via trusted hosts"

add chain="$runId:check:dns" \
    protocol=udp \
    dst-port=53 \
    action=jump \
    jump-target="$runId:reject" \
    comment="REJECT all other DNS requests on udp/53"

add chain="$runId:check:dns" \
    dst-address-list="$runId:dns:trusted" \
    protocol=tcp \
    dst-port=53 \
    action=accept \
    comment="ACCEPT DNS requests on tcp/53 via trusted hosts"

add chain="$runId:check:dns" \
    protocol=tcp \
    dst-port=53 \
    action=jump \
    jump-target="$runId:reject" \
    comment="REJECT all other DNS requests on tcp/53"

add chain="$runId:check:dns" \
    dst-address-list="$runId:dns:trusted" \
    protocol=tcp \
    dst-port=853 \
    action=accept \
    comment="ACCEPT DNS over TLS requests on tcp/853 via trusted hosts"

add chain="$runId:check:dns" \
    protocol=tcp \
    dst-port=853 \
    action=jump \
    jump-target="$runId:reject" \
    comment="REJECT all other DNS over TLS requests on tcp/853"

# As above, there is no REJECT for this port as it is HTTPS
add chain="$runId:check:dns" \
    dst-address-list="$runId:dns:trusted" \
    protocol=tcp \
    dst-port=443 \
    action=accept \
    comment="ACCEPT DNS requests over HTTPS on tcp/443 via trusted hosts"

# Implicit RETURN
