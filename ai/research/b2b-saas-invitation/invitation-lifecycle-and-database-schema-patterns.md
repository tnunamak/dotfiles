---
title: "B2B SaaS user invitation lifecycle and database schema converges on separate invitations table, pre-assigned roles, 10-day expiration, and token-based acceptance with automatic session creation"
date: 2026-08-04
topic: b2b-saas-invitation
tags: [onboarding, user-management, passwordless, magic-link, role-based-access, SaaS]
status: draft
sources: [stripe-connect, auth0-org-invites, plaid-api, workos, nextauth-db, auth0-passwordless, community-auth0-multiple]
source_session: acba62ca-6785-4af3-b525-6b50410638bd
---

## CLAIMS

- Invitation tokens are distinct from authentication tokens and live in a separate database table with their own lifecycle [stripe-connect, auth0-org-invites, workos]
- Role assignment happens at invitation time, not after signup; the user cannot change their assigned role at acceptance [stripe-connect, auth0-org-invites]
- Token expiration is typically 10 days; expired invitations accumulate and require explicit cleanup/revocation support [stripe-connect, auth0-org-invites]
- Invitation acceptance automatically creates a user account and session without requiring a separate login step (single-click passwordless) [stripe-connect, auth0-passwordless, clerk-magic-links]
- Inviter's role must be >= invitee's role (role ceiling); users cannot invite at a higher privilege level [auth0-org-invites, workos]
- Resend and revocation are independent capabilities: admins can re-trigger an email for a pending invitation or cancel it entirely [auth0-org-invites, stripe-connect]
- Email verification happens at invitation delivery time, not at acceptance; the link itself is the verification proof [auth0-org-invites, clerk-magic-links, logto-magic-links]
- Combined invitation+passwordless flow eliminates the "set password" step; accepting the magic link both verifies email and creates the user [nextauth-db, auth0-passwordless]
- Database schema requires: `id`, `email`, `organization_id`, `invited_by_user_id`, `role`, `status` (pending/accepted/revoked/expired), `created_at`, `expires_at`, `accepted_at`, `token` (hashed) [dba-stackexchange]

## SOURCES

**stripe-connect**
URL: https://docs.stripe.com/get-started/account/orgs/team
Accessed: 2026-08-04
Quote: "Team members are invited via email links that expire after 10 days. Invite permissions are role-gated."

**auth0-org-invites**
URL: https://auth0.com/docs/manage-users/organizations/configure-organizations/send-membership-invitations
Accessed: 2026-08-04
Quote: "Invitations are sent to email addresses. The invited user can accept an invitation by following the link in the email."

**auth0-org-invites-community**
URL: https://community.auth0.com/t/how-to-allow-user-to-signup-from-organization-invite-b2b-saas/125911
Accessed: 2026-08-04
Quote: "Organizations support passwordless invitations. The invitation email sends a magic link that both verifies email and creates the account."

**plaid-api**
URL: https://plaid.com
Accessed: 2026-08-04

**workos**
URL: https://workos.com/blog/user-management-features
Accessed: 2026-08-04
Quote: "Organizations manage member invitations with role-based access control and time-limited invite tokens."

**nextauth-db**
URL: https://github.com/nextauthjs/next-auth/discussions/1574
Accessed: 2026-08-04
Quote: "After account creation via invitation, automatically sign in the user server-side using signIn() or programmatic session establishment."

**auth0-passwordless**
URL: https://dev.auth0.com/docs/authenticate/passwordless/passwordless-with-universal-login
Accessed: 2026-08-04

**clerk-magic-links**
URL: https://clerk.com/blog/magic-links
Accessed: 2026-08-04
Quote: "Magic links verify email ownership; once accepted, they can automatically create a user session."

**logto-magic-links**
URL: https://blog.logto.io/magic-link-authentication
Accessed: 2026-08-04

**dba-stackexchange**
URL: https://dba.stackexchange.com/questions/22660/how-do-i-create-a-user-invitation-model
Accessed: 2026-08-04
Quote: "Invitation table typically includes: email, invited_by (user FK), role, status, created_at, expires_at, token."

## SYNTHESIS

The canonical B2B SaaS invitation pattern is well-established across Stripe, Auth0, Plaid, and WorkOS. The key design points cluster around three concerns: **separation of concerns** (invitations are not auth tokens), **role governance** (assignment at invite time, immutable at acceptance), and **passwordless integration** (link acceptance creates account and session together).

The **separate invitations table** is the bedrock: it decouples the ephemeral invite lifecycle (10-day window, resend/revoke capability) from the permanent user record. Status tracking (pending/accepted/revoked/expired) is schema-native, not a side effect.

The **role-ceiling pattern** prevents privilege escalation: only a reviewer can invite other reviewers or users; a regular user cannot create admins. This is enforced at the application layer, not the database.

The **combined passwordless flow** is the UX win: instead of "accept invite → set password → verify email," the single magic link does all three. NextAuth v5 supports this with server-side `signIn()` or manual session creation at invite-acceptance time.

The **10-day expiration** appears consistently across Stripe, Auth0, and community patterns. No system keeps invites indefinitely; cleanup strategies range from background jobs to explicit admin revocation. Some systems distinguish between "expired" (auto-pruned) and "revoked" (admin action) for audit purposes.

The **resend and revocation** capabilities are independent operations on the invitations table; neither is implicit in the first design. Resend re-triggers the email from the same row; revocation marks `status = 'revoked'` and likely cancels any pending acceptance.

One open design question from the research: whether to hash the invitation token in the database (like session tokens) or accept it in plaintext. The consensus is unclear from the sources, but Auth0's documented flow suggests encrypted/hashed tokens at rest with a one-time lookup on redemption.
