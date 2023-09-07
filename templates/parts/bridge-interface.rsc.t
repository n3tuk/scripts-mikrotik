# -- templates/parts/bridge-interface.rsc.t
{{- /* vim:set ft=routeros: */}}

{{- $bridge := (ds "host").bridge.name }}
{{- $v_defaults := dict "enabled" true "comment" "VLAN" }}

{{  template "component" "Configure the Bridge" }}

/interface bridge

# {{ (ds "host").bridge.comment }}

{{    template "item" $bridge }}

# There will only be a single bridge in this configuration, and as such it is
# expected to be created through netinstall. This configuration does not try to
# be idempotent and simply updated the existing bridge settings.
set [ find where name={{ $bridge }} ] \
    auto-mac=yes \
    fast-forward=yes \
    protocol-mode=mstp \
    region-name={{ (ds "network").mstp.region }} \
    region-revision={{ (ds "network").mstp.revision }} \
    priority={{ if (has (ds "host").bridge "priority") }}{{ (ds "host").bridge.priority }}{{ else }}0x8000{{ end }} \
{{- /* igmp-snooping must be disabled for IPv6 to work */}}
    igmp-snooping=no \
    vlan-filtering=yes \
    frame-types=admit-only-vlan-tagged \
    ether-type=0x8100 \
    ingress-filtering=yes \
    pvid=1 \
    comment="{{ (ds "host").bridge.comment }}"
