# -- templates/parts/firewall-filter-forward-rules.rsc.t
{{- /* vim:set ft=routeros: */}}

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

# Add rules for network-level access which should be applied to one or more
# VLANs within the local network accessible through this router

{{- if (and (has (ds "network").firewall "forwarding")
            (has (ds "network").firewall.forwarding "rules")) }}

{{  template "item" "filter/forward:rules chain" }}

/ip firewall filter

{{-   range $rule := (ds "network").firewall.forwarding.rules }}

add chain="$runId:forward:rules" \
{{-     range $option := $ipv4_options }}
{{-       if (has $rule $option) }}
{{-         if (or (eq $option "src-address-list") (eq $option "dst-address-list")) }}
    {{ $option }}="{{ if (strings.HasPrefix "!" (index $rule $option)) }}!{{ end }}$runId:{{ strings.TrimPrefix "!" (index $rule $option) }}" \
{{-         else }}
    {{ $option }}={{ index $rule $option }} \
{{-         end }}
{{-       end }}
{{-     end }}
    comment="{{ if (has $rule "comment") }}{{ $rule.comment }}{{ end }}"

{{-   end }}

/ipv6 firewall filter

{{-   range $rule := (ds "network").firewall.forwarding.rules }}

add chain="$runId:forward:rules" \
{{-     range $option := $ipv6_options }}
{{-       if (has $rule $option) }}
{{-         if (or (eq $option "src-address-list") (eq $option "dst-address-list")) }}
    {{ $option }}="{{ if (strings.HasPrefix "!" (index $rule $option)) }}!{{ end }}$runId:{{ strings.TrimPrefix "!" (index $rule $option) }}" \
{{-         else }}
    {{ $option }}={{ index $rule $option }} \
{{-         end }}
{{-       end }}
{{-     end }}
    comment="{{ if (has $rule "comment") }}{{ $rule.comment }}{{ end }}"
{{-   end }}

{{- end }}
