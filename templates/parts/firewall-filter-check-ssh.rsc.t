# -- templates/parts/firewall-filter-ssh-check.rsc.t
{{- /* vim:set ft=routeros: */}}

{{ template "item" "filter/check:ssh chain" }}

# Create a multi-stage set of rules which manages access to the SSH service from
# external hosts to this host.

/ip firewall filter

add chain="$runId:check:ssh" \
    src-address-list="$runId:ssh:trusted" \
    action=accept \
    comment="Always ACCEPT connections from trusted hosts"
add chain="$runId:check:ssh" \
    src-address-list="dynamic:ssh:restricted" \
    connection-state=new \
    protocol=tcp \
    action=tarpit \
    log=no log-prefix="SSH~" \
    comment="TARPIT (hold open) new TCP connections from restricted hosts"
add chain="$runId:check:ssh" \
    src-address-list="dynamic:ssh:restricted" \
    action=drop \
    comment="DROP all other packets from restricted hosts"
add chain="$runId:check:ssh" \
    src-address-list="!$runId:ssh:allowed" \
    action=drop \
    comment="DROP all other packets from allowed networks"
add chain="$runId:check:ssh" \
    dst-limit=3/15m,3,src-address/1h \
    connection-state=new \
    action=accept \
    comment="ACCEPT connections (as connection-state=new) from any host if <3/15m"
add chain="$runId:check:ssh" \
    src-address-list="$runId:ssh:controlled" \
    action=drop \
    comment="DROP, but do not restrict, hosts within controlled networks"
add chain="$runId:check:ssh" \
    connection-state=new \
    action=add-src-to-address-list \
    address-list="dynamic:ssh:restricted" address-list-timeout=26w \
    log=yes log-prefix="SSH+" \
    comment="Add source host to restricted list if rate limit exceeded"
add chain="$runId:check:ssh" \
    action=drop \
    comment="DROP all other connections"

/ipv6 firewall filter

add chain="$runId:check:ssh" \
    src-address-list="$runId:ssh:trusted" \
    action=accept \
    comment="Always ACCEPT connections from trusted hosts"
add chain="$runId:check:ssh" \
    src-address-list="dynamic:ssh:restricted" \
    action=drop \
    comment="DROP all SSH packets from restricted hosts"
add chain="$runId:check:ssh" \
    src-address-list="!$runId:ssh:allowed" \
    action=drop \
    comment="DROP all other packets from allowed networks"
add chain="$runId:check:ssh" \
    dst-limit=3/15m,3,src-address/1h \
    connection-state=new \
    action=accept \
    comment="ACCEPT connections (as connection-state=new) from any host if <3/15m"
add chain="$runId:check:ssh" \
    src-address-list="$runId:ssh:controlled" \
    action=drop \
    comment="DROP, but do not restrict, hosts within controlled networks"
add chain="$runId:check:ssh" \
    connection-state=new \
    action=add-src-to-address-list \
    address-list="dynamic:ssh:restricted" address-list-timeout=27w \
    log=yes log-prefix="SSH+" \
    comment="Add source host to restricted list if rate limit exceeded"
add chain="$runId:check:ssh" \
    action=drop \
    comment="DROP all other connections"
