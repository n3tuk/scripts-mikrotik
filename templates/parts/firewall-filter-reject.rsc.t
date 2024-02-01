# -- templates/parts/firewall-filter-reject.rsc.t
{{- /* vim:set ft=routeros: */}}
# Create a chain which provides the ability to standardise the processing of
# connections and packets which are to be rejected by the firewall, including
# rate-limited controls for the hosts on each side of the connection.

{{ template "item" "filter/reject chain" }}

/ip firewall filter

{{- /*
# Don't worry about rate-limiting controls when building the netinstall-based
# firewalls. We'll just configure all the packets to be dropped silently until a
# full firewall is installed.
*/}}

{{- if (ne (ds "host").export "netinstall") }}

add chain="$runId:reject" \
    dst-address-type="broadcast" \
    action=drop \
    log=no \
    log-prefix="IGNORE!" \
    comment="DROP all broadcast-type packets silently"

add chain="$runId:reject" \
    dst-address-type="multicast" \
    action=drop \
    log=no \
    log-prefix="IGNORE!" \
    comment="DROP all multicast-type packets silently"

add chain="$runId:reject" \
    dst-limit=3/5m,5,src-and-dst-addresses/3h \
    action=reject \
    reject-with=icmp-admin-prohibited \
    log=no \
    log-prefix="REJECT!" \
    comment="Politely REJECT all connections with ICMP response (rated limited to 5/min)"

{{- end }}

add chain="$runId:reject" \
    action=drop \
    log=no \
    log-prefix="DROP!" \
    comment="DROP all other connections and packets silently"

/ipv6 firewall filter

add chain="$runId:reject" \
    dst-address-type="multicast" \
    action=drop \
    log=no \
    log-prefix="IGNORE!" \
    comment="DROP all multicast-type packets silently"

{{- if (ne (ds "host").export "netinstall") }}

add chain="$runId:reject" \
    dst-limit=3/5m,5,src-and-dst-addresses/3h \
    action=reject \
    reject-with=icmp-admin-prohibited \
    log=no \
    log-prefix="REJECT!" \
    comment="Politely REJECT all connections with ICMPv6 response (rated limited to 5/min)"

{{- end }}

add chain="$runId:reject" \
    action=drop \
    log=no \
    log-prefix="DROP!" \
    comment="DROP all other connections and packets silently"
