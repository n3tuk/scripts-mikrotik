# -- templates/parts/firewall.rsc.t
{{- /* vim:set ft=routeros: */}}
# Build the IPv4 and IPv6 firewall tables and chains

/ip settings
set allow-fast-path=yes \
    route-cache=yes \
    rp-filter=loose \
    accept-source-route=no \
    accept-redirects=no \
    secure-redirects=yes \
    send-redirects=no \
    tcp-syncookies=no

/ip firewall connection tracking
set enabled=yes

{{  template "section" "Set up Address Lists" }}
{{  template "parts/address-lists-vlans.rsc.t" }}
{{  template "parts/address-lists-custom.rsc.t" }}

{{  template "section" "Set up Firewall Tables" }}

{{  if (ne (ds "host").export "netinstall") -}}
{{    template "parts/firewall-raw.rsc.t" }}
{{    template "parts/firewall-mangle.rsc.t" }}
{{    template "parts/firewall-nat.rsc.t" }}
{{  end -}}

{{  template "parts/firewall-filter.rsc.t" }}
{{  template "parts/address-lists-cleanup.rsc.t" -}}
