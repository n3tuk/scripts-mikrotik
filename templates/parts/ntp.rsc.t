# -- templates/parts/ntp.rsc.t
{{- /* vim:set ft=routeros: */}}

{{- $defaults := dict "enabled" true "comment" "" }}

{{- $ntp_servers := coll.Slice }}
{{- if (and (has (ds "host") "settings") (has (ds "host").settings "ntp_servers")) }}
{{-   $ntp_servers = (ds "host").settings.ntp_servers }}
{{- else if (and (has (ds "network") "settings") (has (ds "network").settings "ntp_servers")) }}
{{-   $ntp_servers = (ds "network").settings.ntp_servers }}
{{- end }}

# Update the NTP client settings on this host, if any are set, otherwise
# remove all NTP servers and disable the client. If NTP is set and this host
# is a router, allow it to be an NTP server for the network too.

{{  template "section" "Set up NTP" }}

/system ntp client servers
{{  if (eq (len $ntp_servers) 0) -}}
remove [ find where dynamic=no ]
{{- else -}}
{{-   range $s := $ntp_servers -}}
{{-     $s = merge $s $defaults }}
:if ( \
  [ :len [ find where address="{{ $s.address }}" ] ] = 0 \
) do={ add address="{{ $s.address }}" }
set [ find where address="{{ $s.address }}" ] \
    comment="{{ $s.comment }}" \
    disabled={{ if $s.enabled }}no{{ else }}yes{{ end }}
{{    end }}
remove [
  find where dynamic=no \
{{-   range $s := $ntp_servers -}}
{{-     $s = merge $s $defaults }}
         and address!="{{ $s.address }}" \
{{-   end }}
]
{{- end }}

/system ntp client
{{  if (gt (len $ntp_servers) 0) -}}
set enabled=yes \
    mode=unicast
{{- else -}}
set enabled=no
{{-  end }}

/system ntp server
{{ if (and (eq (ds "host").name "router") (gt (len $ntp_servers) 0)) -}}
set enabled=yes \
    manycast=yes \
    multicast=yes
{{- else -}}
set enabled=no
{{-  end }}
