# -- templates/parts/firewall-filter.rsc.t
{{- /* vim:set ft=routeros: */}}
# All stateful processing of traffic to, from, and through, this host will go
# under the filter table via the INPUT, OUTPUT, and FORWARD chains,
# respectively.

{{  template "component" "filter table" }}
{{  template "parts/firewall-filter-reject.rsc.t" }}
{{- if (ne (ds "host").export "netinstall") }}
{{    template "parts/firewall-filter-tarpit.rsc.t" }}
{{- end }}
{{  template "parts/firewall-filter-check-icmp.rsc.t" }}
{{- if (ne (ds "host").export "netinstall") }}
{{    template "parts/firewall-filter-check-ssh.rsc.t" }}
{{    template "parts/firewall-filter-check-dns.rsc.t" }}
{{    template "parts/firewall-filter-check-ntp.rsc.t" }}
{{- end }}
{{  template "parts/firewall-filter-input.rsc.t" }}
{{  template "parts/firewall-filter-input-internal.rsc.t" }}
{{- if (ne (ds "host").export "netinstall") }}
{{    template "parts/firewall-filter-input-external.rsc.t" }}
{{    template "parts/firewall-filter-input-admin.rsc.t" }}
{{- end }}
{{  template "parts/firewall-filter-output.rsc.t" }}
{{  template "parts/firewall-filter-output-internal.rsc.t" }}
{{  template "parts/firewall-filter-output-external.rsc.t" }}
{{  template "parts/firewall-filter-forward.rsc.t" }}
{{  template "parts/firewall-cleanup.rsc.t" (coll.Slice "filter" "input" "forward" "output") -}}
