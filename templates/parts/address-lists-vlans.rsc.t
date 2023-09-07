# -- templates/parts/address-lists-vlans.rsc.t
{{- /* vim:set ft=routeros: */}}
# Set the Firewall Address Lists for the known VLANs

{{  template "component" "Configure the VLAN Lists" }}

{{- $bridge := (ds "host").bridge.name }}

{{- range $v := (ds "network").vlans }}

{{-   if (and (eq (ds "host").export "netinstall") (not (eq $v.name "management"))) }}
{{-     continue }}
{{-   end }}

{{-   if (and (has $v "enabled") (not $v.enabled)) }}
{{-     continue }}
{{-   end }}

{{-   if (not (or (has $v "ipv4") (has $v "ipv6"))) }}
{{-     continue }}
{{-   end }}

# {{ $bridge }}.{{ $v.id }}

{{ template "item" (print $bridge "." $v.id) }}

{{    if (has $v "ipv4") }}
{{-     $network := (index ((net.ParseIPPrefix $v.ipv4.address).Range | strings.Split "-") 0) -}}
{{-     $prefix := (index ($v.ipv4.address | strings.Split "/") 1) -}}
{{-     $broadcast := (index ((net.ParseIPPrefix $v.ipv4.address).Range | strings.Split "-") 1) -}}

/ip firewall address-list

add list="$runId:vlans" address={{ $network }}/{{ $prefix }} \
    comment="{{ $bridge }}.{{ $v.id }}{{ if (has $v "comment") }}: {{ $v.comment }}{{ end }}"
add list="$runId:vlan:{{ $v.name }}" address={{ $network }}/{{ $prefix }} \
    comment="{{ $bridge }}.{{ $v.id }}{{ if (has $v "comment") }}: {{ $v.comment }}{{ end }}"
add list="$runId:broadcasts" address={{ $broadcast }} \
    comment="{{ $bridge }}.{{ $v.id }}{{ if (has $v "comment") }}: {{ $v.comment }}{{ end }}"
{{-     if (has $v "lists") }}
{{-       range $i := $v.lists }}
add list="$runId:{{ $i }}" address={{ $network }}/{{ $prefix }} \
    comment="{{ $bridge }}.{{ $v.id }}{{ if (has $v "comment") }}: {{ $v.comment }}{{ end }}"
{{-       end }}
{{-     end }}
{{-   end }}

{{    if (has $v "ipv6") }}
{{-     $network := (index ((net.ParseIPPrefix $v.ipv6.address).Range | strings.Split "-") 0) -}}
{{-     $prefix := (index ($v.ipv6.address | strings.Split "/") 1) -}}

/ipv6 firewall address-list

add list="$runId:vlans" address={{ $network }}/{{ $prefix }} \
    comment="{{ $bridge }}.{{ $v.id }}{{ if (has $v "comment") }}: {{ $v.comment }}{{ end }}"
add list="$runId:vlan:{{ $v.name }}" address={{ $network }}/{{ $prefix }} \
    comment="{{ $bridge }}.{{ $v.id }}{{ if (has $v "comment") }}: {{ $v.comment }}{{ end }}"
{{-     if (has $v "lists") }}
{{-       range $i := $v.lists }}
add list="$runId:vlan:{{ $i }}" address={{ $network }}/{{ $prefix }} \
    comment="{{ $bridge }}.{{ $v.id }}{{ if (has $v "comment") }}: {{ $v.comment }}{{ end }}"
{{-       end }}
{{-     end }}
{{-   end }}

{{- end }}

/ip firewall address-list

# This can be installed by a genuine network, but is a global broadcast address
# for some multicast and network services, so check if it exists before adding
:if ( \
  [ :len [ find where list="$runId:broadcasts" and address=255.255.255.255 ] ] = 0 \
) do={
  add list="$runId:broadcasts" address=255.255.255.255 \
      comment="Global Broadcast address"
}
