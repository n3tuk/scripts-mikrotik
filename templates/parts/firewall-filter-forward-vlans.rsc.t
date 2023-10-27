# -- templates/parts/firewall-filter-forward-vlans.rsc.t
{{- /* vim:set ft=routeros: */}}

# Add rules for per-VLAN level access which should within the local network
# accessible through this router

{{  template "item" "filter/forward:vlans chain" }}

{{- $ipv4_options := (coll.Slice "src-address-list"
                                 "dst-address-list"
                                 "protocol"
                                 "src-port"
                                 "dst-port"
                                 "action") }}

{{- $ipv6_options := (coll.Slice "src-address-list"
                                 "dst-address-list"
                                 "protocol"
                                 "src-port"
                                 "dst-port"
                                 "action") }}

{{- range $vlan := (ds "network").vlans }}
{{-   if (and (has $vlan "firewall")
              (has $vlan.firewall "rules")) }}

{{  template "item" (print "filter/forward:vlans:" $vlan.name " chain") }}

/ip firewall filter

add chain="$runId:forward:vlans" \
    src-address-list="$runId:vlan:{{ $vlan.name }}" \
    connection-state=new \
    action=jump \
    jump-target="$runId:forward:vlan:{{ $vlan.name }}" \
    comment="Process rules for VLAN {{ $vlan.id }} ({{ $vlan.name }})"

{{-     range $rule := $vlan.firewall.rules }}

add chain="$runId:forward:vlan:{{ $vlan.name }}" \
{{-       range $option := $ipv4_options }}
{{-         if (has $rule $option) }}
{{-           if (or (eq $option "src-address-list") (eq $option "dst-address-list")) }}
    {{ $option }}="{{ if (strings.HasPrefix "!" (index $rule $option)) }}!{{ end }}$runId:{{ strings.TrimPrefix "!" (index $rule $option) }}" \
{{-           else }}
    {{ $option }}={{ index $rule $option }} \
{{-           end }}
{{-         end }}
{{-       end }}
    comment="{{ if (has $rule "comment") }}{{ $rule.comment }}{{ end }}"

{{-     end }}

/ipv6 firewall filter

add chain="$runId:forward:vlans" \
    src-address-list="$runId:vlan:{{ $vlan.name }}" \
    connection-state=new \
    action=jump \
    jump-target="$runId:forward:vlan:{{ $vlan.name }}" \
    comment="Process rules for VLAN {{ $vlan.id }} ({{ $vlan.name }})"

{{-     range $rule := $vlan.firewall.rules }}

add chain="$runId:forward:vlan:{{ $vlan.name }}" \
{{-       range $option := $ipv6_options }}
{{-         if (has $rule $option) }}
{{-           if (or (eq $option "src-address-list") (eq $option "dst-address-list")) }}
    {{ $option }}="{{ if (strings.HasPrefix "!" (index $rule $option)) }}!{{ end }}$runId:{{ strings.TrimPrefix "!" (index $rule $option) }}" \
{{-           else }}
    {{ $option }}={{ index $rule $option }} \
{{-           end }}
{{-         end }}
{{-       end }}
    comment="{{ if (has $rule "comment") }}{{ $rule.comment }}{{ end }}"
{{-     end }}

{{-   end }}
{{- end }}

/ip firewall filter

add chain="$runId:forward:vlans" \
    action=jump \
    jump-target="$runId:tarpit:drop" \
    comment="DROP all other connections and packets from internal VLANs"

/ipv6 firewall filter

add chain="$runId:forward:vlans" \
    action=jump \
    jump-target="$runId:tarpit:drop" \
    comment="DROP all other connections and packets from internal VLANs"
