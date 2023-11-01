# -- templates/parts/certificates.rsc.t
{{- /* vim:set ft=routeros: */}}
# Configure the SSL Certificates for this network and this host and then
# configure the relevant services to use certificates for encrypted
# communications

{{  template "section" "Install Certificates" }}

{{  template "component" "Network Certificates" }}

{{- if (has (ds "network") "certificates") }}
{{-   range $c := (ds "network").certificates }}

{{      template "item" $c.name }}
:put ""

:if ( \
  [ :len [ /certificate find where name="{{ $c.name }}" ] ] = 0 \
) do={
  :if ( \
    [ :len [ /file find where name="{{ $c.name }}.pem" ] ] > 0 \
  ) do={ /file remove "{{ $c.name }}.pem" }
  /file add name="{{ $c.name }}.pem" \
            contents="{{ $c.contents | strings.Trim "\n" }}"
  # This is needed to ensure the file is ready for reading by the import
  :delay 300ms
  /certificate import name="{{ $c.name }}" \
                      file-name="{{ $c.name }}.pem"
  /file remove "{{ $c.name }}.pem"
}

{{-   end }}
{{- end }}

{{- if (and (has (ds "host").settings "ssl")
            (and (has (ds "host").settings.ssl "key")
                 (has (ds "host").settings.ssl "certificate"))) }}

{{    template "component" "Host Certificate" }}

{{    template "item" (ds "host").name }}
:put ""

{{-   $name := (ds "host").name }}

:if ( \
  [ :len [ /certificate find where name="{{ $name }}" ] ] = 0 \
) do={
  :if ( \
    [ :len [ /file find where name="{{ $name }}.pem" ] ] > 0 \
  ) do={ /file remove "{{ $name }}.pem" }
  /file add name="{{ $name }}.pem" \
            contents="{{ (ds "host").settings.ssl.key | strings.Trim "\n" }}
{{ (ds "host").settings.ssl.certificate | strings.Trim "\n" }}"
  # This is needed to ensure the file is ready for reading by the import
  :delay 300ms
  /certificate import name="{{ $name }}" \
                      file-name="{{ $name }}.pem"
  /file remove "{{ $name }}.pem"
}

/ip service

{{    template "item" "Configure Services" }}

set www-ssl certificate="{{ $name }}" \
            tls-version=only-1.2 \
            disabled=no

set api-ssl certificate="{{ $name }}" \
            tls-version=only-1.2 \
            disabled=no

{{- end }}
