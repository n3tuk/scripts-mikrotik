# -- templates/parts/vlans-custom.rsc.t
{{- /* vim:set ft=routeros: */}}

{{- $bridge := (ds "host").bridge.name }}
{{- $v_defaults := dict "enabled" true "comment" "VLAN" }}
{{- $i_defaults := dict "enabled" false "type" "ethernet" "bridge" true "vlan" "blocked" "comment" "Unused" }}

{{  template "component" "Configure the Custom VLANs" }}

{{-  range $v := (ds "network").vlans }}

{{-   if (or (eq $v.name "management") (eq $v.name "blocked")) }}
{{-     continue }}
{{-   end }}

{{-   $v = merge $v $v_defaults }}
{{-   $interface := print $bridge "." $v.id }}

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
{{-       if (or (not (has $i "bridge")) (not $i.bridge)) -}}
{{-         if (and (has $i "vlan") (eq $i.vlan $v.name)) -}}
{{-           $untagged = $untagged | append $i.name -}}
{{-         else -}}
{{-           if (and (has $i "vlans") (has $i.vlans $v.name)) -}}
{{-             $tagged = $tagged | append $i.name -}}
{{-           end -}}
{{-         end -}}
{{-       end -}}
{{-     end }}

# {{ $bridge }}.{{ $v.id }}
#   {{ $v.comment | strings.WordWrap 76 "\n#   " }}

{{      template "item" $interface }}

/interface bridge vlan
:if ( \
  [ :len [ find where bridge="{{ $bridge }}" and vlan-ids="{{ $v.id }}" ] ] = 0 \
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
      name="{{ $interface }}" \
      mtu={{ if (has (ds "host").settings "mtu") }}{{ (ds "host").settings.mtu }}{{ else }}1500{{ end }} \
}
set [ find where interface="{{ $bridge }}" and vlan-id="{{ $v.id }}" ] \
    name="{{ $interface }}" \
    use-service-tag=no \
    comment="{{ $v.name }}{{ if (has $v "comment") }}: {{ $v.comment }}{{ end }}"

{{-       if (has $v "ipv4") }}
{{-         $address := (index ($v.ipv4.address | strings.Split "/") 0) }}
{{-         $prefix := (index ($v.ipv4.address | strings.Split "/") 1) }}
{{-         $network := (index ((net.ParseIPPrefix $v.ipv4.address).Range | strings.Split "-") 0) }}

/ip address
:if ( \
  [ :len [ find where interface="{{ $interface }}" ] ] = 0 \
) do={ add interface="{{ $interface }}" address="{{ $address }}/{{ $prefix }}" }
set [ find where interface="{{ $interface }}" ] \
    address="{{ $address }}/{{ $prefix }}" \
    comment="{{ $v.name }} ({{ $v.comment }})"

/ip pool
:if ( \
  [ :len [ find where name="{{ $v.name }}" ] ] = 0 \
) do={ add name="{{ $v.name }}" range="{{ $v.ipv4.pool }}" }
set [ find where name="{{ $v.name }}" ] \
    range="{{ $v.ipv4.pool }}" \
    comment="{{ $v.comment }}"

/ip dhcp-server network
:if ( \
  [ :len [ find where address="{{ $network }}/{{ $prefix }}" ] ] = 0 \
) do={ add address="{{ $network }}/{{ $prefix }}" }
set [ find where address="{{ $network }}/{{ $prefix }}" ] \
    gateway="{{ $address }}" \
    dns-server="{{ $address }}" \
    ntp-server="{{ $address }}" \
    comment="{{ $v.name }} ({{ $v.comment }})"

/ip dhcp-server
:if ( \
  [ :len [ find where interface="{{ $interface }}" ] ] = 0 \
) do={ add interface="{{ $interface }}" }
set [ find where interface="{{ $interface }}" ] \
    name="{{ $v.name }}" \
    address-pool="{{ $v.name }}" lease-time="{{ $v.ipv4.lease }}" \
    comment="{{ $v.comment }}"

{{       end -}}

{{-       if (has $v "ipv6") }}
{{-         $address := $v.ipv6.address }}
{{-         $network := (index ((net.ParseIPPrefix $v.ipv6.address).Range | strings.Split "-") 0) }}
{{-         $prefix := (index ($v.ipv6.address | strings.Split "/") 1) -}}

/ipv6 address
:if ( \
  [ :len [ find where interface="{{ $interface }}" and dynamic=no ] ] = 0 \
) do={ add interface="{{ $interface }}" address="{{ $address }}" }
set [ find where interface="{{ $interface }}" and dynamic=no ] \
    address="{{ $address }}" eui-64=no \
    comment="{{ $v.name }} ({{ $v.comment }})"

/ipv6 pool
:if ( \
  [ :len [ find where name="{{ $v.name }}" ] ] = 0 \
) do={ add name="{{ $v.name }}" prefix="{{ $network }}/{{ $prefix }}" prefix-length={{ $prefix }} }
set [ find where name="{{ $v.name }}" ] \
    prefix="{{ $network }}/{{ $prefix }}" prefix-length={{ $prefix }}

/ipv6 dhcp-server
:if ( \
  [ :len [ find where interface="{{ $interface }}" ] ] = 0 \
) do={ add interface="{{ $interface }}" name="{{ $v.name }}" address-pool="{{ $v.name }}" }
set [ find where interface="{{ $interface }}" ] \
    name="{{ $v.name }}" \
    address-pool="{{ $v.name }}" lease-time="{{ $v.ipv6.lease }}" \
    comment="{{ $v.comment }}"
{{-       end }}

/interface list member
:if ( \
  [ :len [ find where list="internal" and interface="{{ $interface }}" ] ] = 0 \
) do={ add list="internal" interface="{{ $interface }}" }
set [ find where list="internal" and interface="{{ $interface }}" ] \
    comment="{{ $v.comment }}"
{{-     end -}}
{{-   end -}}
{{- end }}
