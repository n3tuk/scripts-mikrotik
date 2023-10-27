# -- templates/parts/firewall-filter-check-icmp.rsc.t
{{- /* vim:set ft=routeros: */}}
# Process all ICMP connections and packets, both as a general rule to allow all
# echo packets in, out, and through, for diagnosis, and to permit only

{{  template "item" "filter/check:icmp chain" }}

/ip firewall filter

add chain="$runId:check:icmp" \
    protocol=icmp \
    icmp-options=!8:0 \
    action=jump \
    jump-target="$runId:icmp:allowed" \
    comment="ACCEPT selected types of ICMP packets from any host for connection management"

add chain="$runId:check:icmp" \
    protocol=icmp \
    icmp-options=8:0 \
    action=jump \
    jump-target="$runId:icmp:ping" \
    comment="Process and rate-limit Echo Request ICMP packets"

{{  template "item" "filter/icmp:allowed chain" }}

add chain="$runId:icmp:allowed" \
    protocol=icmp \
    icmp-options=0:0 \
    action=accept \
    comment="ACCEPT ICMP Echo Reply type packets"

add chain="$runId:icmp:allowed" \
    protocol=icmp \
    icmp-options=3:0-3 \
    action=accept \
    comment="ACCEPT ICMP Destination (Network/Host/Protocol/Port) Unreachable type packets"

add chain="$runId:icmp:allowed" \
    protocol=icmp \
    icmp-options=3:4 \
    action=accept \
    comment="ACCEPT ICMP Invalid Fragmentation type packets"

add chain="$runId:icmp:allowed" \
    protocol=icmp \
    icmp-options=3:6-7 \
    action=accept \
    comment="ACCEPT ICMP Destination (Network/Host) Unknown type packets"

add chain="$runId:icmp:allowed" \
    protocol=icmp \
    icmp-options=3:9-10 \
    action=accept \
    comment="ACCEPT ICMP Destination (Network/Host) Prohibited type packets"

add chain="$runId:icmp:allowed" \
    protocol=icmp \
    icmp-options=3:13 \
    action=accept \
    comment="ACCEPT ICMP Destination Prohibited type packets"

add chain="$runId:icmp:allowed" \
    protocol=icmp \
    icmp-options=5:0 \
    action=accept \
    comment="ACCEPT ICMP Source Quench type packets"

add chain="$runId:icmp:allowed" \
    protocol=icmp \
    icmp-options=11:0-255 \
    action=accept \
    comment="ACCEPT ICMP Time Exceeded type packets"

add chain="$runId:icmp:allowed" \
    action=drop \
    log=yes \
    log-prefix="ICMP!" \
    comment="DROP and LOG all other ICMP packets"

{{  template "item" "filter/icmp:ping chain" }}

{{-  if (ne (ds "host").export "netinstall") }}

add chain="$runId:icmp:ping" \
    src-address-list="dynamic:icmp:restricted" \
    action=drop \
    log=yes \
    log-prefix="ICMP!" \
    comment="DROP any ICMP Echo Request packets from restricted hosts"

add chain="$runId:icmp:ping" \
    dst-address-list="$runId:icmp:trusted" \
    action=accept \
    comment="ACCEPT any ICMP Echo Request packets to trusted hosts"

add chain="$runId:icmp:ping" \
    src-address-list="$runId:icmp:trusted" \
    action=accept \
    comment="ACCEPT any ICMP Echo Request packets from trusted hosts"

{{- end }}

add chain="$runId:icmp:ping" \
    dst-limit=65/1m,15,src-and-dst-addresses/15m \
    action=accept \
    comment="ACCEPT ICMP Echo Request type packets limited to <65/min"

{{- if (ne (ds "host").export "netinstall") }}

add chain="$runId:icmp:ping" \
    dst-address-list="$runId:icmp:unrestricted" \
    action=accept \
    comment="DROP any ICMP Echo Request packets to unrestricted hosts, rather than add to restricted list"

add chain="$runId:icmp:ping" \
    src-address-list="$runId:icmp:trusted" \
    action=accept \
    comment="DROP any ICMP Echo Request packets from unrestricted hosts, rather than add to restricted list"

add chain="$runId:icmp:ping" \
    action=add-src-to-address-list \
    address-list="dynamic:icmp:restricted" \
    address-list-timeout=26w \
    log=yes \
    log-prefix="ICMP+" \
    comment="Add source host to restricted list if ICMP Echo Request rate limit exceeded"

{{- end }}

add chain="$runId:icmp:ping" \
    action=drop \
    log=yes \
    log-prefix="ICMP!" \
    comment="DROP the ICMP Echo Request packet (without logging)"
