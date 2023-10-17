# -- templates/parts/firewall-filter-forward-vlans.rsc.t
{{- /* vim:set ft=routeros: */}}

# Add rules for per-VLAN level access which should within the local network
# accessible through this router

{{  template "item" "filter/forward:vlans chain" }}

{{- $ipv4_options := (coll.Slice "dst-address-list"
                                 "protocol"
                                 "src-port"
                                 "dst-port"
                                 "action") }}

{{- $ipv6_options := (coll.Slice "dst-address-list"
                                 "protocol"
                                 "src-port"
                                 "dst-port"
                                 "action") }}

{{- range $vlan := (ds "network").vlans }}
{{-   if (and (has $vlan "firewall")
              (has $vlan.firewall "rules")) }}

# {{ (ds "host").bridge.name }}.{{ $vlan.id }}
#   {{ $vlan.comment | strings.WordWrap 76 "\n#   " }}

/ip firewall filter

{{-     range $rule := $vlan.firewall.rules }}

add chain="$runId:forward:vlan:{{ $vlan.name }}" \
{{-       range $option := $ipv4_options }}
{{-         if (has $rule $option) }}
{{-           if (eq $option "dst-address-list") }}
    {{ $option }}="{{ if (strings.HasPrefix "!" (index $rule $option)) }}!{{ end }}$runId:{{ strings.TrimPrefix "!" (index $rule $option) }}" \
{{-           else }}
    {{ $option }}={{ index $rule $option }} \
{{-           end }}
{{-         end }}
{{-       end }}
    comment="{{ if (has $rule "comment") }}{{ $rule.comment }}{{ end }}"

{{-     end }}

add chain="$runId:forward" \
    src-address-list="$runId:vlan:{{ $vlan.name }}" \
    connection-state=new \
    action=jump jump-target="$runId:forward:vlan:{{ $vlan.name }}" \
    comment="Process rules for VLAN {{ $vlan.id }} ({{ $vlan.name }})"

/ipv6 firewall filter

{{-     range $rule := $vlan.firewall.rules }}

add chain="$runId:forward:vlan:{{ $vlan.name }}" \
{{-       range $option := $ipv6_options }}
{{-         if (has $rule $option) }}
{{-           if (eq $option "dst-address-list") }}
    {{ $option }}="{{ if (strings.HasPrefix "!" (index $rule $option)) }}!{{ end }}$runId:{{ strings.TrimPrefix "!" (index $rule $option) }}" \
{{-           else }}
    {{ $option }}={{ index $rule $option }} \
{{-           end }}
{{-         end }}
{{-       end }}
    comment="{{ if (has $rule "comment") }}{{ $rule.comment }}{{ end }}"
{{-     end }}

add chain="$runId:forward" \
    src-address-list="$runId:vlan:{{ $vlan.name }}" \
    connection-state=new \
    action=jump jump-target="$runId:forward:vlan:{{ $vlan.name }}" \
    comment="Process rules for VLAN {{ $vlan.id }} ({{ $vlan.name }})"

{{-   end }}
{{- end }}
