---
title: "Cloudflare CNAME-flattened apex records do not reliably survive a zone-file export/import into DNSimple (or other providers) and should be manually recreated as that provider's own apex-alias record type"
date: 2026-08-21
topic: dns-apex-aliasing
tags: [dns, cloudflare, dnsimple, cname-flattening, alias-record, zone-transfer, apex-domain]
status: draft
sources: [dnsimple-alias-reference, dnsimple-alias-what-is, isc-cname-apex-blog]
source_session: ef5b6927-6d4f-4b9b-97ac-7ff232aa063a
---

## CLAIMS

- Standard DNS (RFC 1034) forbids a CNAME record from coexisting with any other record at the same name, which is why a CNAME cannot sit at a zone apex (the apex needs NS/SOA, usually MX too). [isc-cname-apex-blog]
- Multiple major DNS providers solve this with a proprietary, non-standard "apex alias" record that behaves like a CNAME but is legal at the apex and coexists with other apex records: Cloudflare calls it CNAME flattening, DNSimple and AWS Route 53 call it ALIAS, others call it ANAME. [dnsimple-alias-reference]
- DNSimple's ALIAS record resolves dynamically — DNSimple's own nameservers perform a live lookup of the target hostname's current IP at query time, rather than storing a static IP. [dnsimple-alias-what-is]
- This dynamic, provider-side-computed nature means apex-alias records are virtual, not real zone data — a zone transfer (AXFR) or a static zone-file export/import will not carry the "aliasing" behavior, because the record only exists as a live computation on the origin provider's own nameservers. [dnsimple-alias-reference]
- No documentation was found (DNSimple's own docs, or third-party writeups) confirming that DNSimple's zone-file **import** tooling accepts or reconstructs an ALIAS record from a plain BIND-format zone file — the record type is DNSimple-specific and BIND zone-file syntax has no equivalent type to represent it.
- Practical implication: migrating an apex domain that uses Cloudflare CNAME flattening to a new DNS provider (e.g. DNSimple) requires **manually recreating the apex record as that provider's native alias-record type** after the transfer — the zone-file export alone is not sufficient for that one record, even though it is sufficient for ordinary CNAME/A/TXT/MX records elsewhere in the same zone.

## SOURCES

**dnsimple-alias-reference**
URL: https://support.dnsimple.com/articles/alias-record-reference/
Accessed: 2026-08-21
Quote: "The ALIAS record is primarily used to provide CNAME-like functionality on the root domain (or apex zone)... The IP address that the ALIAS record resolves to is not static — it is determined dynamically by DNSimple's name servers each time the record is queried."

**dnsimple-alias-what-is**
URL: https://support.dnsimple.com/articles/alias-record/
Accessed: 2026-08-21
Quote: "According to RFC 1034, if a domain has a CNAME record, it cannot have any other records... ALIAS records solve this because they get around this by working differently."

**isc-cname-apex-blog**
URL: https://www.isc.org/blogs/cname-at-the-apex-of-a-zone/
Accessed: 2026-08-21
Quote: "CNAME flattening (Cloudflare) and ALIAS records (DNSimple, Route 53) are workarounds for the apex limitation, but they are not universally supported."

## SYNTHESIS

This came up handling a real domain transfer (`pdpp.dev`, Cloudflare → Linux Foundation, whose DNS platform was confirmed via live `dig NS` lookups on `hyperledger.org`/`lfdt.org`/etc. to be DNSimple). The apex record was a Cloudflare-flattened CNAME pointing at an indirection subdomain. The risk: attaching a Cloudflare zone-file export to a domain-transfer ticket and assuming the receiving DNS team's import will "just work" for that one record.

General rule for future work: whenever a migration crosses DNS providers and the source zone's apex uses any flavor of apex-aliasing (Cloudflare flattening, DNSimple/Route53 ALIAS, ANAME), treat that one record as **always a manual step**, regardless of what the zone-file export claims to contain. Everything else in a zone (CNAME subdomains, TXT, MX, wildcard records) transfers via a normal zone-file import without this problem — it's specifically the apex-flattening trick that doesn't survive, because it's a live computation on the origin nameservers, not stored zone data.

When writing a handoff doc/ticket for this kind of transfer, explicitly call out the apex as a follow-up manual task for the receiving team, naming the exact target hostname the alias should point at — don't rely on the receiving party to notice the gap themselves.
