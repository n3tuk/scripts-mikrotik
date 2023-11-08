# -- templates/parts/users.rsc.t
{{- /* vim:set ft=routeros: */}}

{{- $defaults := coll.Dict "group" "read" "address" ((coll.Slice (ds "network").ranges.internal (ds "network").ranges.ssh) | coll.Flatten) "comment" "" "enabled" true }}

{{- $known := coll.Slice }}
{{- range $u := (ds "network").users }}
{{-   $u = merge $u $defaults }}
{{-   if $u.enabled }}
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

{{  template "component" "Configure the Active Users" }}

{{- range $u := (ds "network").users -}}
{{-   $u = merge $u $defaults }}
{{-   if $u.enabled }}

{{  template "item" $u.name }}

/user

:if ( \
  [ :len [ find where name={{ $u.name }} ] ] = 0 \
) do={
  # A password is required, but to prevent passwords in clear-text and enhance
  # security, all users will be set with a random password and must be reset by
  # the user if they SSH keys, as will be configured below (if set)
  :local password [
    :rndstr length=32 \
            from=0123456789aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ
  ]
  add name={{ $u.name }} \
      group={{ $u.group }} \
      password="$password" \
      address="{{ join $u.address "," }}"
}

set [ find where name={{ $u.name }} ] \
    group={{ $u.group }} \
    address="{{ join $u.address "," }}" \
    disabled={{ if $u.enabled }}no{{ else }}yes{{ end }} \
    comment="{{ $u.comment }}"

/user ssh-keys
{{-      if (has $u "keys") -}}
{{         range $k := $u.keys }}

:if ( \
  [ :len [ find where user={{ $u.name }} and key-owner={{ $k.name }} ] ] = 0 \
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
  import user={{ $u.name }} \
         public-key-file={{ $k.name }}.pub
}
{{-        end -}}
{{-     end }}

remove [
  find where user={{ $u.name }}
{{-     if (has $u "keys") -}}
{{-       range $k := $u.keys }} \
         and key-owner!={{ $k.name }}
{{-       end }}
{{-     end }}
]

{{-   end }}
{{- end }}

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
