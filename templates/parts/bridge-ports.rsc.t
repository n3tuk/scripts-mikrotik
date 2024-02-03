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

{{- /*
# The wifi interfaces need to be split in to individual interfaces for each of
# the SSIDs, so pre-process the interfaces list from the host configuration to
# fake the creation of these interfaces before creating the ports
*/}}

{{- $interfaces := coll.Slice }}
{{- range $interface := (ds "host").interfaces }}
{{-   $interface = merge $interface $i_defaults }}
{{-   if (and (eq $interface.type "wifi")
              (has $interface "vlans")) }}
{{-     if (eq (ds "host").export "netinstall") }}
{{-       continue }}
{{-     end }}
{{-     $vlans := $interface.vlans }}
{{-     $interface = $interface | coll.Omit "vlans" }}
{{-     $interfaces = $interfaces | append ($interface | merge (coll.Dict "comment" (print $interface.comment " (" $interface.vlan ")"))) }}
{{-     range $i, $vlan := $vlans }}
{{-       $virtual := $interface }}
{{-       range $v := (ds "network").vlans }}
{{-         $v := merge $v $v_defaults }}
{{-         if (and (eq $v.name $vlan)
                    (has $v "wifi")) }}
{{-           $virtual = $virtual | merge (coll.Dict "name" (print $interface.name "." $v.id)
                                                     "vlan" $v.name
                                                     "comment" (print $interface.comment " (" $vlan ")")) }}
{{-           $interfaces = $interfaces | append $virtual }}
{{-         end }}
{{-       end }}
{{-     end }}
{{-   else }}
{{-     $interfaces = $interfaces | append $interface }}
{{-   end}}
{{- end}}

{{- range $interface := $interfaces }}
{{-   if (not (and (has $interface "bridge") (not $interface.bridge))) }}

{{-     $cost := 20000 }}
{{-     if (has $interface "cost") }}
{{-       $cost = $interface.cost }}
{{-     else if (eq $interface.type "wifi") }}
{{-       $cost = 80000 }}
{{-     end }}

{{- /*
# Ensure that during bootstrap only management or blocked is allowed for the
# default VLAN on any physical interface
*/}}
{{-     if (eq (ds "host").export "netinstall") }}
{{-       if (and (has $interface "vlan") (ne $interface.vlan "management")) }}
{{-         $interface = $interface | merge (coll.Dict "vlan" "blocked"
                                       "frame_types" "admit-only-untagged-and-priority-tagged") }}
{{-       end }}
{{-     end }}

{{      template "item" (print $bridge "/" $interface.name) }}

:if ( \
  [ :len [ find where bridge={{ $bridge }} and interface={{ $interface.name}} ] ] = 0 \
) do={ add bridge={{ $bridge }} interface={{ $interface.name }} }
set [ find where bridge={{ $bridge }} and interface={{ $interface.name }} ] \
    path-cost={{ $cost }} \
    internal-path-cost={{ $cost }} \
{{-     if (has $interface "vlan") }}
{{-       range $v := (ds "network").vlans }}
{{-         if (eq $interface.vlan $v.name) }}
    pvid={{ $v.id }} \
    ingress-filtering=yes
{{-         end }}
{{-       end }}
{{-     else }}
    pvid={{ $blocked }} \
    ingress-filtering=yes
{{-     end }}

{{-     if (and (and (has $interface "vlan")
                     (ne $interface.vlan "blocked"))
                (has $interface "vlans")) }} \
    frame-types=admit-all \
    edge=yes-discover
{{-     else if (has $interface "vlans") }} \
    frame-types=admit-only-vlan-tagged \
    edge=no-discover
{{-     else if (has $interface "vlan") }} \
    frame-types=admit-only-untagged-and-priority-tagged \
    edge=yes
{{-     end }} \
    point-to-point=auto \
    multicast-router=disabled

{{-     if (has $interface "comment") }} \
    comment="{{ $interface.comment }}"
{{-     end }}

{{-   end -}}
{{- end }}

remove [
  find where bridge="{{ $bridge }}" \
{{- $first := true }}
{{- range $interface := $interfaces }}
{{-   $interface = merge $interface $i_defaults }}
{{-   if (or (not (has $interface "bridge"))
             (and (has $interface "bridge") $interface.bridge)) }}
{{-     if $first }}
{{-       $first = false }}
      and !( interface="{{ $interface.name }}"
{{-     else }} \
          or interface="{{ $interface.name }}"
{{-     end }}
{{-   end }}
{{- end }} )
]
