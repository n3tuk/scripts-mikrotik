# -- templates/parts/address-lists-cleanup.rsc.t
{{- /* vim:set ft=routeros: */}}

{{ template "section" "Clean up Address Lists" }}

{{ template "item" "BFD" }}

# NOTE: This is a workaround for the fact that the BFD configuration is not
#       currently managed by these scripts, but it must still be updated on
#       firewall changes to ensure that the BFD address lists are correct.

/routing bfd configuration
set [ find where address-list~".*:bgp:trusted" ] \
    address-list="$runId:bgp:trusted"

/ip firewall address-list

{{ template "item" "IPv4" }}

remove [
  find where dynamic=no \
         and !( list~"^$runId:" )
]

/ipv6 firewall address-list

{{ template "item" "IPv6" }}

remove [
  find where dynamic=no \
         and !( list~"^$runId:" )
]
