# -- templates/parts/wireguard.rsc.t
{{- /* vim:set ft=routeros: */}}
# Configure the Wireguard VPN Service, setting up each of the required
# interfaces, and attaching the peers and IP addresses, and routing
# configurations needed.

{{- $i_defaults := coll.Dict "enabled" false "type" "ethernet" "vlan" "blocked" "comment" "" "mtu" 1420 "address" coll.Dict }}
{{- $p_defaults := coll.Dict "enabled" false "comment" "" "keepalive" 0 "routes" (coll.Slice) }}
{{- $r_defaults := coll.Dict "enabled" false "comment" "" }}
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

{{-   if (not (and (has (ds "host").secrets "wireguard")
                   (has (ds "host").secrets.wireguard "key"))) }}
{{-     continue }}
{{-   end}}

{{-   $interfaces = $interfaces | append $i.name }}

{{    template "item" $i.name }}

:if ( \
  [ :len [ find where name="{{ $i.name }}" ] ] = 0 \
) do={ add name="{{ $i.name }}" listen-port="{{ $i.port }}" private-key="{{ (ds "host").secrets.wireguard.key }}" }
set [ find where name="{{ $i.name }}" ] \
    private-key="{{ (ds "host").secrets.wireguard.key }}" \
    listen-port="{{ $i.port }}" \
    mtu={{ $i.mtu }} \
    disabled={{ if $i.enabled }}no{{ else }}yes{{ end }} \
    comment="{{ $i.comment }}"

{{-   $ipv4_routes := coll.Slice }}
{{-   $ipv6_routes := coll.Slice }}

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

{{  template "component" "Configure the Peers" }}

{{-   range $p := $i.peers }}
{{-     $p = merge $p $p_defaults }}
{{-     $allowed := coll.Slice }}

{{-     range $r := $p.routes }}
{{-       $r = merge $r $r_defaults }}
{{-       $r = $r | merge (coll.Dict "comment" (print $r.comment " for " $p.comment)
                                     "enabled" (and $i.enabled (and $p.enabled $r.enabled))) }}
{{-       if (has $r "ipv4") }}
{{-         $allowed = $allowed | append $r.ipv4 }}
{{-         if (and $i.enabled $p.enabled) }}
{{-           $ipv4_routes = $ipv4_routes | append $r }}
{{-         end }}
{{-       end }}
{{-       if (has $r "ipv6") }}
{{-         $allowed = $allowed | append $r.ipv6 }}
{{-         if (and $i.enabled $p.enabled) }}
{{-           $ipv6_routes = $ipv6_routes | append $r }}
{{-         end }}
{{-       end }}
{{-     end }}

{{      template "item" (print $i.name "/" $p.name) }}

:if ( \
  [ :len [ find where interface="{{ $i.name }}" and public-key="{{ $p.key }}" ] ] = 0 \
) do={ add interface="{{ $i.name }}" public-key="{{ $p.key }}" allowed-address={{ join $allowed "," }} }
set [ find where interface="{{ $i.name }}" and public-key="{{ $p.key }}" ] \
{{-       if (gt $p.keepalive 0) }}
    persistent-keepalive={{ $p.keepalive}}s \
{{-     end }}
{{-     if (has $p "endpoint") }}
    endpoint-address={{ $p.endpoint.address }} \
    endpoint-port={{ $p.endpoint.port }} \
{{-     end }}
{{-     if (and (has $p "psk")
                (and (has (ds "host").secrets.wireguard "psk")
                     (has (ds "host").secrets.wireguard.psk $p.psk))) }}
    preshared-key="{{ index (ds "host").secrets.wireguard.psk $p.psk }}" \
{{-     end }}
    allowed-address={{ join $allowed "," }} \
    disabled={{ if $p.enabled }}no{{ else }}yes{{ end }} \
    comment="{{ $p.name }} ({{ $p.comment }})"

{{-   end }}

{{  template "component" "Configure the Routes" }}

/ip route

{{-   range $r := $ipv4_routes }}

{{    template "item" $r.ipv4 }}

:if ( \
  [ :len [ find where gateway="{{ $i.name }}" and dst-address="{{ $r.ipv4 }}" ] ] = 0 \
) do={ add gateway="{{ $i.name }}" dst-address="{{ $r.ipv4 }}" }
set [ find where gateway="{{ $i.name }}" and dst-address="{{ $r.ipv4 }}" ] \
  disabled={{ if $r.enabled }}no{{ else }}yes{{ end }} \
  comment="{{ $i.comment }} ({{ $r.comment}})"

{{-   end }}

{{    template "item" "Cleanup IPv4 routes" }}

remove [
  find where \
      gateway="{{ $i.name }}" \
  and dynamic=no
{{-   if (gt (len $ipv4_routes) 0) }}
{{-     $routes := coll.Slice }}
{{-     range $r := $ipv4_routes }}
{{-       $routes = $routes | append $r.ipv4 }}
{{-     end }} \
  and !( dst-address={{ conv.Join $routes " \\\n      or dst-address=" }} )
{{-   end }}
]

/ipv6 route

{{-   range $r := $ipv6_routes }}

{{      template "item" $r.ipv6 }}

:if ( \
  [ :len [ find where gateway="{{ $i.name }}" and dst-address="{{ $r.ipv6 }}" ] ] = 0 \
) do={ add gateway="{{ $i.name }}" dst-address="{{ $r.ipv6 }}" }
set [ find where gateway="{{ $i.name }}" and dst-address="{{ $r.ipv6 }}" ] \
  disabled={{ if $r.enabled }}no{{ else }}yes{{ end }} \
  comment="{{ $i.comment }} ({{ $r.comment}})"

{{-   end }}

{{    template "item" "Cleanup IPv6 routes" }}

remove [
  find where \
        gateway="{{ $i.name }}" \
    and dynamic=no
{{-   if (gt (len $ipv6_routes) 0) }}
{{-     $routes := coll.Slice }}
{{-     range $r := $ipv6_routes }}
{{-       $routes = $routes | append $r.ipv6 }}
{{-     end }} \
    and !( dst-address={{ conv.Join $routes " \\\n      or dst-address=" }} )
{{-   end }}
]

/interface wireguard peers

{{  template "component" "Clean up Wireguard peers" }}

remove [
  find where interface=$i.name
{{-   if (gt (len $i.peers) 0) }}
{{-     $peers := coll.Slice }}
{{-     range $p := $i.peers }}
{{-       $peers = $peers | append $p.key }}
{{-     end}} and !({{ if (gt (len $i.peers) 1) }} \
      {{ end }} public-key="{{ conv.Join $peers "\" \\\n    or public-key=\"" }}" )
]
{{-   end }}

{{- end }}

# Delete unknown Wireguard interfaces (including IP Addresses)

/interface wireguard

remove [
  find
{{- if (gt (len $interfaces) 0) }} where !({{ if (gt (len $interfaces) 1) }} \
      {{ end }} name={{ conv.Join $interfaces " \\\n    or name=" }} )
{{- end }}
]
