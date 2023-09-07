# -- templates/parts/address-lists-cleanup.rsc.t
{{- /* vim:set ft=routeros: */}}

{{ template "section" "Clean up Address Lists" }}

/ip firewall address-list

remove [
  find where dynamic=no \
         and !( list~"^$runId:" )
]

/ipv6 firewall address-list

remove [
  find where dynamic=no \
         and !( list~"^$runId:" )
]
