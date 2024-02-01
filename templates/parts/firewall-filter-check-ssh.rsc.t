# -- templates/parts/firewall-filter-ssh-check.rsc.t
{{- /* vim:set ft=routeros: */}}
# Create a multi-stage set of rules which manages access to the SSH service from
# external hosts to this host. The connections are brokwn down as follows:
# 1. If the remote host is in the ssh:trusted Address List, all connection
#    attempts will be ACCEPT'd without further checks nor rate limiting.
# 2. If the remote host is not part of the ssh:allowed list, block any
#    connections from it to the SSH service on this host.
# 3. If the host has previously exceeded the rate limit, and as such has been
#    added to the ssh:restricted Address List, block it from connecting to the
#    SSH service using TARPIT (if possible).
# 4. The connection by the remote host to the SSH service will now be permitted
#    if the host is in ssh:allowed list but not in the ssh:restricted list, and
#    does not exceeded the permitted rate limit for new connections (i.e. more
#    three new connections within less than 15 minutes).
# 5. If the host is within the ssh:unrestricted Address List, the connection
#    will be DROP'd if exceeding the rate limit, but will not be added to the
#    ssh:restricted list to semi-permanently block it.
# 6. For all other hosts, the connection will be DROP'd if exceeding the rate
#    limited and the host will be added to the ssh:restricted list which will
#    block all future connection attempts for the specified period (six months
#    normally).

{{ template "item" "filter/check:ssh chain" }}

/ip firewall filter

add chain="$runId:check:ssh" \
    src-address-list="$runId:ssh:trusted" \
    action=accept \
    comment="Always ACCEPT connections from trusted hosts"

add chain="$runId:check:ssh" \
    src-address-list="!$runId:ssh:allowed" \
    action=drop \
    log=no \
    log-prefix="DROP>" \
    comment="DROP all connections and packets not from allowed networks"

add chain="$runId:check:ssh" \
    src-address-list="dynamic:ssh:restricted" \
    connection-state=new \
    protocol=tcp \
    action=tarpit \
    log=no \
    log-prefix="TARPIT!" \
    comment="TARPIT (hold open) new SSH connections from restricted hosts"

add chain="$runId:check:ssh" \
    src-address-list="dynamic:ssh:restricted" \
    action=drop \
    log=no \
    log-prefix="DROP!" \
    comment="DROP all other SSH packets from restricted hosts"

add chain="$runId:check:ssh" \
    dst-limit=3/15m,3,src-address/1h \
    connection-state=new \
    action=accept \
    comment="ACCEPT new connections from any host rate limited to <3/15m"

add chain="$runId:check:ssh" \
    src-address-list="$runId:ssh:unrestricted" \
    action=drop \
    log=no \
    log-prefix="DROP|" \
    comment="DROP, but do not restrict, unrestricted hosts if the rate limit is exceeded"

add chain="$runId:check:ssh" \
    connection-state=new \
    action=add-src-to-address-list \
    address-list="dynamic:ssh:restricted" \
    address-list-timeout=26w \
    log=no \
    log-prefix="TARPIT+" \
    comment="ADD the source host to restricted list if the rate limit is exceeded"

add chain="$runId:check:ssh" \
    action=drop \
    log=no \
    log-prefix="DROP!" \
    comment="DROP all other SSH connections and packets"

/ipv6 firewall filter

add chain="$runId:check:ssh" \
    src-address-list="$runId:ssh:trusted" \
    action=accept \
    comment="Always ACCEPT connections from trusted hosts"

add chain="$runId:check:ssh" \
    src-address-list="!$runId:ssh:allowed" \
    action=drop \
    log=no \
    log-prefix="DROP>" \
    comment="DROP all connections and packets not from allowed networks"

add chain="$runId:check:ssh" \
    src-address-list="dynamic:ssh:restricted" \
    action=drop \
    log=no \
    log-prefix="DROP!" \
    comment="DROP all SSH packets from restricted hosts"

add chain="$runId:check:ssh" \
    dst-limit=3/15m,3,src-address/1h \
    connection-state=new \
    action=accept \
    comment="ACCEPT new connections from any host rate limited to <3/15m"

add chain="$runId:check:ssh" \
    src-address-list="$runId:ssh:unrestricted" \
    action=drop \
    log=no \
    log-prefix="DROP|" \
    comment="DROP, but do not restrict, unrestricted hosts if the rate limit is exceeded"

add chain="$runId:check:ssh" \
    connection-state=new \
    action=add-src-to-address-list \
    address-list="dynamic:ssh:restricted" \
    address-list-timeout=26w \
    log=no \
    log-prefix="DROP+" \
    comment="ADD the source host to restricted list if the rate limit is exceeded"

add chain="$runId:check:ssh" \
    action=drop \
    log=no \
    log-prefix="DROP!" \
    comment="DROP all other SSH connections and packets"
