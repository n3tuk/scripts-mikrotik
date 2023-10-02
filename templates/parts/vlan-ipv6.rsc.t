# -- templates/parts/vlan-ipv6.rsc.t
{{- /* vim:set ft=routeros: */}}

{{- $address := "" }}
{{- $prefix := "" }}

{{- if (has . "ipv6") }}
{{-   $address = (index (.ipv6.address | strings.Split "/") 0) }}
{{-   $prefix = (index (.ipv6.address | strings.Split "/") 1) }}
{{- end }}

{{- if (and (eq .name "management")
            (and (has (ds "host").bridge "ipv6")
                 (has (ds "host").bridge.ipv6 "address"))) }}
{{-   $address = (index ((ds "host").bridge.ipv6.address | strings.Split "/") 0) }}
{{-   $prefix = (index ((ds "host").bridge.ipv6.address | strings.Split "/") 1) }}
{{- end }}

{{- if (ne $address "") }}
{{-   $network := (index ((net.ParseIPPrefix (print $address "/" $prefix)).Range | strings.Split "-") 0) }}
{{-   $slaac := false }}
{{-   if (and (ne .name "management") (and (has .ipv6 "slaac") .ipv6.slaac)) }}
{{-     $slaac = true }}
{{-   end }}

/ipv6 address
:if ( \
  [ :len [ find where interface="{{ .interface }}" and dynamic=no ] ] = 0 \
) do={ add interface="{{ .interface }}" address="{{ $address }}/{{ $prefix }}" }
set [ find where interface="{{ .interface }}" and dynamic=no ] \
    address="{{ $address }}/{{ $prefix }}" \
    eui-64={{ if (ne .name "management") }}yes{{ else }}no{{ end }} \
    no-dad={{ if (eq .name "management") }}yes{{ else }}no{{ end }} \
    advertise={{ if (and $slaac (eq (ds "host").type "router")) }}yes{{ else }}no{{ end }} \
    comment="{{ .name }} ({{ .comment }})"

{{-   if (or (ne .name "management")
             (and (has . "ipv6")
                  (eq .ipv6.address (ds "host").bridge.ipv6.address))) }}

/ipv6 pool
{{-     if $slaac }}
remove [ find where name="{{ .name }}" ]
{{-     else }}
:if ( \
  [ :len [ find where name="{{ .name }}" ] ] = 0 \
) do={ add name="{{ .name }}" prefix="{{ $network }}/{{ $prefix }}" prefix-length={{ $prefix }} }
set [ find where name="{{ .name }}" ] \
    prefix="{{ $network }}/{{ $prefix }}" prefix-length={{ $prefix }}
{{-     end }}

/ipv6 dhcp-server
{{-     if $slaac }}
remove [ find where interface="{{ .interface }}" ]
{{-     else }}
:if ( \
  [ :len [ find where interface="{{ .interface }}" ] ] = 0 \
) do={ add interface="{{ .interface }}" name="{{ .name }}" address-pool="{{ .name }}" }
set [ find where interface="{{ .interface }}" ] \
    name="{{ .name }}" \
    address-pool="{{ .name }}" lease-time="{{ .ipv6.lease }}" \
    comment="{{ .comment }}"
{{-     end }}

/ipv6 nd
:if ( \
  [ :len [ find where interface="{{ .interface }}" ] ] = 0 \
) do={ add interface="{{ .interface }}" }
set [ find where interface="{{ .interface }}" \
    advertise-mac-address=yes \
    advertise-dns=yes \
    managed-address-configuration={{ if $slaac }}no{{ else }}yes{{ end }} \
    other-configuration={{ if $slaac }}no{{ else }}yes{{ end }} \
    ra-preference=high \
    ra-interval=15s-10m \
    ra-lifetime=1h \
    ra-delay=1s
{{-   end }}
{{- else }}

# No IPv6 configuration provided
{{- end -}}
