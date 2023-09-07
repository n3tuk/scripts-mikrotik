# -- templates/parts/users.rsc.t
{{- /* vim:set ft=routeros: */}}

{{- $defaults := coll.Dict "group" "read" "address" ((coll.Slice (ds "network").ranges.internal (ds "network").ranges.ssh) | coll.Flatten) "comment" "" "enabled" true }}

{{- $known := coll.Slice }}
{{- range $u, $v := (ds "network").users }}
{{-   $v = merge $v $defaults }}
{{-   if $v.enabled }}
{{-     $known = $known | append $u }}
{{-   end }}
{{- end }}

# Configure standard user settings, and then install or update the known users
# in the configuration and then, if present, attach the SSH keys to their
# accounts for remote SSH access. Note that only the default password is managed
# here. Changed and rotations are to be handled by the user on each host.

{{  template "section" "Set up Users" }}

/ip ssh
set always-allow-password-login=no \
    forwarding-enabled=no

{{  template "component" "Remove the Unknown/Deactivated Users" }}

/user ssh-keys
remove [
  find where !( \
       name={{
    conv.Join (coll.Sort $known) " \\\n    or name="
  }} )
]

/user
remove [
  find where !( \
       name={{
    conv.Join (coll.Sort $known) " \\\n    or name="
  }} )
]

{{  template "component" "Configure the Active Users" }}

{{- range $u, $v := (ds "network").users -}}
{{-   $v = merge $v $defaults }}
{{-   if $v.enabled }}

{{  template "item" $u }}

/user

:if ( \
  [ :len [ find where name={{ $u }} ] ] = 0 \
) do={
  # A password is required, but to prevent passwords in clear-text and enhance
  # security, all users will be set with a random password and must be reset by
  # the user if they SSH keys, as will be configured below (if set)
  :local password [
    :rndstr length=32 \
            from=0123456789aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ
  ]
  add name={{ $u }} \
      group={{ $v.group }} \
      password="$password" \
      address="{{ join $v.address "," }}"
}

set [ find where name={{ $u }} ] \
    group={{ $v.group }} \
    address="{{ join $v.address "," }}" \
    disabled={{ if $v.enabled }}no{{ else }}yes{{ end }} \
    comment="{{ $v.comment }}"

/user ssh-keys
{{-      if (has $v "keys") -}}
{{         range $k := $v.keys }}

:if ( \
  [ :len [ find where user={{ $u }} and key-owner={{ $k.name }} ] ] = 0 \
) do={
  /file
  :if ( \
    [ :len [ find where name={{ $k.name }}.pub ] ] > 0 \
  ) do={ remove {{ $k.name }}.pub }
  add name={{ $k.name }}.pub \
      contents="{{ $k.type }} {{ $k.contents | strings.ReplaceAll " " "" | strings.Trim "\n" }} {{ $k.name }}"
  # This is needed to ensure the file is ready for reading by the import
  :delay 300ms
  /user ssh-keys
  import user={{ $u }} \
         public-key-file={{ $k.name }}.pub
}
{{-        end -}}
{{-     end }}

remove [
  find where user={{ $u }}
{{-     if (has $v "keys") -}}
{{-       range $k := $v.keys }} \
         and key-owner!={{ $k.name }}
{{-       end }}
{{-     end }}
]

{{-   end -}}
{{- end -}}
