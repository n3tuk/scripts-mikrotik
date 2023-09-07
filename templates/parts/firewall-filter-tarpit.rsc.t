# -- templates/parts/firewall-filter-tarpit.rsc.t
{{- /* vim:set ft=routeros: */}}

{{ template "item" "filter/tarpit chain" }}

# Process all new connections looking for spurious requests on restricted ports.
# If too many are received within a set time, assume the host is port scanning
# and block all traffic from that host from targeting the public endpoint.

/ip firewall filter

add chain="$runId:tarpit:process" \
    src-address-list="dynamic:tarpit:restricted" \
    action=jump jump-target="$runId:tarpit:drop" \
    comment="TARPIT (hold open) connections from restricted hosts"
add chain="$runId:tarpit:process" \
    src-address-list="$runId:tarpit:trusted" \
    action=jump jump-target="$runId:reject:admin" \
    comment="REJECT rather than TARPIT connections from trusted networks"
add chain="$runId:tarpit:process" \
    dst-limit=5/15m,3,src-and-dst-addresses/15m \
    action=jump jump-target="$runId:reject:admin" \
    log=no log-prefix="TARPIT!" \
    comment="Politely REJECT all other connections with ICMP prohibited (max. 5/15min)"
add chain="$runId:tarpit:process" \
    address-list="dynamic:tarpit:restricted" address-list-timeout=26w \
    action=add-src-to-address-list \
    log=yes log-prefix="TARPIT+" \
    comment="Add source host to restricted list if rate limit exceeded"
add chain="$runId:tarpit:process" \
    action=jump jump-target="$runId:tarpit:drop" \
    comment="TARPIT (hold open) the connection from the now restricted host"

add chain="$runId:tarpit:drop" \
    protocol=tcp connection-state=new \
    action=tarpit \
    comment="TARPIT (hold open) new TCP connections from restricted hosts"
add chain="$runId:tarpit:drop" \
    action=drop \
    comment="DROP all other packet types from restricted hosts silently"

/ipv6 firewall filter

add chain="$runId:tarpit:process" \
    src-address-list="dynamic:tarpit:restricted" \
    action=jump jump-target="$runId:tarpit:drop" \
    comment="DROP connections from restricted hosts"
add chain="$runId:tarpit:process" \
    src-address-list="$runId:tarpit:trusted" \
    action=jump jump-target="$runId:reject:admin" \
    comment="REJECT rather than TARPIT connections from trusted networks"
add chain="$runId:tarpit:process" \
    dst-limit=5/15m,3,src-and-dst-addresses/15m \
    action=jump jump-target="$runId:reject:admin" \
    log=no log-prefix="TARPIT!" \
    comment="Politely REJECT all other connections with ICMP prohibited (max. 5/15min)"
add chain="$runId:tarpit:process" \
    address-list="dynamic:tarpit:restricted" address-list-timeout=26w \
    action=add-src-to-address-list \
    log=yes log-prefix="TARPIT+" \
    comment="Add source host to restricted list if rate limit exceeded"
add chain="$runId:tarpit:process" \
    action=jump jump-target="$runId:tarpit:drop" \
    comment="DROP the connection from the now restricted host"

add chain="$runId:tarpit:drop" \
    action=drop \
    comment="DROP all packets from restricted hosts silently"
