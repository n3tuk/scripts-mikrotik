# -- templates/parts/vlans-custom.rsc.t
{{- /* vim:set ft=routeros: */}}

{{- $bridge := (ds "host").bridge.name }}
{{- $v_defaults := coll.Dict "enabled" true "comment" "VLAN" }}
{{- $i_defaults := coll.Dict "enabled" false "type" "ethernet" "bridge" true "vlan" "blocked" "comment" "Unused" }}

{{  template "component" "Configure the Custom VLANs" }}

{{-  range $v := (ds "network").vlans }}

{{-   if (or (eq $v.name "management") (eq $v.name "blocked")) }}
{{-     continue }}
{{-   end }}

{{-   $v = merge $v $v_defaults }}
{{-   $v = merge $v (coll.Dict "interface" (print $bridge "." $v.id)) }}

{{-   if $v.enabled -}}

{{-     $tagged := coll.Slice -}}
{{-     $untagged := coll.Slice -}}
{{-     $router := false -}}

{{-     if (has (ds "host").bridge.vlans $v.name) -}}
{{-       $tagged = $tagged | append (ds "host").bridge.name -}}
{{-       $router = true -}}
{{-     end }}

{{-     range $i := (ds "host").interfaces -}}
{{-       $i = merge $i $i_defaults }}
{{-       if (or (not (has $i "bridge")) $i.bridge) }}
{{-         if (and (has $i "vlan") (eq $i.vlan $v.name)) -}}
{{-           $untagged = $untagged | append $i.name -}}
{{-         else -}}
{{-           if (and (has $i "vlans") (has $i.vlans $v.name)) }}
{{-             if (eq $i.type "wireless") }}{{- /*
                  # Even through wireless interfaces have vlans support for virtual
                  # interfaces, they are attached as untagged ports as each
                  # virtual interface becomes a dedicated interface  */}}
{{-               $untagged = $untagged | append (print $i.name "." $v.id) }}
{{-             else }}
{{-               $tagged = $tagged | append $i.name }}
{{-             end }}
{{-           end }}
{{-         end }}
{{-       end }}
{{-     end }}

# {{ $bridge }}.{{ $v.id }}
#   {{ $v.comment | strings.WordWrap 76 "\n#   " }}

{{      template "item" $v.interface }}

/interface bridge vlan

:if ( \
  [ :len [ find where bridge="{{ $bridge }}" and vlan-ids="{{ $v.id }}" and dynamic=no ] ] = 0 \
) do={ add bridge="{{ $bridge }}" vlan-ids="{{ $v.id }}" }
set [ find where bridge="{{ $bridge }}" and vlan-ids="{{ $v.id }}" ] \
    tagged="{{ join (sort $tagged) "," }}" \
    untagged="{{ join (sort $untagged) "," }}" \
    comment="{{ $v.name }}{{ if (has $v "comment") }}: {{ $v.comment }}{{ end }}"

{{-     if $router }}

/interface vlan

:if ( \
  [ :len [ find where interface="{{ $bridge }}" and vlan-id="{{ $v.id }}" ] ] = 0 \
) do={
  add interface="{{ $bridge }}" \
      vlan-id="{{ $v.id }}" \
      name="{{ $v.interface }}" \
      mtu={{ if (has (ds "host").settings "mtu") }}{{ (ds "host").settings.mtu }}{{ else }}1500{{ end }} \
}

set [ find where interface="{{ $bridge }}" and vlan-id="{{ $v.id }}" ] \
    name="{{ $v.interface }}" \
    use-service-tag=no \
    comment="{{ $v.name }}{{ if (has $v "comment") }}: {{ $v.comment }}{{ end }}"

{{  template "parts/vlan-ipv4.rsc.t" $v }}
{{  template "parts/vlan-ipv6.rsc.t" $v }}

/interface list member

:if ( \
  [ :len [ find where list="internal" and interface="{{ $v.interface }}" ] ] = 0 \
) do={ add list="internal" interface="{{ $v.interface }}" }
set [ find where list="internal" and interface="{{ $v.interface }}" ] \
    comment="{{ $v.comment }}"
{{-     end -}}
{{-   end -}}
{{- end }}
