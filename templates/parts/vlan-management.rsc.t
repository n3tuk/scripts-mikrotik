# -- templates/parts/vlan-management.rsc.t
{{- /* vim:set ft=routeros: */}}

{{- $bridge := (ds "host").bridge.name }}
{{- $v_defaults := dict "enabled" true "comment" "VLAN" }}
{{- $i_defaults := dict "enabled" false "type" "ethernet" "bridge" true "vlan" "blocked" "comment" "Unused" }}

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

/ip address
:if ( \
  [ :len [ find where interface="{{ $management.interface }}" ] ] = 0 \
) do={ add interface="{{ $management.interface }}" address="{{ (ds "host").bridge.ipv4.address }}" }
set [ find where interface="{{ $management.interface }}" ] \
    address="{{ (ds "host").bridge.ipv4.address }}" \
    comment="{{ $management.comment }}"

{{- if (and (has $management "ipv4") (eq (ds "host").bridge.ipv4.address $management.ipv4.address)) }}
{{-   $address := (index ($management.ipv4.address | strings.Split "/") 0) -}}
{{-   $prefix := (index ($management.ipv4.address | strings.Split "/") 1) -}}
{{-   $network := (index ((net.ParseIPPrefix $management.ipv4.address).Range | strings.Split "-") 0) }}

/ip pool
:if ( \
  [ :len [ find where name="{{ $management.name }}" ] ] = 0 \
) do={ add name="{{ $management.name }}" range="{{ $management.ipv4.pool }}" }
set [ find where name="{{ $management.name }}" ] \
    range="{{ $management.ipv4.pool }}" \
    comment="{{ $management.comment }}"

/ip dhcp-server network
:if ( \
  [ :len [ find where address="{{ $network }}/{{ $prefix }}" ] ] = 0 \
) do={ add address="{{ $network }}/{{ $prefix }}" }
set [ find where address="{{ $network }}/{{ $prefix }}" ] \
    gateway="{{ $address }}" \
    dns-server="{{ $address }}" \
    ntp-server="{{ $address }}" \
    comment="{{ $management.name }} via {{ $management.interface }} ({{ $management.comment }})"

/ip dhcp-server
:if ( \
  [ :len [ find where interface="{{ $management.interface }}" ] ] = 0 \
) do={ add interface="{{ $management.interface }}" name="{{ $management.name }}" }
set [ find where interface="{{ $management.interface }}" ] \
    name="{{ $management.name }}" \
    address-pool="{{ $management.name }}" lease-time="{{ $management.ipv4.lease }}" \
    comment="{{ $management.comment }}"
{{-  else }}

{{-   $address := (index ($management.ipv4.address | strings.Split "/") 0) }}

/ip route
:if ( \
  [ :len [ find where type=static and dst-address="0.0.0.0/0" ] ] = 0 \
) do={ add dst-address="0.0.0.0/0" gateway="{{ $address }}" }
set [ find where type=static and dst-address="0.0.0.0/0" ] \
    gateway="{{ $address }}" \
    comment="Default Gateway for {{ $management.comment }}"
{{- end }}

{{  if (and (has (ds "host").bridge "ipv6") (has (ds "host").bridge.ipv6 "address")) -}}

/ipv6 address
:if ( \
  [ :len [ find where interface="{{ $management.interface }}" and dynamic=no ] ] = 0 \
) do={ add interface="{{ $management.interface }}" address="{{ (ds "host").bridge.ipv6.address }}" }
set [ find where interface="{{ $management.interface }}" and dynamic=no ] \
    address="{{ (ds "host").bridge.ipv6.address }}" \
    eui-64=no no-dad=yes advertise=no \
    comment="{{ $management.comment }}"

{{-   if (and (has $management "ipv6") (eq (ds "host").bridge.ipv6.address $management.ipv6.address)) }}
{{-     $address := $management.ipv6.address }}
{{-     $prefix := (index ((net.ParseIPPrefix $management.ipv6.address).Range | strings.Split "-") 0) }}
{{-     $length := (index ($management.ipv6.address | strings.Split "/") 1) }}

# TODO:
#   - IPv6 ND for advertising default routes

/ipv6 pool
:if ( \
  [ :len [ find where name="{{ $management.name }}" ] ] = 0 \
) do={ add name="{{ $management.name }}" prefix="{{ $prefix }}/{{ $length }}" prefix-length={{ $length }} }
set [ find where name="{{ $management.name }}" ] \
    prefix="{{ $prefix }}/{{ $length }}" prefix-length={{ $length }}

/ipv6 dhcp-server
:if ( \
  [ :len [ find where interface="{{ $management.interface }}" ] ] = 0 \
) do={ add interface="{{ $management.interface }}" name="{{ $management.name }}" address-pool="{{ $management.name }}" }
set [ find where interface="{{ $management.interface }}" ] \
    name="{{ $management.name }}" \
    address-pool="{{ $management.name }}" lease-time="{{ $management.ipv6.lease }}" \
    comment="{{ $management.comment }}"

{{-   end }}
{{- end }}

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
