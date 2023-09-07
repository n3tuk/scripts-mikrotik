# -- templates/parts/reset.rsc.t
{{- /* vim:set ft=routeros: */}}
# Reset a number of systems and services to a baseline (usually empty)
# configuration, ready for management by the remaining scripts, which will
# usually rely on the custom configuration being set to manage ongoing

{{  template "section" "Reset to Basic Settings" }}

/ip dns static
remove [ find ]

/ip firewall address-list
remove [ find where dynamic=no ]

/ipv6 firewall address-list
remove [ find where dynamic=no ]

/ip firewall raw
# Use the dynamic=no filter as we cannot remove these rules from the tables
remove [ find where dynamic=no ]

/ip firewall mangle
remove [ find where dynamic=no ]

/ip firewall nat
remove [ find where dynamic=no ]

/ip firewall filter
remove [ find where dynamic=no ]

/ipv6 firewall raw
# Use the dynamic=no filter as we cannot remove these rules from the tables
remove [ find where dynamic=no ]

/ipv6 firewall mangle
remove [ find where dynamic=no ]

/ipv6 firewall nat
remove [ find where dynamic=no ]

/ipv6 firewall filter
remove [ find where dynamic=no ]

/interface list
remove [ find where builtin=no ]

add name=internal \
    comment="contains all internal interfaces"
add name=external \
    comment="contains all external interfaces"
add name=management \
    comment="contains all internal interfaces for the management network"

/tool mac-server
set allowed-interface-list=management
/tool mac-server mac-winbox
set allowed-interface-list=management
/tool mac-server ping
set enabled={{ if (eq (ds "host").export "netinstall") }}yes{{ else }}no{{ end }}

/ip neighbor discovery-settings
set discover-interface-list="management" \
    lldp-med-net-policy-vlan=disabled \
    protocol="cdp,lldp,mndp" \
    mode="tx-and-rx"
