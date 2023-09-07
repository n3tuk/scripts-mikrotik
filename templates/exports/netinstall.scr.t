{{ template "parts/header.rsc.t" "netinstall" }}
{{- /* vim:set ft=routeros: */}}
# Initialise the basic configuration needed for this new, or factory-reset,
# host, where it can then be reboot and the remaining configuration applied

{{ template "parts/identity.rsc.t" }}
{{ template "parts/reset.rsc.t" }}
{{ template "parts/services.rsc.t" }}
{{ template "parts/ssh.rsc.t" }}
{{ template "parts/dns.rsc.t" }}
{{ template "parts/ntp.rsc.t" }}
{{ template "parts/users.rsc.t" }}

# With all basic configurations set to standard values, or removed, as required,
# now build out the initial bridge configuration and attached ports to support
# the bridge and the management VLAN, allowing the host to be reboot, ready
# for the remaining configuration to be applied.

{{ template "parts/interfaces.rsc.t" }}
{{ template "parts/bootstrap.rsc.t" }}
{{ template "parts/firewall.rsc.t" }}
{{ template "parts/footer.rsc.t" }}
