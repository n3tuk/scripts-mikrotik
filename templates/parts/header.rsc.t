# RouterOS Configuration Script
{{- /* vim:set ft=routeros: */}}

{{- /* This header is included by all exports, so the following section will
       define a set of common templates used to facilitate the processing of
       outputs for the script and user. */}}

{{- define "section" -}}
:log info "{{ (ds "host").export }}.rsc/$runId: {{ . }}"
{{-   if (not (eq (ds "host").export "netinstall")) }}
:put "╶──>                                             "
:terminal cuu
:put "╶──> {{ . }}"
{{-   end -}}
{{- end }}

{{- define "error" -}}
:log error "{{ (ds "host").export }}.rsc/$runId: {{ . }}"
{{-   if (not (eq (ds "host").export "netinstall")) }}
:put ""
:terminal style error
:put " ╶─> {{ . }}"
:terminal style none
{{-   end -}}
{{- end }}

{{- define "component" -}}
:log info "{{ (ds "host").export }}.rsc/$runId: {{ . }}"
{{-   if (not (eq (ds "host").export "netinstall")) }}
:put " ╶─>                                             "
:terminal cuu
:put " ╶─> {{ . }}"
{{-   end -}}
{{- end }}

{{- define "item" -}}
:log info "{{ (ds "host").export }}.rsc/$runId: {{ . }}"
{{-   if (not (eq (ds "host").export "netinstall")) }}
:put "  ╶>                                             "
:terminal cuu
:put "  ╶> {{ . }}"
:terminal cuu
{{-   end -}}
{{- end }}

{{- define "debug" -}}
:log debug "{{ (ds "host").export }}.rsc/$runId: {{ . }}"
{{- end }}
#
#        Host: {{ (ds "host").name }}
#      Export: {{ if (eq (ds "host").export "netinstall") }}netinstall{{ else }}{{ . }} Update{{ end }} Script
#        Date: {{ (ds "host").date }}
#       Model: {{ (ds "host").model }}
# Description: {{ (ds "host").description | strings.ReplaceAll "\n" " " | strings.WordWrap 64 "\n#              " }}
#
{{  if (eq (ds "host").export "netinstall") -}}
# To use this script, run the netinstall utility from Mikrotik with the current
# version of the image for the selected host and the path to this file. This
# will configure the script to run on install and any reset of the host:
#
# $ netinstall-cli -r \
#       -i {interface} -s exports/{{ (ds "host").name }}-netinstall.rsc \
#     routeros-{version}.npk
{{- else -}}
# To run this script, SCP this file over to the host as the admin user (or
# whatever user set up for administrative access) and run it with /import:
#
# $ scp {{ (ds "host").name }}-{{ (ds "host").export }}.rsc admin@{{ (ds "host").name }}:{{ (ds "host").export }}.rsc
# $ ssh admin@{{ (ds "host").name }} /import {{ (ds "host").export }}.rsc
{{- end }}

# Create a runId which can be used by some parts of the script to create new
# resources in parallel to existing ones before swapping them over, making the
# changes, in effect, atomic and reducing the risk of mishandling live traffic
:local runId [ :rndstr length=6 from=0123456789abcdef ]

:log info "{{ (ds "host").export }}.rsc/$runId: {{ (ds "host").name }} (built {{ (ds "host").date }})"

{{- $i_defaults := coll.Dict "enabled" false "type" "ethernet" "vlan" "blocked" "comment" "Unused" }}

{{- if (eq (ds "host").export "netinstall") }}

{{-   $ethernet := 0 }}
{{-   $wireless := 0 }}

{{-   range $i := (ds "host").interfaces }}
{{-     $i = merge $i $i_defaults }}
{{-     if (eq $i.type "ethernet") }}
{{-       $ethernet = $ethernet | math.Add 1 }}
{{-     end }}
{{-     if (eq $i.type "wireless") }}
{{-       $wireless = $wireless | math.Add 1 }}
{{-     end }}
{{-   end }}

{
  # The time to wait for the ethernet interfaces to come up during the check
  :local t 60
  :local i 0

  :log info "{{ (ds "host").export }}.rsc/$runId: Waiting for interfaces to come up..."

  # Check every second for the number of interfaces available so we can continue
  while ( \
    $i < $t \
{{-   if (eq $wireless 0) }}
    && [ :len [ /interface ethernet find ] ] = 0 \
{{-   else }}
    && (    [ :len [ /interface ethernet find ] ] = 0 \
         || [ :len [ /interface wireless find ] ] = 0 ) \
{{-   end }}
  ) do={
    :set $i ($i + 1)
    :delay 1s
  }

  # Verify that the expected interfaces exist before continuing the setup
  if ([ :len [ /interface ethernet find ] ] = 0) \
  do={
    :log error "{{ (ds "host").export }}.rsc/$runId: Not all ethernet interfaces came up; aborting default setup"
    :error "FATAL: Not all ethernet interfaces came up; aborting default setup"
    /quit
  } else {
    :log info "{{ (ds "host").export }}.rsc/$runId: Expected ethernet interfaces became available."
  }

{{-   if (gt $wireless 0) }}

  if ([ :len [ /interface wireless find ] ] = 0) \
  do={
    :log error "{{ (ds "host").export }}.rsc/$runId: Not all wireless interfaces came up; aborting default setup"
    :error "FATAL: Not all wireless interfaces came up; aborting default setup"
    /quit
  } else {
    :log info "{{ (ds "host").export }}.rsc/$runId: Expected wireless interfaces became available."
  }
{{- end }}
}

{{  else }}

:terminal style escaped
:put ""
:put "╶─╴RouterOS Configuration Script ╶─────────────────────────────────────╴"
:put ""

:terminal style none
:put "    Host: {{ (ds "host").name }}"
:put "  Export: {{ if (eq (ds "host").export "netinstall") }}netinstall{{ else }}{{ . }} Update{{ end }} Script"
:put "    Date: {{ (ds "host").date }}"
:put "  Run ID: $runId"
:put ""

:terminal style error
:put "This script will reset and/or (re)configure resources for the {{ . | toLower }}"
:put "update on the above host. If this is not the correct host, or this is not"
:put "the intended action, please cancel this script now!"
:put ""

:terminal style none
:put "Starting in 3 seconds..."
:for e from 2 to 0 do={
  :delay 1s
  :terminal cuu
  :put "Starting in $e seconds..."
}

:terminal cuu
{{  end -}}

{{ template "section" "Starting the Script..." }}
