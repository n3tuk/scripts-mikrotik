# -- templates/parts/firewall-filter-tarpit.rsc.t
{{- /* vim:set ft=routeros: */}}
# Process all connections and packets which have not been accepted, looking for
# spurious requests on any port. If too many are received within a set time from
# each remote host, assume the host is port scanning and block all traffic from
# that host from targeting the public endpoint for up to six months.

{{ template "item" "filter/tarpit chain" }}

/ip firewall filter

add chain="$runId:tarpit" \
    dst-address-type="broadcast" \
    action=drop \
    log=no \
    log-prefix="IGNORE!" \
    comment="DROP all broadcast-type packets silently"

add chain="$runId:tarpit" \
    dst-address-type="multicast" \
    action=drop \
    log=no \
    log-prefix="IGNORE!" \
    comment="DROP all multicast-type packets silently"

add chain="$runId:tarpit" \
    src-address-list="dynamic:tarpit:restricted" \
    action=jump \
    jump-target="$runId:tarpit:drop" \
    comment="TARPIT connections from restricted hosts"

add chain="$runId:tarpit" \
    src-address-list="$runId:tarpit:trusted" \
    action=jump \
    jump-target="$runId:reject" \
    comment="REJECT rather than TARPIT connections from trusted networks"

add chain="$runId:tarpit" \
    dst-limit=5/15m,3,src-and-dst-addresses/15m \
    action=jump \
    jump-target="$runId:reject" \
    log=no \
    log-prefix="REJECT!" \
    comment="Politely REJECT all other connections with ICMP prohibited (max. 5/15min)"

add chain="$runId:tarpit" \
    action=add-src-to-address-list \
    address-list="dynamic:tarpit:restricted" \
    address-list-timeout=26w \
    log=no \
    log-prefix="TARPIT+" \
    comment="Add source host to restricted list if rate limit exceeded"

add chain="$runId:tarpit" \
    action=jump \
    jump-target="$runId:tarpit:drop" \
    comment="TARPIT the connection from the now restricted host"

add chain="$runId:tarpit:drop" \
    protocol=tcp \
    connection-state=new \
    action=tarpit \
    log=no \
    log-prefix="TARPIT!" \
    comment="TARPIT (hold open) new TCP connections from restricted hosts"

add chain="$runId:tarpit:drop" \
    action=drop \
    log=no \
    log-prefix="DROP!" \
    comment="DROP all other packet types from restricted hosts silently"

/ipv6 firewall filter

add chain="$runId:tarpit" \
    dst-address-type="multicast" \
    action=drop \
    log=no \
    log-prefix="IGNORE!" \
    comment="DROP all multicast-type packets silently"

add chain="$runId:tarpit" \
    src-address-list="dynamic:tarpit:restricted" \
    action=jump \
    jump-target="$runId:tarpit:drop" \
    comment="DROP connections from restricted hosts"

add chain="$runId:tarpit" \
    src-address-list="$runId:tarpit:trusted" \
    action=jump \
    jump-target="$runId:reject" \
    comment="REJECT rather than TARPIT connections from trusted networks"

add chain="$runId:tarpit" \
    dst-limit=5/15m,3,src-and-dst-addresses/15m \
    action=jump \
    jump-target="$runId:reject" \
    log=no \
    log-prefix="TARPIT!" \
    comment="Politely REJECT all other connections with ICMP prohibited (max. 5/15min)"

add chain="$runId:tarpit" \
    action=add-src-to-address-list \
    address-list="dynamic:tarpit:restricted" \
    address-list-timeout=26w \
    log=no \
    log-prefix="TARPIT+" \
    comment="Add source host to restricted list if rate limit exceeded"

add chain="$runId:tarpit" \
    action=jump \
    jump-target="$runId:tarpit:drop" \
    comment="DROP the connection from the now restricted host"

add chain="$runId:tarpit:drop" \
    action=drop \
    log=no \
    log-prefix="DROP!" \
    comment="DROP all packets from restricted hosts silently"
