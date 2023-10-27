# -- templates/parts/firewall-cleanup.rsc.t
{{- /* vim:set ft=routeros: */}}
{{- /* Once all the rules in each of the chains are configured, and the initial
       jumps in the default chains are appended, the old jumps can be removed
       and in effect swap out the old firewall chains for the new in a single
       command, allowing (in theory) the traffic to be cut over without the
       firewall ever being in an interim state, or only being partially
       configured if the script fails */}}

{{- $keys := coll.Slice "ip" "ipv6" }}

{{- /* GoSlice isn't working properly, so hack a solution */}}
{{- $table := "" }}
{{- $chains := coll.Slice }}
{{- range $i := .}}
{{-   if (eq $table "") }}
{{-     $table = $i }}
{{-   else }}
{{-     $chains = $chains | append $i }}
{{-   end }}
{{- end }}

{{  template "item" (print $table " cleanup") }}

{{- range $keys }}

/{{ . }} firewall {{ $table }}

remove [
  find where ( chain={{ join $chains " or chain=" }} ) \
         and ( ( action=jump and !( jump-target~"^$runId:" ) ) or action!=jump ) \
         and dynamic=no
]

{{- end }}

# Clean up all chains which are neither default nor the current version
{{  range $keys }}
/{{ . }} firewall {{ $table }}

remove [
  find where !( chain~"^$runId:" or chain={{
    join $chains " or chain="
  }} )
]
{{  end -}}
