# AdGuard Home must conditionally forward Active Directory DNS zones

Date: 2026-07-24

## Finding

AdGuard Home at `192.168.1.6` resolved the static A/PTR records for `dc01.reef.vivid.fish` but returned no LDAP or Kerberos SRV records. Direct queries to the domain controller DNS service at `192.168.1.4` returned the required records and the controller's directory ports were reachable from theorem.

## Durable Configuration

In AdGuard Home, add this line to **Settings -> DNS settings -> Upstream DNS servers**:

```text
[/reef.vivid.fish/]192.168.1.4
```

This delegates the private AD zone, including its dynamic SRV records, to the domain controller while leaving all other DNS names on the normal upstream path. AdGuard Home documents this dnsmasq-style per-domain upstream syntax specifically for private nameservers ([official configuration documentation](https://github.com/AdguardTeam/AdGuardHome/wiki/Configuration)).

## Verification

From theorem, the following must return an SRV answer pointing to `dc01.reef.vivid.fish`:

```sh
nslookup -type=SRV _ldap._tcp.dc._msdcs.reef.vivid.fish 192.168.1.6
```
