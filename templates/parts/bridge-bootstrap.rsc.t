# -- templates/parts/bootstrap.rsc.t
{{- /* vim:set ft=routeros: */}}

{{- $bridge := (ds "host").bridge.name }}
{{- $original := (ds "host").bridge.name }}

{{- $management := 2 }}
{{- range $v := (ds "network").vlans }}
{{-   if (eq $v.name "management") }}
{{-     $management = $v.id }}
{{-   end }}
{{- end }}

{{  template "section" "Bootstrap the bridge interface" }}

/interface bridge

{{  template "component" "Prepare the bridge interface"}}

{{  template "item" (print $bridge " (rename from " $original ")") }}

:if ( \
  [ :len [ find where name={{ $original }} ] ] > 0 \
) do={
  set [ find where name={{ $original }} ] \
      name={{ $bridge }}
}

# Remove all other bridges which are not configured for this host
remove [ find where !( name={{ $bridge }} ) ]

# Ensure the bridge exists, and configure basic settings, as well as disabling
# vlan-filtering in order to prepare the VLAN configuration before enabling
:if ( \
  [ :len [ find where name={{ $bridge }} ] ] = 0 \
) do={ add name={{ $bridge }} auto-mac=yes }
set [ find where name={{ $bridge }} ] \
    auto-mac=yes \
    protocol-mode=none \
    vlan-filtering=no \
    ingress-filtering=no

# With the initial bridge configured with VLAN disabled, add all the interfaces
# as bridge ports (where enabled) with the VLAN settings, and then configure the
# required VLANs

{{  template "parts/bridge-ports.rsc.t" }}
{{  template "parts/vlans-required.rsc.t" }}

# With all bridge ports and VLANs configured, fully enable the bridge interface
# with VLAN support, MSTP protocols, and MSTI enabled

{{  template "parts/bridge-interface.rsc.t" }}

/interface bridge msti
:if ( \
  [ :len [ find where bridge={{ $bridge }} and identifier=1 ] ] = 0 \
) do={ add bridge={{ $bridge }} identifier=1 vlan-mapping={{ $management }} }
set [ find where bridge={{ $bridge }} and identifier=1 ] \
    vlan-mapping={{ $management }} \
    priority={{ if (has (ds "host").bridge "priority") }}{{ (ds "host").bridge.priority }}{{ else }}0x8000{{ end }}
