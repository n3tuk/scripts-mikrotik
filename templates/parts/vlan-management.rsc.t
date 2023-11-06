# -- templates/parts/vlan-management.rsc.t
{{- /* vim:set ft=routeros: */}}

{{- $bridge := (ds "host").bridge.name }}
{{- $v_defaults := coll.Dict "enabled" true "comment" "VLAN" }}
{{- $i_defaults := coll.Dict "enabled" false "type" "ethernet" "bridge" true "vlan" "blocked" "comment" "Unused" }}

{{- $management := coll.Dict }}
{{- range $v := (ds "network").vlans }}
{{-   $v = merge $v $v_defaults }}
{{-   if (eq $v.name "management") }}
{{-     $management = merge $v (
          coll.Dict "id" (printf "%02d" $v.id)
                    "interface" (print $bridge "." $v.id)) }}
{{-   end }}
{{- end }}

{{- $tagged := coll.Slice $bridge }}
{{- $untagged := coll.Slice }}
{{- range $i := (ds "host").interfaces }}
{{-   $i = merge $i $i_defaults }}
{{-   if (not $i.bridge) }}
{{-     continue }}
{{-   end }}
{{-   if (and (has $i "vlans") (has $i.vlans $management.name)) }}
{{-     $tagged = $tagged | append $i.name }}
{{-   else if (eq $i.vlan $management.name) }}
{{-     $untagged = $untagged | append $i.name }}
{{-   end }}
{{- end }}

{{  template "item" (print $bridge "." $management.id) }}

/interface bridge vlan

:if ( \
  [ :len [ find where bridge="{{ $bridge }}" and vlan-ids={{ $management.id }} ] ] = 0 \
) do={ add bridge="{{ $bridge }}" vlan-ids={{ $management.id }} }
set [ find where bridge="{{ $bridge }}" and vlan-ids={{ $management.id }} ] \
    tagged="{{ conv.Join (sort $tagged) "," }}" untagged="{{ conv.Join (sort $untagged) "," }}" \
    comment="{{ $management.comment }}"

/interface vlan

:if ( \
  [ :len [ find where interface="{{ $bridge }}" and vlan-id={{ $management.id }} ] ] = 0 \
) do={
  add interface="{{ $bridge }}" \
      vlan-id={{ $management.id }} \
      name="{{ $management.interface }}" \
      mtu={{ if (has (ds "host").settings "mtu") }}{{ (ds "host").settings.mtu }}{{ else }}1500{{ end }}
}

set [ find where interface={{ $bridge }} and vlan-id={{ $management.id }} ] \
    name="{{ $management.interface }}"\
    use-service-tag=no \
    comment="{{ $management.comment }}"

{{  template "parts/vlan-ipv4.rsc.t" $management }}
{{  template "parts/vlan-ipv6.rsc.t" $management }}

/interface list member

:if ( \
  [ :len [ find where list="internal" and interface="{{ $management.interface }}" ] ] = 0 \
) do={ add list="internal" interface="{{ $management.interface }}" }
set [ find where list="internal" and interface="{{ $management.interface }}" ] \
    comment="{{ $management.comment }}"

:if ( \
  [ :len [ find where list="management" and interface="{{ $management.interface }}" ] ] = 0 \
) do={ add list="management" interface="{{ $management.interface }}" }
set [ find where list="management" and interface="{{ $management.interface }}" ] \
    comment="{{ $management.comment }}"
