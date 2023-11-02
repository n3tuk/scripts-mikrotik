# -- templates/parts/vlans-remove.rsc.t
{{- /* vim:set ft=routeros: */}}

{{- $bridge := (ds "host").bridge.name }}
{{- $v_defaults := coll.Dict "enabled" true "comment" "" }}

{{- $comment := false -}}
{{- range $v := (ds "network").vlans -}}
{{-   $v = merge $v $v_defaults }}

{{-   $interface := print $bridge "." (printf "%02d" $v.id) }}

{{-   if (not $v.enabled) -}}
{{-     if (not $comment) -}}
{{-       $comment = true }}

# Find and remove all the VLANs which are configured, but set to disabled, and
# remove them from the bridges they are associated with, ready for their
# eventual removal from the shared configuration file

{{        template "component" "Remove Deactivated VLANs" }}
{{-     end }}

{{      template "item" $interface }}

/ip dhcp-server lease
remove [ find where server="{{ $v.name }}" ]
/ip dhcp-server
remove [ find where interface="{{ $interface }}" ]
/ip pool
remove [ find where name="{{ $v.name }}" ]

{{-     if (has $v "ipv4") }}
{{-       $network := (index ((net.ParseIPPrefix $v.ipv4.address).Range | strings.Split "-") 0) }}
{{        $prefix := (index ($v.ipv4.address | strings.Split "/") 1) }}
/ip dhcp-server network
remove [ find where address="{{ $network }}/{{ $prefix }}" ]
/ip firewall address-lists
remove [ find where address="{{ $network }}/{{ $prefix }}" ]
{{-     end }}

/ipv6 dhcp-server lease
remove [ find where server="{{ $v.name }}" ]
/ipv6 dhcp-server
remove [ find where interface="{{ $interface }}" ]
/ipv6 pool
remove [ find where name="{{ $v.name }}" ]

/ipv6 nd
remove [ find where interface="{{ $interface }}" ]
/ipv6 nd prefix
remove [ find where interface="{{ $interface }}" ]

{{-     if (has $v "ipv6") }}
{{-       $network := (index ((net.ParseIPPrefix $v.ipv6.address).Range | strings.Split "-") 0) }}
{{        $prefix := (index ($v.ipv6.address | strings.Split "/") 1) }}
/ipv6 dhcp-server network
remove [ find where address="{{ $network }}/{{ $prefix }}" ]
/ipv6 firewall address-lists
remove [ find where address="{{ $network }}/{{ $prefix }}" ]
{{-     end }}

/ip address
remove [ find where interface="{{ $interface }}" ]
/ipv6 address
remove [ find where interface="{{ $interface }}" ]

/interface vlan
remove [ find where interface="{{ $bridge }}" and vlan-ids={{ $v.id }} ]
/interface bridge vlan
remove [ find where bridge="{{ $bridge }}" and vlan-ids={{ $v.id }} ]
{{-   end }}
{{- end }}
