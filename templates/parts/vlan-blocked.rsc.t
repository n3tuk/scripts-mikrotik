# -- templates/parts/vlan-blocked.rsc.t
{{- /* vim:set ft=routeros: */}}

{{- $bridge := (ds "host").bridge.name }}
{{- $v_defaults := coll.Dict "enabled" true "comment" "VLAN" }}
{{- $i_defaults := coll.Dict "enabled" false "type" "ethernet" "bridge" true "vlan" "blocked" "comment" "Unused" }}

{{- $blocked := coll.Dict }}
{{- range $v := (ds "network").vlans }}
{{-   $v = merge $v $v_defaults }}
{{-   if (eq $v.name "blocked") }}
{{-     $blocked = merge $v (coll.Dict "id" (print "%02d" $v.id)) }}
{{-   end }}
{{- end }}

{{- $untagged := coll.Slice }}
{{- range $i := (ds "host").interfaces }}
{{-   $i = merge $i $i_defaults }}
{{-   if (and (eq (ds "host").export "netinstall")
              (and $i.bridge (ne $i.vlan "management"))) }}
{{-     $untagged = $untagged | append $i.name }}
{{-   else if (and $i.bridge (eq $i.vlan "blocked")) }}
{{-     $untagged = $untagged | append $i.name }}
{{-   end }}
{{- end }}

{{  template "item" (print $bridge "." $blocked.id) }}

/interface bridge vlan
:if ( \
  [ :len [ find where bridge={{ $bridge }} and vlan-ids={{ $blocked.id }} ] ] = 0 \
) do={ add bridge={{ $bridge }} vlan-ids={{ $blocked.id }} }
set [ find where bridge={{ $bridge }} and vlan-ids={{ $blocked.id }} ] \
    tagged="" untagged="{{ conv.Join (sort $untagged) "," }}" \
    comment="{{ $blocked.comment }}"
