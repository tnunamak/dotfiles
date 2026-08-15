---
title: "Go's url.QueryEscape (encodeQueryComponent mode) is not equivalent to JavaScript's encodeURIComponent — it escapes space as '+' and additionally escapes !'()* which encodeURIComponent leaves unescaped"
date: 2026-08-11
topic: web-standards
tags: [go, javascript, url-encoding, percent-encoding, interop]
status: verified
sources: [go-source-shouldescape]
source_session: 7dd49c6d-fefa-40d1-bf35-0bcd43c3eb67
---

## CLAIMS

- Go's `net/url.QueryEscape` calls `escape(s, encodeQueryComponent)`, which
  uses `shouldEscape(c, encodeQueryComponent)` per-byte. [go-source-shouldescape]
- `shouldEscape` treats only `A-Za-z0-9` and `-_.~` (RFC 3986 §2.3 unreserved
  "mark" characters) as never-escape, for every mode including
  `encodeQueryComponent`. [go-source-shouldescape]
- For `encodeQueryComponent` specifically, the reserved-character switch
  (`$&+,/:;=?@`) hits `case encodeQueryComponent: return true` — i.e. the RFC
  reserves, so Go escapes, ALL of `$ & + , / : ; = ? @` unconditionally in
  this mode. [go-source-shouldescape]
- The `encodeFragment`-only carve-out that un-escapes `!()*` does NOT apply
  to `encodeQueryComponent` — those three plus `'` (single quote, which Go's
  source comments say is deliberately always escaped outside fragment mode,
  citing golang.org/issue/19917) are escaped in query-component mode.
  [go-source-shouldescape]
- Separately from `shouldEscape`, Go's `escape()` function replaces a literal
  space (` `) with `+` when `mode == encodeQueryComponent`, rather than
  percent-encoding it to `%20`. [go-source-shouldescape]
- JavaScript's `encodeURIComponent` leaves unescaped: `A-Za-z0-9` plus
  `- _ . ! ~ * ' ( )` (per the ECMAScript spec's own reserved-unescaped set)
  — i.e. it does NOT escape `!'()*`, and it encodes space as `%20`, not `+`.
  This is a DIFFERENT safe-set than Go's `encodeQueryComponent`: `!'()*` are
  safe in JS but escaped in Go query-component mode, and space differs
  (`%20` vs `+`).

## SOURCES

**go-source-shouldescape**
URL: https://github.com/golang/go/blob/go1.16/src/net/url/url.go
Accessed: 2026-08-11
Quote: "case encodeQueryComponent: // §3.4 // The RFC reserves (so we must escape) everything. return true" — and, for the fragment-only carve-out: "if mode == encodeFragment { ... switch c { case '!', '(', ')', '*': return false } }" (explicitly NOT reachable for encodeQueryComponent, which returns from the switch above with `return true` before this block).

## SYNTHESIS

Any code porting a Go `url.QueryEscape`-produced or -consumed value into a
JS/TS codebase (or vice versa) via `encodeURIComponent`/`decodeURIComponent`
is not a safe drop-in substitution for byte-identical wire compatibility if
the input can ever contain a literal space or any of `!'()*` — these differ
in escaped-vs-unescaped status and (for space) in escape character itself
(`+` vs `%20`). A byte-for-byte port must special-case those characters
(and the space→`+` substitution) rather than delegating to
`encodeURIComponent` and assuming equivalence. Verified against a real
PDPP incident: initially assumed `encodeURIComponent` mirrored Go's
`url.QueryEscape` for a Slack session cookie value (worked for that one
value, which happened to contain only `+`/`/`/`=`, all of which ARE
escaped identically in both — `+` and `/` and `=` are outside JS's safe
set too), but the equivalence claim was false in general and needed an
exact reimplementation of Go's `shouldEscape(c, encodeQueryComponent)`
table to be correct for arbitrary inputs (space, `!'()*`).
