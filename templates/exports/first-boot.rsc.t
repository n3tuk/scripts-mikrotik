{{ template "parts/header.rsc.t" "First Boot" }}
{{- /* vim:set ft=routeros: */}}
# Initialise the basic configuration needed for this new, or factory-reset,
# host, where it can then be reboot and the remaining configuration applied

{{ template "parts/services.rsc.t" }}
{{ template "parts/ssh.rsc.t" }}
{{ template "parts/dns.rsc.t" }}
{{ template "parts/ntp.rsc.t" }}
{{ template "parts/users.rsc.t" }}
{{ template "parts/interfaces.rsc.t" }}
{{ template "parts/wireless.rsc.t" }}
{{ template "parts/bridge.rsc.t" }}
{{ template "parts/vlans.rsc.t" }}
{{ template "parts/firewall.rsc.t" }}
{{ template "parts/wireguard.rsc.t" }}

{{ template "parts/footer.rsc.t" }}
