# -- templates/parts/firewall-raw-check-udp.rsc.t
{{- /* vim:set ft=routeros: */}}
# Ensure that any UDP packets receive have the right combination of options,
# dropping anything which is invalid to prevent processing the connection.

{{- $keys := (coll.Slice "ip" "ipv6") }}

{{ template "item" "raw/check:udp chain" }}

{{- range $keys }}

/{{ . }} firewall raw

add chain="$runId:check:udp" \
    protocol=udp \
    port=0 \
    action=drop \
    comment="Drop UDP packets to port 0"
{{- end}}
