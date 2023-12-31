# -- templates/parts/ssh.rsc.t
{{- /* vim:set ft=routeros: */}}
# Configure the SSH Service

{{  template "section" "Set up SSH Service" }}

# Update the host key configuration for SSH and disallow all forwarding using
# SSH; only use for access to the host itself for management purposes

/ip service

# These are the normal modes of access for maintenance, so enable and permit
# access to these services from trusted networks only
set ssh disabled=no \
        address={{  join (ds "network").ranges.internal "," }},
                {{- join (ds "network").ranges.ssh "," -}}
                {{- if (eq (ds "host").export "netinstall") }},192.168.88.0/24{{ end }} port=22

/ip ssh

set forwarding-enabled=no \
    host-key-type=ed25519 \
    host-key-size=4096 \
    strong-crypto=yes

{{- if (and (eq (ds "host").export "certificates")
            (and (has (ds "host").secrets "ssh")
                 (has (ds "host").secrets.ssh "key"))) }}

/file

# Make sure to purge the host key file before re-creating and importing it
:if ( \
  [ :len [ find where name="ssh-host-key.pem" ] ] > 0 \
) do={ remove "ssh-host-key.pem" }
add name="ssh-host-key.pem" \
    contents="{{ (ds "host").secrets.ssh.key | strings.Trim "\n" }}"

# This is needed to ensure the file is ready for reading by the import
:delay 250ms

/ip ssh

import-host-key private-key-file="ssh-host-key.pem"

# Allow time for the key to be imported then delete
:delay 250ms

/file remove "ssh-host-key.pem"

{{-     end }}
