# -- templates/parts/firewall-filter-forward-settings.rsc.t
{{- /* vim:set ft=routeros: */}}
# Configure the IPv4 and IPv6 settings on the host, ensuring that IP forwarding
# is disabled on non-routing hosts, and we're running strict filters for route
# sources on routing hosts too.

{{  template "item" "ip settings" }}

/ip settings

set accept-redirects=no \
    secure-redirects=yes \
    send-redirects=no \
    allow-fast-path=yes \
    tcp-syncookies=no

{{- if (and (ne (ds "host").export "netinstall")
            (eq (ds "host").type "router")) }}

set ip-forward=yes \
    rp-filter=strict

{{- else }}

set ip-forward=no \
    rp-filter=loose

{{- end }}

{{  template "item" "ipv6 settings" }}

/ipv6 settings

set disable-ipv6=no \
    accept-redirects=no

{{- if (and (ne (ds "host").export "netinstall")
            (eq (ds "host").type "router")) }}

set forward=yes \
    accept-router-advertisements=no

{{- else }}

set forward=no \
    accept-router-advertisements=yes

{{- end }}
