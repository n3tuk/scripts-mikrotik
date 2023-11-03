# -- templates/parts/bridge.rsc.t
{{- /* vim:set ft=routeros: */}}

{{- $bridge := (ds "host").bridge.name }}
{{- $v_defaults := coll.Dict "enabled" true "comment" "VLAN" }}

{{  template "section" "Set up Bridge Interface" }}

/interface bridge

{{  template "parts/bridge-ports.rsc.t" }}
{{  template "parts/bridge-interface.rsc.t" }}
# Configure the MSTP instance and attach the known VLANs to it to allow it to
# monitor all the connections and detect loops or issues with the network
/interface bridge msti

{{- $vlans := coll.Slice }}
{{- $blocked := coll.Dict }}
{{- range $v := (ds "network").vlans }}
{{-   $v = merge $v $v_defaults }}
{{-   if (eq $v.name "blocked") }}
{{-     $blocked = $v }}
{{-   else if $v.enabled }}
{{-     $vlans = $vlans | append $v.id }}
{{-   end }}
{{- end }}

:if ( \
  [ :len [ find where bridge="{{ $bridge }}" and identifier=1 ] ] = 0 \
) do={ add bridge="{{ $bridge }}" identifier=1 vlan-mapping={{ conv.Join (coll.Sort $vlans) "," }} }
set [ find where bridge="{{ $bridge }}" and identifier=1 ] \
    vlan-mapping={{ conv.Join (coll.Sort $vlans) "," }} \
    priority={{ if (has (ds "host").bridge "priority") }}{{ (ds "host").bridge.priority }}{{ else }}0x8000{{ end }}
