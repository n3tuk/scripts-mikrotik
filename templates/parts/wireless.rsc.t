# -- templates/parts/wireless.rsc.t
{{- /* vim:set ft=routeros: */}}
# Configure the wireless interfaces for this host to set up them up as access points
# for wireless clients to connect to, and then connect them to the appropriate
# Bridge and VLANs for passing traffic across

{{- $v_defaults := coll.Dict "enabled" true "comment" "VLAN" }}
{{- $i_defaults := coll.Dict "enabled" false "type" "ethernet" "vlan" "blocked" "comment" "Unused" }}

{{  template "component" "Configure the wireless Profiles" }}

/interface wireless security

{{- $profiles := coll.Slice }}
{{- range $v := (ds "network").vlans }}
{{-   $v := merge $v $v_defaults }}
{{-   if (has $v "wireless") }}
{{-     $profiles = $profiles | append $v.name }}
{{-     $psk := "" }}
{{-     if (and (and (has $v.wireless "psk") (has $v.wireless.psk "secret"))
                (has (ds "network").secrets.wireless $v.wireless.psk.secret)) }}
{{-       $psk = (index (ds "network").secrets.wireless $v.wireless.psk.secret) }}
{{-     end }}

{{      template "item" $v.name }}

:if ( \
  [ :len [ find where name="{{ $v.name }}" ] ] = 0 \
) do={ add name="{{ $v.name }}" }

set [ find where name="{{ $v.name }}" ] \
{{-     if (eq $psk "") }}
    mode=none
{{-     else }}
    mode=dynamic-keys \
    authentication-types=wpa2-psk \
    wpa2-pre-shared-key="{{ index (ds "network").secrets.wireless $v.wireless.psk.secret }}"
{{-     end }}

{{-   end }}
{{- end }}

{{  template "component" "Configure the wireless Interfaces" }}

/interface wireless

{{- range $i := (ds "host").interfaces }}
{{-   $i = merge $i $i_defaults }}
{{-   if (ne $i.type "wireless") }}
{{-     continue }}
{{-   end }}

{{    template "item" $i.name }}

{{-   $master := coll.Dict }}
{{-   range $v := (ds "network").vlans }}
{{-     $v := merge $v $v_defaults }}
{{-     if (and (eq $v.name $i.vlan)
                (has $v "wireless")) }}
{{-       $master = $v }}
{{-     end }}
{{-   end }}

{{-   if (eq (len $master) 0) }}

set [ find where name="{{ $i.name }}" ] \
    ssid="MikroTik" \
    security-profile="default" \
    disabled=yes \
    comment="Unused"

{{-   else }}

set [ find where name="{{ $i.name }}" ] \
    mode=ap-bridge \
    bridge-mode=enabled \
    wireless-protocol=802.11 \
    installation=indoor \
    frequency-mode=regulatory-domain \
    country="{{ (ds "network").settings.wireless.country }}" \
    wmm-support=enabled \
{{-     if (and (has $i "frequency") (lt $i.frequency 5000)) }}
    tx-power-mode=all-rates-fixed \
    tx-power=10 \
    band=2ghz-b/g/n \
    channel-width=20mhz \
    frequency={{ $i.frequency }} \
{{-     else if (and (has $i "frequency") (lt $i.frequency 6000)) }}
    band=5ghz-n/ac \
    channel-width=20/40/80mhz-XXXX \
    frequency={{ $i.frequency }} \
{{-     end }}
    ssid="{{ $master.wireless.ssid }}" \
    security-profile="{{ $master.name }}" \
    wps-mode=disabled \
    vlan-mode=no-tag \
    vlan-id=1 \
    multicast-helper=full \
    multicast-buffering=enabled \
    keepalive-frames=enabled \
    disabled=no \
    comment="{{ $master.comment }}"

{{-   end }}

{{-   $virtuals := coll.Slice }}
{{-   $virtual_names := coll.Slice }}
{{-   if (has $i "vlans") }}
{{-     range $vlan := $i.vlans }}
{{-       range $v := (ds "network").vlans }}
{{-         $v := merge $v $v_defaults }}
{{-         if (and $v.enabled
                    (and (eq $v.name $vlan)
                         (lt (len $virtuals) 3))) }}
{{-           $virtuals = $virtuals | append $v }}
{{-           $virtual_names = $virtual_names | append (print $i.name "." $v.id)}}
{{-         end }}
{{-       end }}
{{-     end }}
{{-   end }}

/interface wireless

# Remove any virtual wireless interfaces which we do not expect based on the
# configuration, as this must be done first before we can add any to ensure we
# do not exceed the limits on virtual interfaces
remove [
  find where interface-type=virtual \
         and master-interface={{ $i.name }}
{{-   if (gt (len $virtual_names) 0) }} \
         and !( name={{ join $virtual_names " \\\n             or name=" }} )
{{-   end }}
]

{{-   range $virtual := $virtuals }}

{{    template "item" (print $i.name "." $virtual.id) }}

:if ( \
  [ :len [ find where interface-type=virtual \
                  and master-interface="{{ $i.name }}" \
                  and name="{{ $i.name }}.{{ $virtual.id }}" ] ] = 0 \
) do={
  # Add as disabled as so to not open an unencrypted network by accident
  add master-interface="{{ $i.name }}" \
      name="{{ $i.name }}.{{ $virtual.id }}" \
      disabled=yes
}

set [ find where name="{{ $i.name }}.{{ $virtual.id }}" ] \
    ssid="{{ $virtual.wireless.ssid }}" \
    security-profile="{{ $virtual.name }}" \
    wps-mode=disabled \
    disabled=no \
    comment="{{ $virtual.comment }}"

{{-   end }}

{{- end }}

/interface wireless security-profiles

remove [
  find where default=no
{{-   if (gt (len $profiles) 0) }} \
         and !( name={{ join $profiles " \\\n             or name=" }} )
{{-   end }}
]
