# -- templates/parts/firewall-raw-check-tcp.rsc.t
{{- /* vim:set ft=routeros: */}}
# Ensure that any TCP packets receive have the right combination of options,
# dropping anything which is invalid to prevent processing the connection.

{{- $keys := (coll.Slice "ip" "ipv6") }}
{{- $options := (coll.Slice "!fin,!syn,!rst,!ack"
                            "fin,syn"
                            "fin,rst"
                            "fin,!ack"
                            "fin,urg"
                            "syn,rst"
                            "rst,urg") }}

{{ template "item" "raw/check:tcp chain" }}

{{- range $keys }}

/{{ . }} firewall raw
{{-   range $option := $options }}

add chain="$runId:check:tcp" \
    protocol=tcp \
    tcp-flags={{ $option }} \
    action=drop \
    comment="Filter packets with invalid TCP flags"
{{-   end }}

add chain="$runId:check:tcp" \
    protocol=tcp \
    port=0 \
    action=drop \
    comment="Drop TCP packets to port 0"
{{- end }}
