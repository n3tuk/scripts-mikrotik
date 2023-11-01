# -- templates/parts/services.rsc.t
{{- /* vim:set ft=routeros: */}}
# Configure the standard services and their settings

{{  template "section" "Set up Standard Services" }}

/ip service
# These should never be accessed on any host, so disable and restrict the
# access to localhost only, just in case they are accidentally enabled
set ftp disabled=yes \
    address=127.0.0.1/32 port=21
set telnet disabled=yes \
    address=127.0.0.1/32 port=23
set www disabled=yes \
    address=127.0.0.0/32 port=80
set api disabled=yes \
    address=127.0.0.0/32 port=8728
set winbox disabled=no \
    address={{ join (ds "network").ranges.internal "," }} port=8291
# These should be manually configured and enabled once the certificates are
# imported onto the host and associated with each of these services
set www-ssl disabled=yes \
    address={{ join (ds "network").ranges.internal "," }} port=443 \
    certificate=none tls-version=only-1.2
set api-ssl disabled=yes \
    address={{ join (ds "network").ranges.internal "," }} port=8729 \
    certificate=none tls-version=only-1.2

# TODO: Install Certificates for www-ssl and api-ssl services

# Disable these following services as they are not required and should not be
# used in any normal operation of this host
/ip proxy
set enabled=no
/ip socks
set enabled=no
/ip smb
set enabled=no
/ip smb shares
set [ find ] \
    disabled=yes
/ip smb users
set [ find default=no ] \
    disabled=yes

/ip upnp
set enabled=no \
    allow-disable-external-interface=no \
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
set enabled=no

/tool bandwidth-server
set enabled=no \
    authenticate=yes

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
