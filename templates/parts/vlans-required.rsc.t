# -- templates/parts/vlans-required.rsc.t
{{- /* vim:set ft=routeros: */}}

{{  template "component" "Configure the Required VLANs" }}

{{  template "parts/vlan-management.rsc.t" }}
{{  template "parts/vlan-blocked.rsc.t" }}
