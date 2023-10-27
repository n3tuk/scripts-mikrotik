# -- templates/parts/firewall-filter-forward.rsc.t
{{- /* vim:set ft=routeros: */}}
# Process all traffic which is not destined for this host, limiting what is
# accepted to the minimum needed between local networks, and taking into account
# traffic coming in from internal networks or external networks, for both IPv4
# and IPv6.

{{  template "parts/firewall-filter-forward-settings.rsc.t" }}

{{  template "item" "filter/forward jump" }}

# -> forward
#  > check:icmp
#    > check:icmp:allowed
#      - accept allowed icmp packets
#    > check:icmp:ping
#      - drop restricted hosts
#      - rate limit allowed icmp echo packets
#      - add hosts to restricted list
#      - drop excess icmp echo packets
#    - drop all other icmp packets
#  + established/invalid checks (with fasttrack)
#  > check:dns
#    - accept dns requests to selected hosts
#    > reject
#      - drop with icmp-admin-prohibited
#  > check:ntp
#    - accept ntp requests to selected hosts
#    > reject
#      - drop with icmp-admin-prohibited
#  (all internal firewall rules should go here)
#  > evaluate requests on per-vlan basis
#    - per-vlan rules
#  + reject all other packets

/ip firewall filter

add chain="forward" \
    action=jump jump-target="$runId:forward" \
    comment="Process all packets passing through the FORWARD chain"

/ipv6 firewall filter

add chain="forward" \
    action=jump jump-target="$runId:forward" \
    comment="Process all packets passing through the FORWARD chain"

{{  template "item" "filter/forward chain" }}

{{- if (and (ne (ds "host").export "netinstall")
            (eq (ds "host").type "router")) }}

{{    template "parts/firewall-filter-forward-chain.rsc.t" }}
{{    template "parts/firewall-filter-forward-ports.rsc.t" }}
{{    template "parts/firewall-filter-forward-services.rsc.t" }}
{{    template "parts/firewall-filter-forward-rules.rsc.t" }}
{{    template "parts/firewall-filter-forward-vlans.rsc.t" }}

{{- else }}

{{    template "parts/firewall-filter-forward-drop.rsc.t" }}

{{- end }}
