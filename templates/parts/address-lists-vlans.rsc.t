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

/ip firewall address-list

add list="$runId:vlans" address={{ $network }}/{{ $prefix }} \
    comment="{{ $bridge }}.{{ $v.id }}{{ if (has $v "comment") }}: {{ $v.comment }}{{ end }}"
add list="$runId:vlan:{{ $v.name }}" address={{ $network }}/{{ $prefix }} \
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
add list="$runId:{{ $i }}" address={{ $network }}/{{ $prefix }} \
    comment="{{ $bridge }}.{{ $v.id }}{{ if (has $v "comment") }}: {{ $v.comment }}{{ end }}"
{{-       end }}
{{-     end }}

{{-     if (and (has $v.ipv6 "pool")
                (ne $v.ipv6.pool (print $network "/" $prefix))) }}

add list="$runId:vlans" address={{ $v.ipv6.pool }} \
    comment="{{ $bridge }}.{{ $v.id }}{{ if (has $v "comment") }}: {{ $v.comment }}{{ end }}"
add list="$runId:vlan:{{ $v.name }}" address={{ $v.ipv6.pool }} \
    comment="{{ $bridge }}.{{ $v.id }}{{ if (has $v "comment") }}: {{ $v.comment }}{{ end }}"

{{-      if (has $v "lists") }}
{{-        range $i := $v.lists }}
add list="$runId:{{ $i }}" address={{ $v.ipv6.pool }} \
    comment="{{ $bridge }}.{{ $v.id }}{{ if (has $v "comment") }}: {{ $v.comment }}{{ end }}"
{{-        end }}
{{-      end }}

{{-    end }}
{{-   end }}

{{- end }}
