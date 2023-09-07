# -- templates/parts/identity.rsc.t
{{- /* vim:set ft=routeros: */}}
# Configure the identity and location of this host.

{{  template "section" "Set up Host Identity" }}

/system identity
set name="{{ (ds "host").name }}"

/system clock
set time-zone-name="{{ (ds "host").settings.timezone }}"
