# -- templates/parts/vlans.rsc.t
{{- /* vim:set ft=routeros: */}}
# Configure the internal network VLANs for this location based on the shared
# configuration, and then associate them with the bridge interfaces and the
# bridge ports as required for each VLAN based on the configuration specific for
# each host

{{  template "parts/vlans-remove.rsc.t" }}
{{  template "parts/vlans-required.rsc.t" -}}
{{  template "parts/vlans-custom.rsc.t" -}}
