# -- templates/parts/bridge-ports.rsc.t
{{- /* vim:set ft=routeros: */}}
# Set or update the configuration for the Bridge interfaces on this host

{{- $bridge := (ds "host").bridge.name }}
{{- $v_defaults := coll.Dict "enabled" true "comment" "VLAN" }}
{{- $i_defaults := coll.Dict "enabled" false "type" "ethernet" "vlan" "blocked" "comment" "Unused" }}

{{- $blocked := 1 }}
{{- $management := 2 }}
{{- range $v := (ds "network").vlans }}
{{-   if (eq $v.name "management") }}
{{-     $management = $v.id }}
{{-   else if (eq $v.name "blocked") }}
{{-     $blocked = $v.id }}
{{-   end }}
{{- end }}

{{  template "component" "Configure the Bridge Ports" }}

/interface bridge port

{{- range $i := (ds "host").interfaces }}
{{-   if (not (and (has $i "bridge") (not $i.bridge))) }}

{{-     $cost := 20000 }}
{{-     if (has $i "cost") }}
{{-       $cost = $i.cost }}
{{-     end }}

{{- /*
# Ensure that during bootstrap only management or blocked is allowed for the
# default VLAN on any physical interface
*/}}
{{-     if (eq (ds "host").export "netinstall") }}
{{-       if (and (has $i "vlan") (ne $i.vlan "management")) }}
{{-         $i = $i | merge (coll.Dict "vlan" "blocked"
                                       "frame_types" "admit-only-untagged-and-priority-tagged") }}
{{-       end }}
{{-     end }}

{{      template "item" (print $bridge "/" $i.name) }}

:if ( \
  [ :len [ find where bridge={{ $bridge }} and interface={{ $i.name}} ] ] = 0 \
) do={ add bridge={{ $bridge }} interface={{ $i.name }} }
set [ find where bridge={{ $bridge }} and interface={{ $i.name }} ] \
    path-cost={{ $cost }} internal-path-cost={{ $cost }} \
{{-     if (has $i "vlan") }}
{{-       range $v := (ds "network").vlans }}
{{-         if (eq $i.vlan $v.name) }}
    pvid={{ $v.id }} ingress-filtering=yes
{{-         end }}
{{-       end }}
{{-     else }}
    pvid={{ $blocked }} ingress-filtering=yes
{{-     end }}

{{-     if (and (and (has $i "vlan") (ne $i.vlan "blocked")) (has $i "vlans")) }} \
    frame-types=admit-all
{{-     else if (has $i "vlans") }} \
    frame-types=admit-only-vlan-tagged
{{-     else if (has $i "vlan") }} \
    frame-types=admit-only-untagged-and-priority-tagged
{{-     end }}

{{-     if (has $i "comment") }} \
    comment="{{ $i.comment }}"
{{-     end }}

{{-   end -}}
{{- end }}

remove [
  find where bridge="{{ $bridge }}" \
{{- $first := true }}
{{- range $i := (ds "host").interfaces }}
{{-   $i = merge $i $i_defaults }}
{{-   if (or (not (has $i "bridge"))
             (and (has $i "bridge") $i.bridge)) }}
{{-     if $first }}
{{-       $first = false }}
      and !( interface="{{ $i.name }}"
{{-     else }} \
          or interface="{{ $i.name }}"
{{-     end }}
{{-   end }}
{{- end }} )
]
