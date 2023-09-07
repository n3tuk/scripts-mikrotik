# -- templates/parts/firewall-filter.rsc.t
{{- /* vim:set ft=routeros: */}}
# All stateful processing of traffic to, from, and through, this host will go
# under the filter table via the INPUT, OUTPUT, and FORWARD chains,
# respectively.

{{  template "component" "filter table" }}

# -> input
#  - established/invalid checks
#  - accept dhcp requests
#  > check:bogons (disabled)
#    - reject invalid network connections
#  > check:icmp
#    > check:icmp:allowed
#      - accept allowed icmp packets
#      - drop all other icmp packets
#    > check:icmp:ping
#      - drop restricted hosts
#      - rate limit icmp echo packets
#      - add hosts to restricted list
#      - drop excess icmp echo packets
#  > input:internal
#    > check:ssh
#      - drop restricted hosts
#      - rate limit ssh connection attempts
#      - add hosts to restricted list
#      - drop excess ssh connections
#    - accept dns requests
#    - accept ntp requests
#    > input:internal:admin
#      - accept webfig access
#      - accept winbox access
#      > input:internal:api
#        - accept api access
#    > input:internal:api
#      - accept api access
#    > reject:admin
#      - drop with icmp-admin-prohibited
#  > input:external
#    > tarpit:drop
#      - tarpit/drop connection attempts from known bad hosts
#    > input:external:wireguard
#      - accept wireguard requests
#    > input:external:ipsec (disabled)
#      - accept ipsec-encapsulated packets
#      - accept esp+ah packets
#      - accept ikev2 requests
#    > check:ssh
#      - drop restricted hosts
#      - rate limit ssh connection attempts
#      - add hosts to restricted list
#      - drop excess ssh connections
#    > tarpit:process
#      - rate limit drops with icmp-admin-prohibited
#      > tarpit:drop
#        - tarpit/drop connection attempts from known bad hosts
#
# -> forward
#  + established/invalid checks (with fasttrack)
#  > check:bogons (disabled)
#  > check:icmp
#    > check:icmp:allowed
#      - accept allowed icmp packets
#    > check:icmp:ping
#      - drop restricted hosts
#      - rate limit allowed icmp echo packets
#      - add hosts to restricted list
#      - drop excess icmp echo packets
#    - drop all other icmp packets
#    > check:dns
#      - accept dns requests to selected hosts
#      > reject:admin
#        - drop with icmp-admin-prohibited
#    > check:ntp
#      - accept ntp requests to selected hosts
#      > reject:admin
#        - drop with icmp-admin-prohibited
#  (all internal firewall rules should go here)
#  > evaluate requests on per-vlan basis
#    - per-vlan rules
#  + reject all other packets
#
# -> output
#  + established check
#  + invalid check
#  > check:bogons (disabled)
#  > check:icmp
#    > check:icmp:allowed
#      - accept allowed icmp packets
#    > check:icmp:ping
#      - drop restricted hosts
#      - rate limit allowed icmp echo packets
#      - add hosts to restricted list
#      - drop excess icmp echo packets
#    - drop all other icmp packets
#  > check:dns
#    - accept dns requests to selected hosts
#    > reject:admin
#      - drop with icmp-admin-prohibited
#  > check:ntp
#    - accept ntp requests to selected hosts
#    > reject:admin
#      - drop with icmp-admin-prohibited
#  > output:internal
#    - accept http(s) requests
#  > output:external
#    > output:external:wireguard
#      - accept wireguard requests
#    > output:external:ipsec (disabled)
#      - accept ipsec-encapsulated packets
#      - accept esp+ah packets
#      - accept ikev2 requests
#  > reject:admin
#    - drop with icmp-admin-prohibited

{{  template "parts/firewall-filter-reject-admin.rsc.t" }}
{{  template "parts/firewall-filter-check-icmp.rsc.t" }}
{{- if (and (ne (ds "host").export "netinstall")
            (eq (ds "host").type "router")) }}
{{    template "parts/firewall-filter-tarpit.rsc.t" }}
{{- end }}
{{- if (ne (ds "host").export "netinstall") }}
{{    template "parts/firewall-filter-check-ssh.rsc.t" }}
{{- end }}
{{  template "parts/firewall-filter-check-dns.rsc.t" }}
{{  template "parts/firewall-filter-check-ntp.rsc.t" }}
{{  template "parts/firewall-filter-input-internal.rsc.t" }}
{{  template "parts/firewall-filter-input-external.rsc.t" }}
{{  template "parts/firewall-filter-input.rsc.t" }}
{{  template "parts/firewall-filter-output-internal.rsc.t" }}
{{  template "parts/firewall-filter-output-external.rsc.t" }}
{{  template "parts/firewall-filter-output.rsc.t" }}
{{  template "parts/firewall-filter-forward.rsc.t" }}
{{  template "parts/firewall-cleanup.rsc.t" (coll.Slice "filter" "input" "forward" "output") -}}
