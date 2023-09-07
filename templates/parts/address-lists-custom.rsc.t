# -- templates/parts/address-lists-custom.rsc.t
{{- /* vim:set ft=routeros: */}}
# Set the Firewall Address Lists for custom lists

{{ template "component" "Configure the Custom Lists" }}

{{- if (has (ds "network") "lists") }}
{{-   range $list := (ds "network").lists }}

{{-     if (and (eq (ds "host").export "netinstall") (not (and (has $list "default") $list.default))) }}
{{-       continue }}
{{-     end }}

{{-     if (and (has $list "enabled") (not $list.enabled)) }}
{{-       continue }}
{{-     end }}

{{-     if (not (and (has $list "type") (eq $list.type "address"))) }}
{{-       continue }}
{{-     end }}

# {{ $list.name }}

{{ template "item" $list.name }}

/ip firewall address-list

{{-     range $address := $list.addresses }}
{{-       if (and (has $address "enabled") (not $address.enabled)) }}
{{-         continue }}
{{-       end }}

{{-       if (or (has $address "host") (has $address "ipv4")) }}
add list="$runId:{{ $list.name }}"
{{-         if (has $address "host") }} address="{{ $address.host }}"
{{-         else if (has $address "ipv4") }} address="{{ $address.ipv4 }}"
{{-         end }}

{{-         if (has $address "comment") }} \
    comment="{{ $address.comment | strings.ReplaceAll "\n" " " | strings.TrimSpace }}"
{{-         end }}
{{-       end }}

{{-     end }}

/ipv6 firewall address-list

{{-     range $address := $list.addresses }}
{{-       if (and (has $address "enabled") (not $address.enabled)) }}
{{-         continue }}
{{-       end }}

{{-       if (or (has $address "host") (has $address "ipv6")) }}
add list="$runId:{{ $list.name }}"
{{-         if (has $address "host") }} address="{{ $address.host }}"
{{-         else if (has $address "ipv6") }} address="{{ $address.ipv6 }}"
{{-         end }}

{{-         if (has $address "comment") }} \
    comment="{{ $address.comment | strings.ReplaceAll "\n" " " | strings.TrimSpace }}"
{{-         end }}
{{-       end }}

{{-     end }}

{{-   end }}
{{- end -}}
