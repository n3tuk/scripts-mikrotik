# -- templates/parts/wireguard.rsc.t
{{- /* vim:set ft=routeros: */}}
# Configure the Wireguard VPN Service, setting up each of the required
# interfaces, and attaching the peers and IP addresses, and routing
# configurations needed.

{{- $i_defaults := coll.Dict "enabled" false "type" "ethernet" "vlan" "blocked" "comment" "" "mtu" 1420 "address" coll.Dict }}
{{- $p_defaults := coll.Dict "enabled" false "comment" "" "keepalive" 0 }}
{{- $interfaces := coll.Slice }}

{{  template "section" "Set up Wireguard Interfaces" }}

/interface wireguard

{{  template "component" "Configure the Interfaces" }}

{{- range $i := (ds "host").interfaces }}
{{-   $i = merge $i $i_defaults }}

{{-   if (or (eq (ds "host").export "netinstall")
             (ne $i.type "wireguard")) }}
{{-     continue }}
{{-   end}}

{{-   $interfaces = $interfaces | append $i.name }}

{{    template "item" $i.name }}

:if ( \
  [ :len [ find where name="{{ $i.name }}" ] ] = 0 \
) do={ add name="{{ $i.name }}" listen-port="{{ $i.port }}" private-key="{{ $i.key }}" }
set [ find where name="{{ $i.name }}" ] \
    private-key="{{ $i.key }}" \
    listen-port="{{ $i.port }}" \
    mtu={{ $i.mtu }} \
    disabled={{ if $i.enabled }}no{{ else }}yes{{ end }} \
    comment="{{ $i.comment }}"

{{-   if (has $i.address "ipv4") }}
{{-     $prefix := (index ($i.address.ipv4 | strings.Split "/") 1) }}
{{-     $network := (index ((net.ParseIPPrefix $i.address.ipv4).Range | strings.Split "-") 0) }}

/ip address

:if ( \
  [ :len [ find where interface="{{ $i.name }}" ] ] = 0 \
) do={ add interface="{{ $i.name }}" address="{{ $i.address.ipv4 }}" }
set [ find where interface="{{ $i.name }}" ] \
    address={{ $i.address.ipv4 }} \
    network={{ $network }} \
    disabled={{ if $i.enabled }}no{{ else }}yes{{ end }} \
    comment="{{ $i.comment }}"

{{-   end }}

{{-   if (has $i.address "ipv6") }}
{{-     $prefix := (index ($i.address.ipv6 | strings.Split "/") 1) }}
{{-     $network := (index ((net.ParseIPPrefix $i.address.ipv6).Range | strings.Split "-") 0) }}

/ipv6 address

:if ( \
  [ :len [ find where interface="{{ $i.name }}" ] ] = 0 \
) do={ add interface="{{ $i.name }}" address="{{ $i.address.ipv4 }}" }
set [ find where interface="{{ $i.name }}" ] \
    address={{ $i.address.ipv6 }} \
    no-dad=yes \
    disabled={{ if $i.enabled }}no{{ else }}yes{{ end }} \
    comment="{{ $i.comment }}"

{{-   end }}

/interface wireguard peers

{{-   $ipv4_routes := coll.Slice }}
{{-   $ipv6_routes := coll.Slice }}
{{-   range $p := $i.peers }}
{{-     $p = merge $p $p_defaults }}
{{-     $allowed := coll.Slice }}

{{-     range $r := $p.routes }}
{{-       if (has $r "ipv4") }}
{{-         $allowed = $allowed | append $r.ipv4 }}
{{-         if (and $i.enabled $p.enabled) }}
{{-           $ipv4_routes = $ipv4_routes | append $r.ipv4 }}
{{-         end }}
{{-       end }}
{{-       if (has $r "ipv6") }}
{{-         $allowed = $allowed | append $r.ipv6 }}
{{-         if (and $i.enabled $p.enabled) }}
{{-           $ipv6_routes = $ipv6_routes | append $r.ipv6 }}
{{-         end }}
{{-       end }}
{{-     end }}

{{      template "item" (print $i.name "/" $p.name) }}

:if ( \
  [ :len [ find where interface="{{ $i.name }}" and public-key="{{ $p.key }}" ] ] = 0 \
) do={ add interface="{{ $i.name }}" public-key="{{ $p.key }}" }
set [ find where interface="{{ $i.name }}" and public-key="{{ $p.key }}" ] \
{{-       if (gt $p.keepalive 0) }}
    persistent-keepalive={{ $p.keepalive}}s \
{{-     end }}
{{-     if (has $p "endpoint") }}
    endpoint-address={{ $p.endpoint.address }} \
    endpoint-port={{ $p.endpoint.port }} \
{{-     end }}
    allowed-address={{ join $allowed "," }} \
    disabled={{ if $p.enabled }}no{{ else }}yes{{ end }} \
    comment="{{ $p.name }} ({{ $p.comment }})"

{{-     $has_ipv4_route := false }}
{{-     range $r := $p.routes }}

{{-       if (not (has $r "ipv4")) }}
{{-         continue }}
{{-       end }}

{{-       if (not $has_ipv4_route) }}
{{-         $has_ipv4_route = true }}

/ip route

{{-       end }}

:if ( \
  [ :len [ find where gateway="{{ $i.name }}" and dst-address="{{ $r.ipv4 }}" ] ] = 0 \
) do={ add gateway="{{ $i.name }}" dst-address="{{ $r.ipv4 }}" }
set [ find where gateway="{{ $i.name }}" and dst-address="{{ $r.ipv4 }}" ] \
  disabled={{ if (and $i.enabled $p.enabled) }}no{{ else }}yes{{ end }} \
  comment="{{ $i.comment }} ({{ $r.comment}} for {{ $p.comment }})"

{{-     end }}

{{-     $has_ipv6_route := false }}
{{-     range $r := $p.routes }}

{{-       if (not (has $r "ipv6")) }}
{{-         continue }}
{{-       end }}

{{-       if (not $has_ipv6_route) }}
{{-         $has_ipv6_route = true }}

/ipv6 route

{{-       end }}

:if ( \
  [ :len [ find where gateway="{{ $i.name }}" and dst-address="{{ $r.ipv6 }}" ] ] = 0 \
) do={ add gateway="{{ $i.name }}" dst-address="{{ $r.ipv6 }}" }
set [ find where gateway="{{ $i.name }}" and dst-address="{{ $r.ipv6 }}" ] \
  disabled={{ if (and $i.enabled $p.enabled) }}no{{ else }}yes{{ end }} \
  comment="{{ $i.comment }} ({{ $r.comment}} for {{ $p.comment }})"

{{-     end }}

{{-   end }}

/ip route

remove [
  find where gateway="{{ $i.name }}"
]

/ipv6 route

remove [
  find where gateway="{{ $i.name }}" \
]

{{- end }}

# Delete unknown peer
# Delete unknown Wireguard interfaces (including IP Addresses)

/interface wireguard

# How to remove route for deleted interfaces?

remove [
  find where !(
    name={{ conv.Join $interfaces " or \\\n    name=" }}
  )
]
