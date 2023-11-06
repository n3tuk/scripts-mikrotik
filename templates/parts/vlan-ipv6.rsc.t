# -- templates/parts/vlan-ipv6.rsc.t
{{- /* vim:set ft=routeros: */}}

{{- $address := "" }}
{{- $prefix := "" }}
{{- $gateway := "" }}
{{- $type := "slaac" }}

{{- if (has . "ipv6") }}
{{-   $address = (index (.ipv6.address | strings.Split "/") 0) }}
{{-   $prefix = (index (.ipv6.address | strings.Split "/") 1) }}
{{-   if (has .ipv6 "type") }}
{{-     $type = .ipv6.type }}
{{-   end }}
{{- end }}

{{- if (and (eq .name "management")
            (and (has (ds "host").bridge "ipv6")
                 (has (ds "host").bridge.ipv6 "address"))) }}
{{-   $address = (index ((ds "host").bridge.ipv6.address | strings.Split "/") 0) }}
{{-   $prefix = (index ((ds "host").bridge.ipv6.address | strings.Split "/") 1) }}
{{-   if (has (ds "host").bridge.ipv6 "gateway") }}
{{-     $gateway = (ds "host").bridge.ipv6.gateway }}
{{-   end }}
{{- end }}

{{- if (ne $address "") }}
{{-   $network := (index ((net.ParseIPPrefix (print $address "/" $prefix)).Range | strings.Split "-") 0) }}

/ipv6 address

:if ( \
  [ :len [ find where interface="{{ .interface }}" and dynamic=no ] ] = 0 \
) do={ add interface="{{ .interface }}" address="{{ $address }}/{{ $prefix }}" }
set [ find where interface="{{ .interface }}" and dynamic=no ] \
    address="{{ $address }}/{{ $prefix }}" \
    eui-64={{ if (ne .name "management") }}yes{{ else }}no{{ end }} \
    no-dad={{ if (eq .name "management") }}yes{{ else }}no{{ end }} \
    advertise={{ if (and (eq $type "slaac") (eq (ds "host").type "router")) }}yes{{ else }}no{{ end }} \
    disabled=no \
    comment="{{ .name }} ({{ .comment }})"

{{-   if (and (eq .name "management")
              (and (has . "ipv6")
                   (ne .ipv6.address (ds "host").bridge.ipv6.address))) }}

/ipv6 route

:if ( \
  [ :len [ find where dst-address="::/0" and dynamic=no ] ] = 0 \
) do={ add dst-address="::/0" gateway="{{ $gateway }}" }
set [ find where dst-address="::/0" and dynamic=no ] \
    gateway="{{ $gateway }}" \
    disabled=no \
    comment="Default Gateway for {{ .comment }}"

/ipv6 pool
remove [ find where name="{{ .name }}" ]

/ipv6 dhcp-server
remove [ find where interface="{{ .interface }}" ]

/ipv6 nd prefix
remove [ find where interface="{{ .interface }}" and dynamic=no ]

/ipv6 nd
remove [ find where interface="{{ .interface }}" ]

{{-   else if (eq $type "dhcp") }}

/ipv6 pool

:if ( \
  [ :len [ find where name="{{ .name }}" ] ] = 0 \
) do={ add name="{{ .name }}" prefix="{{ .ipv6.pool }}" prefix-length=64 }
set [ find where name="{{ .name }}" ] \
    prefix="{{ .ipv6.pool }}" \
    prefix-length=64

/ipv6 dhcp-server

:if ( \
  [ :len [ find where interface="{{ .interface }}" ] ] = 0 \
) do={ add interface="{{ .interface }}" name="{{ .name }}" address-pool="{{ .name }}" }
set [ find where interface="{{ .interface }}" ] \
    name="{{ .name }}" \
    address-pool="{{ .name }}" \
    lease-time="{{ .ipv6.lease }}" \
    disabled=no \
    comment="{{ .comment }}"

/ipv6 nd prefix

:if ( \
  [ :len [ find where interface="{{ .interface }}" ] ] = 0 \
) do={ add interface="{{ .interface }}" prefix="::/64" }
set [ find where interface="{{ .interface }}" ] \
    prefix="::/64" \
    autonomous=no \
    disabled=no \
    comment="{{ .comment }}"

/ipv6 nd

:if ( \
  [ :len [ find where interface="{{ .interface }}" ] ] = 0 \
) do={ add interface="{{ .interface }}" }
set [ find where interface="{{ .interface }}" ] \
    advertise-mac-address=yes \
    advertise-dns=yes \
    managed-address-configuration=yes \
    other-configuration=yes \
    ra-preference=high \
    ra-interval=15s-10m \
    ra-lifetime=1h \
    ra-delay=1s \
    disabled=no

{{-   else if (eq $type "slaac") }}

/ipv6 pool
remove [ find where name="{{ .name }}" ]

/ipv6 dhcp-server
remove [ find where interface="{{ .interface }}" ]

/ipv6 nd prefix
remove [ find where interface="{{ .interface }}" and dynamic=no ]

/ipv6 nd
:if ( \
  [ :len [ find where interface="{{ .interface }}" ] ] = 0 \
) do={ add interface="{{ .interface }}" }
set [ find where interface="{{ .interface }}" ] \
    advertise-mac-address=yes \
    advertise-dns=yes \
    managed-address-configuration=no \
    other-configuration=no \
    ra-preference=high \
    ra-interval=15s-10m \
    ra-lifetime=1h \
    ra-delay=1s \
    disabled=no

{{-   else if (eq $type "static") }}

/ipv6 pool
remove [ find where name="{{ .name }}" ]

/ipv6 dhcp-server
remove [ find where interface="{{ .interface }}" ]

/ipv6 nd prefix
remove [ find where interface="{{ .interface }}" and dynamic=no ]

/ipv6 nd
:if ( \
  [ :len [ find where interface="{{ .interface }}" ] ] = 0 \
) do={ add interface="{{ .interface }}" }
set [ find where interface="{{ .interface }}" ] \
    advertise-mac-address=yes \
    advertise-dns=yes \
    managed-address-configuration=no \
    other-configuration=no \
    ra-preference=high \
    ra-interval=15s-10m \
    ra-lifetime=1h \
    ra-delay=1s \
    disabled=no
{{-   end }}
{{- else }}

# No IPv6 configuration provided
{{- end -}}
