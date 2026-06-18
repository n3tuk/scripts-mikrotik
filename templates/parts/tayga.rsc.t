# -- templates/parts/tayga.rsc.t
{{- /* vim:set ft=routeros: */}}
# Configure the Tayga NAT64 container for this host, including the virtual
# interface and the network routing.

{{- if (and (has (ds "host") "containers")
            (has (ds "host") "tayga")) }}

{{    template "section" "Configure the Virtual Interface" }}
{{-   $name := "tayga" }}
{{-   $bridge := (ds "host").containers.bridge.name }}
{{-   $interface := (ds "host").tayga.interface.name }}
{{-   $ipv4 := (ds "host").tayga.ipv4.address }}
{{-   $ipv6 := (ds "host").tayga.ipv6.address }}

/interface veth

{{    template "component" $interface }}
{{-   $gateway4 := index ((ds "host").containers.bridge.ipv4.address | strings.Split "/") 0 }}
{{-   $gateway6 := index ((ds "host").containers.bridge.ipv6.address | strings.Split "/") 0 }}

:if ( \
  [ :len [ find where name="{{ $interface }}" ] ] = 0 \
) do={ add name="{{ $interface }}" }
set [ find name="{{ $interface }}" ] \
    mac-address="{{ (ds "host").tayga.interface.mac.interface }}" \
    container-mac-address="{{ (ds "host").tayga.interface.mac.container }}" \
    address="{{ $ipv4 }},{{ $ipv6 }}" \
    disabled=no \
    dhcp=no \
    gateway="{{ $gateway4 }}" \
    gateway6="{{ $gateway6 }}" \
    comment="{{ (ds "host").tayga.comment }}"

/interface list member

:if ( \
  [ :len [ find where list="internal" and interface="{{ $interface }}" ] ] = 0 \
) do={ add list="internal" interface="{{ $interface }}" }
set [ find where list="internal" and interface="{{ $interface }}" ] \
    comment="{{ (ds "host").tayga.comment }}"

/interface bridge port

{{    template "component" (print $bridge "/" $interface) }}

:if ( \
  [ :len [ find where bridge="{{ $bridge }}" and interface="{{ $interface }}" ] ] = 0 \
) do={ add bridge="{{ $bridge }}" interface="{{ $interface }}" }
set [ find where bridge="{{ $bridge }}" and interface="{{ $interface }}" ] \
    point-to-point=auto \
    multicast-router=disabled \
    comment="{{ (ds "host").tayga.comment }}"

{{    template "section" "Configure the Routes" }}

/ip route

{{    $routed4 := (ds "host").tayga.ipv4.routed }}
{{-   template "component" $routed4 }}

:if ( \
  [ :len [ find where gateway="{{ $gateway4 }}" and dst-address="{{ $routed4 }}" ] ] = 0 \
) do={ add gateway="{{ $gateway4 }}" dst-address="{{ $routed4 }}" }
set [ find where gateway="{{ $gateway4 }}" and dst-address="{{ $routed4 }}" ] \
  disabled=no \
  comment="NAT64 Dynamic Pool ({{ (ds "host").tayga.comment }})"

/ipv6 route

{{    $routed6 := (ds "host").tayga.ipv6.routed }}
{{-   template "component" $routed6 }}

:if ( \
  [ :len [ find where gateway="{{ $gateway6 }}%{{ $bridge }}" and dst-address="{{ $routed6 }}" ] ] = 0 \
) do={ add gateway="{{ $gateway6 }}%{{ $bridge }}" dst-address="{{ $routed6 }}" }
set [ find where gateway="{{ $gateway6 }}%{{ $bridge }}" and dst-address="{{ $routed6 }}" ] \
  disabled=no \
  comment="NAT64 Translation Prefix ({{ (ds "host").tayga.comment }})"

{{    template "section" "Configure the Container" }}

/container envs

{{    template "component" "Environment Variables" }}

:if ( \
  [ :len [ find where list="{{ $name }}" and key="TAYGA_ADDR6" ] ] = 0 \
) do={ add list="{{ $name }}" key="TAYGA_ADDR6" value="" }
set [ find where list="{{ $name }}" and key="TAYGA_ADDR6" ] \
    value="{{ $ipv6 }}"

:if ( \
  [ :len [ find where list="{{ $name }}" and key="TAYGA_ADDR4" ] ] = 0 \
) do={ add list="{{ $name }}" key="TAYGA_ADDR4" value="" }
set [ find where list="{{ $name }}" and key="TAYGA_ADDR4" ] \
    value="{{ $ipv4 }}"

:if ( \
  [ :len [ find where list="{{ $name }}" and key="TAYGA_POOL4" ] ] = 0 \
) do={ add list="{{ $name }}" key="TAYGA_POOL4" value="" }
set [ find where list="{{ $name }}" and key="TAYGA_POOL4" ] \
    value="{{ $routed4 }}"

:if ( \
  [ :len [ find where list="{{ $name }}" and key="TAYGA_WKPF_STRICT" ] ] = 0 \
) do={ add list="{{ $name }}" key="TAYGA_WKPF_STRICT" value="" }
set [ find where list="{{ $name }}" and key="TAYGA_WKPF_STRICT" ] \
    value="no"

:if ( \
  [ :len [ find where list="{{ $name }}" and key="TAYGA_LOG" ] ] = 0 \
) do={ add list="{{ $name }}" key="TAYGA_LOG" value="" }
set [ find where list="{{ $name }}" and key="TAYGA_LOG" ] \
    value="drop reject icmp self dyn"

/container

:if ( \
  [ :len [ find where name="{{ $name }}" ] ] = 0 \
) do={

{{    template "component" "Container" }}

add name="{{ $name }}" \
    interface="{{ $interface }}" \
    remote-image="{{ (ds "host").tayga.image }}" \
    hostname="{{ $name }}" \
    envlist="{{ $name }}" \
    start-on-boot=yes \
    auto-restart-interval=10s \
    memory-high=67108864 \
    comment="{{ (ds "host").tayga.comment }}"

}

{{- end }}
