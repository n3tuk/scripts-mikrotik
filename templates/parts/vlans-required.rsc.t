# -- templates/parts/vlans-required.rsc.t
{{- /* vim:set ft=routeros: */}}

{{  template "component" "Disable the default IPv6 ND" }}

/ipv6 nd
set [ find where interface=all ] \
    disable=yes

{{  template "component" "Configure the Required VLANs" }}

{{  template "parts/vlan-management.rsc.t" }}
{{  template "parts/vlan-blocked.rsc.t" }}
