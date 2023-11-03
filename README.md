# n3t.uk Mikrotik RouterOS Scripts

This repository hosts a set of scripts, templates, and a [Taskfile][taskfile] to
manage the building of RouterOS scripts for multiple Mikrotik hosts (including
routers, switches, and access points) using a centralised defined configuration,
with emphasis on the management of VLANs and Firewall Rules.

![Overview Diagram for Mikrotik Scripts](https://github.com/n3tuk/scripts-mikrotik/blob/main/docs/overview-diagram.svg?raw=true)

> [!WARNING]
> This repository is designed to specifically configure the multiple routers,
> switches, and access points that are used as part of the network for the
> [`n3t.uk`][n3tuk] Lab and Home environments. However, this is open-source and
> can be used by anyone for their own hosts if they so wish. Updates are welcome
> to help generalise and secure, if suitable.

Feel free to fork it, and if you wish to contribute back to the repository, see
the document [`CONTRIBUTE.md`][contribute-md] for further details.

[n3tuk]: https://github.com/n3tuk
[contribute-md]: https://github.com/n3tuk/scripts-mikrotik/blob/main/.github/CONTRIBUTE.md

## How Mikrotik Scripts Operates

The script is ultimately designed to take complete control of the hosts its
configured for, although not every feature is supported. It's been written to
support the most common and currently needed features for the [`n3t.uk`][n3tuk]
network at this time.

This repository therefore operates in two parts:

| Step | Name                               | Description                                                                                                                                                                                                                                                                                                                                                |
| ---: | :--------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1. | [`netinstall.scr`](#netinstallscr) | Provide a baseline for each MikroTik host which should be installed as the default configuration using the [`netinstall-cli`][netinstall-cli] utility, and ensures that when a host is initiall configured or reset to the default configuration, it has secure settings and the `management` VLAN configured, allowing easy remote access to reconfigure. |
|   2. | [`update.scr`](#updatersc)         | Provides the up-to-date current configuration for each MikroTik host, installing the full initial configuration for all VLANs, Firewalls, User, Ports, etc., and updaing them as needed over time.                                                                                                                                                         |

[netinstall-cli]: https://mikrotik.com/download

Once the [`netinstall.scr`](#netinstallscr) script is loaded onto a MikroTik
host, and the define initialised, it should always be accessible within the
network without needing physical access. The configuration will also facilitate
the passing of `management` VLAN traffic over it (if configured to do so), so
all MikroTik hosts, and other hosts directly connected to the `management`
VLAN should remain accessible, even if no other traffic is allowed to pass.

That should allow each host to be loaded with the [`update.rsc`](#updatersc)
script which sets it to the current full configuration of the interfaces,
bridge, ports, VLANs, firewalls, and users, with that same script or similar
exports) to then keep the host up-to-date.

## Using Taskfile

[Taskfiles][taskfile] is used to manage the running of the scripts, including
the operation and dependencies of the scripts to build the configurations for
all hosts, or just for selected hosts or exports, as required.

Run `task --list` to see all supported tasks:

```console
$ task --list
task: Available tasks for this project:
* clean:         Clean up the temporary files from the repository
* default:       Run the default task (export)
* export:        Build and export the scripts for all hosts
* force:         Clean up and then re-export all scripts
* lint:          Check and lint files for correctness
```

## Exporting Mikrotik Scripts

To build and export the configuration scripts for all known hosts and all
known export types, just use `force` (which calls `clean` and then `export`) or
just `export`.

> [!NOTE]
> This repository does not, by default, include any configuration files for
> hosts or networks. As such, running `export` will not output any scripts.
> Instead example hosts and an example network are found within the
> [`examples/`][examples] directory, and can be test exported using `examples`
> rather than `export`.

[examples]: https://github.com/n3tuk/scripts-mikrotik/tree/examples

```console
$ task clean examples
task: [lint-yaml] yamllint -c .yamllint.yaml \
  {examples,hosts,networks}/*.yaml
task: [examples] scripts/exports  \
  | parallel -kj 10 scripts/export
==> ap/firewall
 -> Sourcing local://examples/ap.yaml
==> ap/netinstall
 -> Sourcing local://examples/ap.yaml
==> router/firewall
 -> Sourcing local://examples/router.yaml
==> switch/firewall
 -> Sourcing local://examples/switch.yaml
==> router/netinstall
 -> Sourcing local://examples/router.yaml
==> switch/netinstall
 -> Sourcing local://examples/switch.yaml
```

Or, when using `export` (or `examples`), you can select specific hosts or export
types through a fuzzy search by appending the search term to the end of
command-line (following `--`):

```console
$ task clean examples -- switchfirewall
task: [lint-yaml] yamllint -c .yamllint.yaml \
  {examples,hosts,networks}/*.yaml
task: [examples] scripts/exports switchfirewall \
  | parallel -kj 10 scripts/export
==> switch/firewall
 -> Sourcing local://examples/switch.yaml
```

## Export Types

### `netinstall.scr`

```console
task export -- netinstall
```

This is the "part 1" of the configuration and provides an `.scr` script which
can be used with [`netinstall-cli`] to load a host with the default
configuration that prepares that host for the network on first boot or
configuration reset.

Specifically, most services are pre-configured (logging, graphing, services,
DNS, NTP) and users are added with public SSH key for remote access.

> [!IMPORTANT]
> Users will be added by `netinstall.scr` with passwords (as this is required
> for `/user add` in RouterOS) but the password is thrown away. This is chosen
> as otherwise the password must be output to the system log or to a local file
> which would be open for all other users who have access. Users must first log
> in with their SSH private key and then set the password if WinBox or WebFig
> access is required. This will ensure that no one user can know more than their
> own password on any host.

The network is also configured by `netinstall.scr`, but only to support access
to `management` VLAN. The `management` and `blocked` VLANs are created and
interfaces are attached based on three rules:

- If `vlans:` is set on the interface, and `vlans` contains the `management`
  VLAN, that interface is configured as `tagged` on `management` and `untagged`
  for `blocked` (and only VLAN-tagged frames are allowed);
- If the above doesn't match, but `vlan:` is set, and its value is `management`,
  that interface is configured as `untagged` on `management` (and only untagged
  or priority tagged frames are allowed);
- All other interfaces are configured as `untagged` on `blocked` (and only
  untagged or priority tagged frames are allowed).

As any host should have access to the `management` VLAN on its initial
installation, or when reset to the default configuration, it should be possible to
remotely access the host without any further access to the host. Additionally,
as the `management` VLAN is supported in both tagged and untagged modes, any
switch or router may connect to multiple MikroTik hosts, allowing them to all
communicate over the `management` VLAN as normal.

As such, easy remote access to a host should be possible on reset, enabling an
administrator to remotely log in over SSH and run the update scripts to install
the full configuration of the current known network quickly.

### Testing Default Configurations

Due to the way scripts are structured when making changes to resources (see
[Safe Changes of Live Configurations](#safe-changes-of-live-configurations)
below), the `netinstall.scr` is not dependent on there being no resources
present on the host to run successfully.

Although it is not recommended to run on a fully-configured system (it will most
likely still work, even in this case, but it should remove all "unknown" VLANs
and remove all but the basic Firewall rules, etc.), it is safe to run on a reset
host. As such it allows for the rapid testing of the configuration on a fully
reset host, including repeated re-running on the same host to validate the
configuration.

### `update.rsc`

```console
task export -- update
```

The `update.rsc` export is in effect a superset of the following exports, with
two exceptions:

1. The [SSH Host Private Key][ros-ssh] is not exported as this should normally
   only be set once. Use [`certificates.rsc`](#certificatesrsc) to set the host
   private key, and as such should be exported and run explicitly once the host
   has been initialised or reset.
1. The [TLS Certificates][ros-certificates] needed to provide access to the
   WebFig and API services over HTTPS.
1. The [CAPsMAN][ros-capsman] Host Certificate and Client Authority Certificate
   will not be set, nor the Client Certificate on any Access Points.

[ros-ssh]: https://help.mikrotik.com/docs/display/ROS/SSH
[ros-certificates]: https://help.mikrotik.com/docs/display/ROS/Certificates
[ros-capsman]: https://help.mikrotik.com/docs/display/ROS/CAPsMAN

This exported script is therefore the default script to be run once a device has
been initialised or reset, and will bring the host up to the current network
configuration. It is also probably the general script to run on most updates.

If the update needs to be more targeted, there are exported scripts to
facilitate smaller sub-sets of changes, such as [`network.rsc`](#networkrsc) and
[`firewall.rsc`](#firewallrsc).

### `certificates.rsc`

```console
task export -- certificates
```

The `certificates.rsc` export provides SSH- and certificate-specific and
settings, should they be changed. More explicitly, this allows the configuration
of the Host Private Key (and hence public key provided for clients to verify the
host is who we expect them to be) and certificate public and private keys, which
should be protected.

### `network.rsc`

```console
task export -- network
```

The `network.rsc` script is for the configuration of network settings,
specifically:

1. Update the basic settings on all physical interfaces (except `mtu` and
   `l2mtu` settings, as this can cause temporary interface resets and therefore
   packet drops);
1. Update the bridge on the host and all of the bridge ports on the bridge,
   including default VLAN settings and frames permitted on ports, as well as
   costs and MSTP settings on the bridge and ports.
1. CRUD the VLANs based on network changes as defined, and ensure that they are
   associated with the bridge ports and as tagged or untagged.

### `firewall.rsc`

```console
task export -- firewall
```

The `firewall.rsc` script is for the configuration of the firewall (both IPv4
and IPv6) on each host, updating the address lists as needed, and then update
the firewall with the current set of rules.

Regardless of if there are IPv4 or IPv6 address settings defined, both versions
of the firewall are installed; which ones are used therefore depend on which
traffic the host is configured to support.

### `users.rsc`

```console
task export -- users
```

The `users.rsc` script is for the configuration of users on each host, and any
SSH public keys for each users.

> [!IMPORTANT]
> Users will be added by `users.rcs` (like `netinstall.scr` above) with
> passwords (as this is required for `/user add` in RouterOS) but the password
> is thrown away. Users must either first log in with their SSH private key and
> then set the password if WinBox or WebFig access is required, or the
> administrator running `user.rcs` should manually update and then expire the
> password and pass it on to the user. This will ensure that no one user can
> know more than their own password on any host.

### `dns.rsc`

```console
task export -- dns
```

The `dns.rsc` script is for the configuration of static DNS records and the
overall DNS settings of each host (i.e. the DNS server and DNS over HTTPS
settings).

## Safe Changes of Live Configurations

Although there are different ways to handle changes in configurations, such as
by clearing out the existing settings and then replacing them, the templates
here are designed to handle changes for live systems in a safe way. In most
situations any change applied should not effect running system in a way which
breaks existing processing (even momentarily).

For example, for static DNS records:

1. Each record is wrapped into an `:if () do={}` statement which checks for its
   presence first, and if not present, then it is created;
1. Any additional information which do not form part of the minimum required
   values (e.g. `comment`) is/are updated; then
1. All entries for the record which do not match the known configuration are
   removed.

> [!NOTE]
> This method ensures that new records are created before then removing those no
> longer required. Even if all records are changed in a single pass, both sets
> of records are present before the old set is removed. At no point should there
> be an empty set.

Alternately, for firewall rules:

1. Each existing (or new) address list is (re)created with a new prefix (as set
   in the `$rubId` variable for each run of the script) within which contains
   the latest set of entries for each of the address lists (Any prefixed as
   `dynamic:` are not managed by scripts so are not touched);
1. Each existing (or new) chain is (re)created with a new prefix (as set in the
   `$runId` variable for each run of the script) within which contains the
   latest set of rules for each chain;
1. A new `jump` target is set in each of the default chains for each table which
   redirects traffic to the new set of chains, and then all other rules in the
   default chain which do not `jump` to the new `$runId` chains are removed.
1. All existing address lists which do not have the `$runId` prefix are removed
   from the tables.
1. All existing chains which do not have the `$runId` prefix are removed from
   the tables.

> [!NOTE]
> This method ensures that two full sets of firewall chains, with `jump` rules
> in the default chains, are configured in all tables before the traffic is then
> switched by removing the old `jump` rule. This ensures that there are no
> partially complete chains while packets are being processed, and therefore not
> unintentionally blocked or allowing live packets in connections during
> updates. As all firewall chains either `accept` or `deny` traffic, traffic in
> the new chains will not be processed until the old `jump` rule is removed; an
> atomic change.

This is not a truly idempotent configuration in that there should be no changes
made if the resources match what is defined, but it should make the changes
atomic (e.g. packets are not processed by the new chain until the chain is fully
created and the parent rule directing the jump to the chain is replaced).

## Opinionated Network Settings

This script is designed with a specific purpose: To ease the day-to-day
management of the network of the [`n3t.uk`][n3tuk] network for general home
operation as well as the setup and communications in the `n3t.uk` Lab and Home
environments. As such this script is not specifically for general configuration
of any networks, but can be used as a base for that. Many of the names, options
chose, and settings used, are opinionated for what I like to use and how I need
the network to run.

### Bridge and VLANs

Every connected MikroTik host operates though a combination of a single Bridge
(not all hosts support hardware-accelerated multiple Bridges) and
[`802.1q`][wikipedia-8021q] VLANs to segment networks as required.

The Bridge (named `bri01`) is by default tagged, and the bridge and all trunk
interfaces (i.e those with only `vlans` configured) are set to only accept
packets with `802.1q` tagged packets. Edge ports can have a combination of
tagged and untagged support for various VLANs, as needed.

[wikipedia-8021q]: https://en.wikipedia.org/wiki/IEEE_802.1Q

### Management Port

Where a host has a Management Port, that will be named `mgt01` and associated,
untagged, with the `management` VLAN. This will allow access to the management
network for maintenance and debugging on both the host itself, as well local
connected hosts over the `management` VLAN.

### Blocked VLAN

All ports which are unconnected and unused will be both disabled and associated
with the Blocked VLAN (i.e. `99`). As such, in the event that any port is
accidentally enabled, the VLAN ensures that the connected host is still not
able to access anything on the network, other than any other potential host
connected to a blocked (but enabled) port.

This VLAN has no interface on any bridge on any host and has no DHCP server
(either via IPv4 or IPv6, nor SLAAC enabled via IPv6). Any communications are
local to the host itself too as this does not transit over any trunked physical
interface.

### Interface Naming

The following list is the set of standard base names of all interfaces within
the [n3t.uk][n3tuk] network. These will be configured by the netinstall script,
although the actual names are arbitrary and defined by the host configuration
itself (`hosts/{host}.yaml`), and not the templates themselves. However, any
default configurations may reference these (e.g. the default bridge name is set
to `bri01`, but this may be configurable eventually).

| Type            | Original           | Name            | Example            |
| :-------------- | :----------------- | :-------------- | :----------------- |
| 1000BASE-T      | `ether{x}`         | `gbe{xx}`       | `gbe01`            |
| 2500BASE-T      | `ether{x}`         | `tge{xx}`       | `tge01`            |
| 10GBASE-T       | `ether{x}`         | `xge{xx}`       | `xge01`            |
| SFP             | `sfp{x}`           | `sfp{xx}`       | `sfp01`            |
| SFP+            | `sfp-sfpplus{x}`   | `xfp{xx}`       | `xfp01`            |
| SFP28           | `sfp28-{x}`        | `tfp{xx}`       | `tfp01`            |
| QSFP+           | `qsftpplus{x}-{y}` | `qfp{x}{y}`     | `qfp21`            |
| QSFP28          | `qsftp28-{x}-{y}`  | `ofp{x}{y}`     | `ofp32`            |
| Bridge          | `bridge{x}`        | `bri{xx}`       | `bri01`            |
| VLAN            | `vlan{x}`          | `bri{xx}.{yy}`  | `bri01.10`         |
| WAN             | `ether{x}`         | `wan{xx}`       | `wan01`            |
| Management      | `ether{x}`         | `mgt{xx}`       | `mgt01`            |
| WireGuard       | `wg{x}`            | `wgd{xx}`       | `wgd01`            |
| WiFi (Main)     | `wlan{x}`          | `wfi{ghz}`      | `wfi24` or `wfi50` |
| WiFi (Children) | `n/a`              | `wfi{ghz}.{xx}` | `wfi24.22`         |

### Fixed Defaults

The following items are fixed defaults and should always be present for the
templates to work correctly:

| Type   | Name                   | Description                                                                                                                                                                                                                                                                    |
| :----- | :--------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| VLAN   | `management` (`name:`) | This VLAN name is searched for when managing some network interfaces, e.g. when setting network baseline during the `netinstall` export to inititally configure the network ports, so it should always be preset and be set to the VLAN ID associated with management network. |
| VLAN   | `blocked` (`name:`)    | This VLAN name is searched for when managing some network interfaces, e.g. when there is no pre-defined VLAN configuration on an interface, so it should always be present and set to the VLAN ID associated with blocked interfaces.                                          |
| VLAN   | `1` (`id:`)            | This VLAN ID is a default when the `blocked` VLAN cannot be found, so it is not recommended to be used in normal circumstances. (This is also the default VLAN for ports without VLANs assigned to them too, and as such is a reserved VLAN ID.)                               |
| VLAN   | `2` (`id:`)            | This VLAN ID is a possible default when the `management` VLAN cannot be found, so it is not recommended to be used in normal circumstances.                                                                                                                                    |
| VLAN   | `4095` (`id:`)         | This VLAN ID is not recommended for use in VLANs as it's a reserved ID.                                                                                                                                                                                                        |
| Bridge | `bri01` (`name:`)      | This is the name of the default and only bridge configured by these scripts and when setting up the bridge ports it is this bridge they are connected to (unless `bridge: false` is set for the interface).                                                                    |

## Configuration

The configuration for the networks and the associated host are handled by a
number of configuration files within the repository, and potentially within
[Hashicorp Vault][vault]. Each level overrides the next and allows for general
configurations with specific overrides, as needed.

| File                    | Description                                                                                                                                                                                                                                                                                            |
| :---------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `networks/{name}.yaml`  | This is the general settings of the local network, including the VLANs to be configured, and their network settings, as well as address lists, intereface lists, users, and other general settings. The file to be used is selected by the `network: {name}` setting in the host's configuration file. |
| `hosts/{name}.yaml`     | This is the configuration file for the specific MikroTik host. This should configure the local settings specific to each host, such as interface names, which VLANs are attached to ports, etc..                                                                                                       |
| `vault://{host}/{path}` | This is the configuration location for Vault-managed configurations and will be used to access (typically) secrets which should override values `hosts/{name}.yaml`. See `examples/vault.json` for an example of what can be supported.                                                                |

[vault]: https://www.vaultproject.io

## Layout of Exports and Parts

The templates (`exports`) used within this repository are heavily broken down
into smaller sections (`parts`), allowing them to be easily understood, and also
to allow the to be re-used when building up the configuration for the different
types of exports.

For example, the [`users.rsc.t`][p-users-rsc] file, which is used to manage
`/users` and their public SSH keys for remote access, is used by the
[`netinstall.scr.t`][e-netinstall-scr] export type when generating the initial
configuration to be loaded onto a host, alongside the general deployment export
type ([`update.rsc.t`][e-update-rsc]), and of course a dedicated
[`users.rsc.t`][e-users-rsc] for exporting just changes to `/users` on hosts.

It is not included in the [`firewall.rsc.t`][e-firewall-rsc] export type as you
don't need to update `/users` if you're just deploying changes to the firewall
configuration.

Exporting is quick too. When run on an Intel 12th-gen laptop, it can generally
export about 20-30 configurations per second, so even with a large number of
hosts, or export types, it doesn't take long to collate the data and then build
the scripts for the hosts. This can be improved further by limiting the outputs
using a fuzzy matcher to build only selected configurations when needed as well
(see [#Using Taskfile](#using-taskfile) above for details).

[taskfile]: https://taskfile.dev
[p-users-rsc]: templates/parts/users.rsc.t
[e-netinstall-scr]: templates/exports/netinstall.scr.t
[e-update-rsc]: templates/exports/update.rsc.t
[e-users-rsc]: templates/exports/users.rsc.t
[e-firewall-rsc]: templates/exports/users.rsc.t

## Authors

- Jonathan Wright (<jon@than.io>)
