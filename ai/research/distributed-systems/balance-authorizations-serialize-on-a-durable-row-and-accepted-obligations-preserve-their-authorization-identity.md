---
title: "Balance authorizations serialize on a durable row, and accepted obligations preserve their authorization identity"
date: 2026-07-23
topic: distributed-systems
tags: [payments, authorization, postgres, row-locking, identity]
status: draft
sources: [postgres-select, postgres-locking, stripe-payment-intent, stripe-incremental-authorization]
source_session: 019f905a-afbc-7a90-be5e-346c09537ffe
---

## CLAIMS

- PostgreSQL `SELECT ... FOR UPDATE` locks the selected rows against concurrent lockers and writers until the transaction ends; a competing `SELECT ... FOR UPDATE` waits, then returns the updated row. [postgres-select] [postgres-locking]
- PostgreSQL recommends acquiring locks on multiple objects in a consistent order and acquiring the most restrictive required lock first to reduce deadlock risk. [postgres-locking]
- Stripe models an uncaptured authorization as a durable PaymentIntent with an explicit `requires_capture` state and `amount_capturable`; capture is bounded by the authorized amount. [stripe-payment-intent]
- Stripe applies a successful incremental authorization to the existing PaymentIntent, while a failed increment leaves the previously authorized amount and other PaymentIntent fields unchanged. [stripe-incremental-authorization]

## SOURCES

**postgres-select**
URL: https://www.postgresql.org/docs/current/sql-select.html
Accessed: 2026-07-23

**postgres-locking**
URL: https://www.postgresql.org/docs/current/explicit-locking.html
Accessed: 2026-07-23

**stripe-payment-intent**
URL: https://docs.stripe.com/api/payment_intents/capture
Accessed: 2026-07-23

**stripe-incremental-authorization**
URL: https://docs.stripe.com/payments/incremental-authorization
Accessed: 2026-07-23

## SYNTHESIS

For a database-backed balance authorization, use one durable row per serialization
domain and lock it before reading both the balance and already accepted obligations.
The critical section should finish by persisting the newly accepted obligation in
the same transaction. This makes the second authorizer observe the first
authorization after it waits.

Accepted obligations should also snapshot the identity and version of the authority
that permitted them. That follows the same durable-object principle as Stripe's
PaymentIntent: later accounting should use the accepted object's persisted identity
and state, rather than re-resolving mutable registry or permission data.
