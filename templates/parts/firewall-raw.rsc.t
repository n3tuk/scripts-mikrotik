# -- templates/parts/firewall-raw.rsc.t
{{- /* vim:set ft=routeros: */}}
# The raw table for the firewall provides some initial quick processing of all
# packets received by, passed through, and sent from, this host, mainly to
# check that packets are correct and valid, and the connections are only handled
# from and to valid public and private networks.
#
# Specifically, add checks to the RAW table which allows packet processing to be
# quickly bypassed if required, to ensure inbound DHCP packets are accepted via
# the global broadcast address for IPv4 (as this is technically a BOGON network
# address) and to drop packets received from, or being sent to, a BOGON network
# range.

{{  template "component" "raw table" }}

# -> prerouting
#  - prerouting bypass (disabled)
#  - accept dhcp discovery packets (ipv4)
#  > check:bogons
#    - drop invalid network packets
#  > check:tcp
#    - drop invalid tcp packets
#  > check:udp
#    - drop invalid udp packets

{{  template "parts/firewall-raw-prerouting.rsc.t" }}
{{  template "parts/firewall-raw-check-bogons.rsc.t" }}
{{  template "parts/firewall-raw-check-tcp.rsc.t" }}
{{  template "parts/firewall-raw-check-udp.rsc.t" }}
{{  template "parts/firewall-cleanup.rsc.t" (coll.Slice "raw" "prerouting" "output") -}}
