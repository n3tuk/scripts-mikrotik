# -- templates/parts/containers.rsc.t
{{- /* vim:set ft=routeros: */}}
# Configure the Container bridge network for the host, including the bridge
# itself, and associated IP addresses.
#
# NOTE: This configuration does NOT enable the container service, as that is a
#       manual, one-time operation which required the rebooting of the host. See
#       the following documentation for more information on enabling the
#       container service:
#         https://help.mikrotik.com/docs/spaces/ROS/pages/84901929/Container

{{- if (has (ds "host") "containers") }}

{{-   template "section" "Configure the Bridge" }}
{{-   $bridge := (ds "host").containers.bridge.name }}

/interface bridge

# Container network for {{ (ds "host").name }}

{{    template "component" $bridge }}

# There will only be a single bridge in this configuration, and as such it is
# expected to be created through netinstall. This configuration does not try to
# be idempotent and simply updated the existing bridge settings.
set [ find where name={{ $bridge }} ] \
    auto-mac=yes \
    fast-forward=yes \
    protocol-mode=none \
    igmp-snooping=no \
    vlan-filtering=no \
    ingress-filtering=no \
    comment="{{ (ds "host").bridge.comment }}"
    comment="Container network for {{ (ds "host").name }}"

/ip address

{{    $ipv4 := (ds "host").containers.bridge.ipv4.address }}
{{-   template "item" $ipv4 }}

:if ( \
  [ :len [ find where interface="{{ $bridge }}" ] ] = 0 \
) do={ add interface="{{ $bridge }}" address="{{ $ipv4 }}" }
set [ find where interface="{{ $bridge }}" ] \
    address="{{ $ipv4 }}" \
    comment="Container network for {{ (ds "host").name }}"

/ipv6 address

{{    $ipv6 := (ds "host").containers.bridge.ipv6.address }}
{{-   template "item" $ipv6 }}

:if ( \
  [ :len [ find where interface="{{ $bridge }}" and dynamic=no ] ] = 0 \
) do={ add interface="{{ $bridge }}" address="{{ $ipv6 }}" }
set [ find where interface="{{ $bridge }}" ] \
    address="{{ $ipv6 }}" \
    eui-64=no \
    no-dad=yes \
    advertise=no \
    disabled=no \
    comment="{{ (ds "host").containers.bridge.comment }}"

{{- end }}
