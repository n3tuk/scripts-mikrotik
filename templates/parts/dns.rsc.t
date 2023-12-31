# -- templates/parts/dns.rsc.t
{{- /* vim:set ft=routeros: */}}
# Configure the standard DNS settings, and configure any required static DNS
# records which are required, for example, for DNS over HTTPS or DNS over TLS,
# which host must know the entries if the certificates are to be validated.

{{- $defaults := coll.Dict "enabled" true "ttl" "1h" "comment" "" }}

{{  template "section" "Set up DNS" }}

{{  template "component" "Configure the DNS Records" }}

/ip dns static

{{  range $r := (ds "network").dns.static }}
{{-   $r = merge $r $defaults -}}
# {{ $r.name }} ({{ $r.comment }})

{{    template "item" $r.name }}

{{-   if (not $r.enabled) }}
remove [ find where name={{ $r.name }} ]
{{-   else }}
{{-     range $a := $r.addresses }}

{{-       $type := (print "type=\"" $a.type "\"")}}
{{-       if (eq $a.type "A") }}
{{-         $type = "!type" }}
{{-       end }}

:if ( \
  [ :len [ find where name="{{ $r.name }}" and {{ $type }} and address="{{ $a.address }}" ] ] = 0 \
) do={ add name="{{ $r.name }}" type="{{ $a.type }}" address="{{ $a.address }}" }
set [ find where name="{{ $r.name }}" and {{ $type }} and address="{{ $a.address }}" ] \
    ttl="{{ $r.ttl }}" \
    comment="{{ $r.comment }}"

{{-     end }}

remove [
  find name="{{ $r.name }}"
{{-     range $a := $r.addresses }} \
   and !({{ if (eq $a.type "A") }}!type{{ else }}type="{{ $a.type }}"{{ end }} and address="{{ $a.address }}")
{{-     end }}
]
{{    end }}
{{  end }}

{{-  if (ne (ds "host").export "netinstall") -}}

{{  template "component" "Configure the Certificate Authorities" }}

{ :do {

{{  template "item" "Get the Certificate Authorities File" }}

/ip dns
# Disable verifying DoH certificates to ensure that we can process the DNS
# requests to fetch the Certificate Authorities which will validate DoH
set verify-doh-cert=no

/tool fetch \
  url="https://curl.se/ca/cacert.pem" \
  check-certificate=no \
  dst-path="cacert.pem"

# This is needed to ensure the file is ready for the import
:delay 300ms

/certificate

{{  template "component" "Remove the Expired Certificates" }}

remove [ find where name ~ "^ca" and authority expired ]

{{  template "component" "Import the New Certificates" }}

import file-name="cacert.pem" name="ca"

/file
remove "cacert.pem"

} on-error={

{{  template "error" "Failed to update Certificate Authorities" }}

}; }

{{  end -}}

{{  template "component" "Configure the DNS Settings" }}

/ip dns
{{  if (eq (ds "host").type "router") -}}
# This host is a router, so allow remote requests within the network
# (protected via the firewall configuration for this host)
set allow-remote-requests=yes
{{  end }}
# Remove all upstream DNS servers and use DNS over HTTPS via Cloudflare
set use-doh-server="{{ (ds "network").dns.resolver.doh }}" \
    verify-doh-cert={{ if (eq (ds "host").export "netinstall") }}no{{ else }}yes{{ end }} \
    doh-max-concurrent-queries=128 \
    doh-max-server-connections=32 \
    doh-timeout=1m

# Configure standard settings in case of temporary fall-back to traditional DNS
set cache-max-ttl=1d \
    cache-size=2048KiB \
    max-concurrent-queries=512 \
    max-concurrent-tcp-sessions=128 \
    max-udp-packet-size=4096 \
    query-server-timeout=2s \
    query-total-timeout=10s
