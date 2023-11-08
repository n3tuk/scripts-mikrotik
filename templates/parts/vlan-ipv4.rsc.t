# -- templates/parts/vlan-ipv4.rsc.t
{{- /* vim:set ft=routeros: */}}

{{- $address := "" }}
{{- $prefix := "" }}
{{- $gateway := "" }}
{{- $type := "dhcp" }}

{{- if (has . "ipv4") }}
{{-   $address = (index (.ipv4.address | strings.Split "/") 0) }}
{{-   $prefix = (index (.ipv4.address | strings.Split "/") 1) }}
{{-   if (has .ipv4 "type") }}
{{-     $type = .ipv4.type }}
{{-   end }}
{{-   $gateway = $address }}
{{-   if (has .ipv4 "gateway") }}
{{-     $gateway = .ipv4.gateway }}
{{-   end }}
{{- end }}

{{- if (and (eq .name "management")
            (and (has (ds "host").bridge "ipv4")
                 (has (ds "host").bridge.ipv4 "address"))) }}
{{-   $address = (index ((ds "host").bridge.ipv4.address | strings.Split "/") 0) }}
{{-   $prefix = (index ((ds "host").bridge.ipv4.address | strings.Split "/") 1) }}
{{- end }}

{{- if (ne $address "") }}
{{-   $network := (index ((net.ParseIPPrefix (print $address "/" $prefix)).Range | strings.Split "-") 0) }}

/ip address

:if ( \
  [ :len [ find where interface="{{ .interface }}" ] ] = 0 \
) do={ add interface="{{ .interface }}" address="{{ $address }}/{{ $prefix }}" }
set [ find where interface="{{ .interface }}" ] \
    address="{{ $address }}/{{ $prefix }}" \
    comment="{{ .comment }}"

{{-   if (and (eq .name "management")
              (and (has . "ipv4")
                   (ne .ipv4.address (ds "host").bridge.ipv4.address))) }}

/ip route

:if ( \
  [ :len [ find where type=static and dst-address="0.0.0.0/0" ] ] = 0 \
) do={ add dst-address="0.0.0.0/0" gateway="{{ $gateway }}" }
set [ find where type=static and dst-address="0.0.0.0/0" ] \
    gateway="{{ $gateway }}" \
    comment="Default Gateway for {{ .comment }}"

{{-   else if (eq $type "dhcp") }}

/ip pool

:if ( \
  [ :len [ find where name="{{ .name }}" ] ] = 0 \
) do={ add name="{{ .name }}" range="{{ .ipv4.pool }}" }
set [ find where name="{{ .name }}" ] \
    range="{{ .ipv4.pool }}" \
    comment="{{ .comment }}"

/ip dhcp-server network

:if ( \
  [ :len [ find where address="{{ $network }}/{{ $prefix }}" ] ] = 0 \
) do={ add address="{{ $network }}/{{ $prefix }}" }
set [ find where address="{{ $network }}/{{ $prefix }}" ] \
    gateway="{{ $gateway }}" \
    dns-server="{{ $gateway }}" \
    ntp-server="{{ $gateway }}" \
    comment="{{ .name }} ({{ .comment }})"

/ip dhcp-server

:if ( \
  [ :len [ find where interface="{{ .interface }}" ] ] = 0 \
) do={ add interface="{{ .interface }}" }
set [ find where interface="{{ .interface }}" ] \
    name="{{ .name }}" \
    address-pool="{{ .name }}" lease-time="{{ .ipv4.lease }}" \
    comment="{{ .comment }}"

{{-   else if (eq $type "static") }}

/ip pool
remove [ find where name="{{ .name }}" ]

/ip dhcp-server network
remove [ find where address="{{ $network }}/{{ $prefix }}" ]

/ip dhcp-server
remove [ find where interface="{{ .interface }}" ]

{{-   end }}
{{- else }}

# No IPv4 configuration provided
{{- end }}
