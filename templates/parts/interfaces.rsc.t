# -- templates/parts/interfaces.rsc.t
{{- /* vim:set ft=routeros: */}}
# Reconfigure the base interfaces for this host into a standard sets of names
# and settings for the internal network.

{{- $i_defaults := coll.Dict "enabled" false "type" "ethernet" "vlan" "blocked" "comment" "Unused" }}

{{  template "section" "Set up Physical Interfaces" }}

/interface

{{  template "component" "Configure the Physical Interfaces" }}

{{- $interfaces := coll.Slice }}
{{- range $i := (ds "host").interfaces }}
{{-   $i = merge $i $i_defaults }}
{{-   $interfaces = $interfaces | append $i.name }}
{{-   if (and (eq (ds "host").export "netinstall")
              (has $i "original")) }}

{{      template "item" (print $i.name " (rename from " $i.original ")") }}

:if ( \
  [ :len [ find where name={{ $i.original }} ] ] > 0 \
) do={
  set [ find where name={{ $i.original }} ] \
      name={{ $i.name }}
}

{{-   else }}

{{-   end }}

{{-   if (and (eq $i.type "wifi")
              (not (eq (ds "host").export "netinstall"))) }}
{{-     continue }}
{{-   end }}

{{      template "item" $i.name }}

set [ find where name={{ $i.name }} ] \
{{-   if (or (eq (ds "host").export "netinstall")
             (eq (ds "host").export "mtu")) }}
{{-     if (or (has $i "mtu") (has (ds "host").settings "mtu")) }}
{{-       if (has $i "mtu") }}
    mtu={{ $i.mtu }} \
{{-       else if (has (ds "host").settings "l2mtu") }}
    mtu={{ (ds "host").settings.mtu }} \
{{-       end }}
{{-       if (has $i "l2mtu") }}
    l2mtu={{ $i.l2mtu }} \
{{-       else if (has (ds "host").settings "l2mtu") }}
    l2mtu={{ (ds "host").settings.l2mtu }} \
{{-       else }}
{{-         if (has $i "mtu") }}
    l2mtu={{ (math.Add $i.mtu 92) }} \
{{-         else if (has (ds "host").settings "mtu") }}
    l2mtu={{ (math.Add (ds "host").settings.mtu 92) }} \
{{-         end }}
{{-       end }}
{{-     end }}
{{-   end }}
    disabled={{ if (not $i.enabled) }}yes{{ else }}no{{ end }} \
    comment="{{ $i.comment }}"
{{- end }}
