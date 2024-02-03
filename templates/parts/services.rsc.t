# -- templates/parts/services.rsc.t
{{- /* vim:set ft=routeros: */}}
# Configure the standard services and their settings

{{  template "section" "Set up Standard Services" }}

/ip service

# These should never be accessed on any host, so disable and restrict the
# access to localhost only, just in case they are accidentally enabled
set ftp \
    address=127.0.0.1/32 \
    port=21 \
    disabled=yes

set telnet \
    address=127.0.0.1/32 \
    port=23 \
    disabled=yes

set www \
    address=127.0.0.0/32 \
    port=80 \
    disabled=yes

set api \
    address=127.0.0.0/32 \
    port=8728 \
    disabled=yes

set winbox \
    address={{ join (ds "network").ranges.internal "," }} \
    port=8291 \
    disabled=no

# These should be manually configured and enabled once the certificates are
# imported onto the host and associated with each of these services, so run a
# check to see if the certificates are installed before configuring the
# certificate and enabling or disabling the certificate

set www-ssl \
    address={{ join (ds "network").ranges.internal "," }} \
    port=443

set api-ssl \
    address={{ join (ds "network").ranges.internal "," }} \
    port=8729

:if ( \
  [ :len [ /certificate find where name="{{ (ds "host").name }}" ] ] > 0 \
) do={
  set www-ssl,api-ssl \
      certificate="{{ (ds "host").name }}" \
      tls-version=only-1.2 \
      disabled=no
} else={
  set www-ssl,api-ssl \
      certificate=none \
      tls-version=only-1.2 \
      disabled=yes
}

# TODO: Install Certificates for www-ssl and api-ssl services

# Disable these following services as they are not required and should not be
# used in any normal operation of this host

/ip proxy

:if ([get enabled]) do {
  set enabled=no
}

/ip socks

:if ([get enabled]) do {
  set enabled=no
}

/ip smb shares

# Disabling all SMB shares disabled the SMB service too
set [ find ] \
    disabled=yes

/ip smb users

set [ find default=no ] \
    disabled=yes

/ip upnp

:if ([get enabled]) do {
  set enabled=no
}

set allow-disable-external-interface=no \
    show-dummy-rule=no

/ip upnp interfaces

remove [ find ]

/ip cloud

set ddns-enabled=no \
    ddns-update-interval=none \
    update-time=no

/ip cloud advanced

set use-local-address=no

/snmp

:if ([get enabled]) do {
  set enabled=no
}

/tool bandwidth-server

:if ([get enabled]) do {
  set enabled=no
}

set authenticate=yes

/tool graphing

set page-refresh=60 \
    store-every=5min

/tool graphing interface
{{- range $address := (ds "network").ranges.internal }}

:if ( \
  [ :len [ find where allow-address={{ $address }} and interface=all ] ] = 0 \
) do={ add allow-address={{ $address }} interface=all }
set [ find where allow-address={{ $address }} and interface=all ] \
    store-on-disk=yes \
    disabled=no
{{- end }}

remove [
  find where not \
    !(    allow-address={{
      join (ds "network").ranges.internal " \\\n       or allow-address="
    }} )
]

/tool graphing queue
{{- range $address := (ds "network").ranges.internal }}

:if ( \
  [ :len [ find where allow-address={{ $address }} and simple-queue=all ] ] = 0 \
) do={ add allow-address={{ $address }} simple-queue=all }
set [ find where allow-address={{ $address }} and simple-queue=all ] \
    store-on-disk=yes \
    disabled=no
{{- end }}

remove [
  find where \
    !(    allow-address={{
      join (ds "network").ranges.internal " \\\n       or allow-address="
    }} )
]

/tool graphing resource
{{- range $address := (ds "network").ranges.internal }}

:if ( \
  [ :len [ find where allow-address={{ $address }} ] ] = 0 \
) do={ add allow-address={{ $address }} }
set [ find where allow-address={{ $address }} ] \
    store-on-disk=yes \
    disabled=no
{{- end }}

remove [
  find where \
    !(    allow-address={{
      join (ds "network").ranges.internal " \\\n       or allow-address="
    }} )
]

/system logging

add topics=critical \
    action=memory

/system logging action

set [ find where name="memory" ] \
    memory-lines={{ if (eq (ds "host").type "router") }}2500{{ else }}250{{ end }} \
    memory-stop-on-full=no

/interface detect-internet

set detect-interface-list=none \
    lan-interface-list=none \
    wan-interface-list=none \
    internet-interface-list=none
