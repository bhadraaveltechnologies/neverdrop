---
name: bhadraavel-razorpay
description: Add paid plans with Razorpay to an existing Bhadraavel website - several prepaid plans (monthly, quarterly, yearly or any other), Razorpay Checkout with server-side order creation, signature verification and the webhook, a subscription wall that closes the portal to anyone without a current subscription, admin coupon codes (percent or flat amount off, per plan, per person, dated, limited, or free), admin grants and refunds, plus the pricing-page wording, a payments FAQ, and the Privacy, Terms, Cancellation and Refunds, Shipping and Delivery and Contact pages Razorpay's activation review expects. Use whenever the user asks for Razorpay, payments, subscriptions, plans, pricing, a paywall, coupons or discount codes, or refund / payment policy pages in one of the apps.
---

# Razorpay plans, coupons and the subscription wall

This skill turns an existing free website into a paid one, with Razorpay, in
any stack. It holds the user's rules, the decisions that keep money counted
exactly once, the setup steps in Razorpay's dashboard, and every word a
customer reads. The pieces:

| File | What it is |
|---|---|
| `reference/billing.ts.txt` | The billing core: plans, coupons, pricing, Razorpay REST client, checkout verification, webhook, access rule, trial, admin grants. Framework- and database-free behind a `BillingStore` interface. **Port the store, keep the logic.** |
| `reference/memory-store.ts.txt` | A working in-memory `BillingStore` (the tests run on it), each method annotated with its SQL: the template for the real one. |
| `reference/billing.test.ts.txt` | 14 tests: coupon maths and every refusal, the wall, stacking, the trial, the verify-and-webhook race, signatures, the free-coupon path. Port them with the core. |
| `reference/schema.sql` | PostgreSQL tables and the constraints that matter (one trial per account, order ids unique, coupon codes upper-case). |
| `reference/copy.md` | Every message: pricing page, coupon field, checkout results, the wall, reminders, Account page, admin, store build, release-log lines. |
| `reference/faq.md` | The customer FAQ for the pricing page, and the operator FAQ. |
| `reference/legal.md` | Privacy and Terms sections to add; whole Cancellation and Refunds, Shipping and Delivery, and Contact pages. |

The code files end in `.txt` on purpose: this folder is copied into every
app's `.claude/skills/`, where an app's test runner and linter would
otherwise pick up `.ts` files and fail its CI. Copy them into the app's
source tree **without** the `.txt` (`billing.ts`, `memory-store.ts`,
`billing.test.ts`). In the SkillFactory repository,
`scripts/test-references.sh` runs their tests (Node 22.18+).

Reference app: Memorize It (`lib/billing/`, `/pricing`, `/api/billing/*`)
was the first; it predates this skill (one trial not stored as a row, prices
from the environment, no coupons). Build new work to this skill, not to it.

## 1. What the user asked for (1 November 2026)

- A skill "capable of enabling Razorpay setup for an existing website",
  with "necessary configurations" and "verbiage content messages for the
  setup".
- An FAQ about Razorpay transactions; Privacy Policy, Terms and Conditions
  and a refund strategy for the website.
- "Configuration of multiple subscriptions for the users": several plans to
  choose from, set up without code changes.
- "Once enabled, users with zero subscription should not be allowed access
  to the portal."
- "As an admin, he should be able to offer coupon codes for enabling
  subscription for a user (i.e. percent discount or dollar discount)":
  percent off or a flat amount off, and a coupon that covers the whole price
  to switch a plan on for someone.

## 2. Decisions (the contract; do not reopen without the user)

1. **Off until switched on.** `BILLING_ENABLED=true` turns everything on;
   until then the app is free, the wall never shows, plans are only
   previewed. Payments additionally need the two Razorpay keys.
2. **Prepaid plans, no automatic renewal.** A plan is paid once for a fixed
   number of days (Razorpay *Orders* + *Checkout*). No mandates, no
   surprise charges, nothing to cancel. (Razorpay *Subscriptions* with UPI
   Autopay / card mandates is a separate, later project; do not mix it in.)
3. **Plans are rows.** `billing_plans` (id, name, description, days,
   amount, currency, active, sort), seeded once, then managed from the admin
   screen or API. Any number of plans. A plan is retired (`active = false`),
   never deleted.
4. **Access is a subscription row covering today. Nothing else.** With
   billing on, a signed-in person without a `subscriptions` row where
   `starts_at <= now < ends_at` is blocked: every app page sends them to
   `/pricing`, every app API answers `402`. Admins are never blocked.
5. **The trial, if any, is also a row** (`source = 'trial'`, granted once
   per account by `ensureTrial`, `TRIAL_DAYS`, default 0 = no trial), so rule
   4 stays literally true. Existing accounts get theirs the first time the
   gate sees them after switch-on.
6. **Periods stack.** A new plan starts when everything already bought
   ends; paying early never loses days.
7. **The server prices everything.** The browser sends a plan id and a
   coupon code, never an amount. The order amount, the discount and the
   currency are decided and stored on the server.
8. **Counted once.** A payment is counted by whichever arrives first, the
   checkout verify route or the webhook, through one conditional claim
   (`UPDATE … WHERE status = 'created' RETURNING`) inside one transaction
   with the grant. The loser sees "already counted". Never grant first and
   mark paid second: two arrivals then both grant.
9. **Signatures always.** Checkout result: HMAC-SHA256 of
   `order_id|payment_id` with the key secret. Webhook: HMAC-SHA256 of the
   raw request body with the webhook secret. Constant-time comparison.
10. **Coupons** are percent (1–100) or amount (smallest unit, in a
    currency), optionally limited to plans, dates, one account's email,
    first purchases, a number of uses per account (default 1) and in total.
    A coupon is recorded as used when money moves, not when an order is
    made. A price that a coupon would bring under Razorpay's minimum (100 in
    the smallest unit, ₹1) is rounded up to it; a coupon covering the whole
    price activates the plan with no Razorpay order at all.
11. **Refunds don't cut access by themselves.** `refund.processed` marks the
    payment refunded; the admin decides whether to end the period.
12. **Data is kept** when access ends ({90} days by default, stated in the
    Terms), so renewing picks up where the person left off.
13. **The Play Store build sells nothing.** Every price and plan is hidden in
    the Android wrapper (Google's policy for digital goods), with one line
    pointing to the website. A plan bought there works in the app.

## 3. Configuration

Environment variables (in `.env.example`, the compose file as
pass-through, and the README's configuration table):

| Variable | Meaning |
|---|---|
| `BILLING_ENABLED` | `true` turns plans, the wall and payments on. Default `false`. |
| `TRIAL_DAYS` | Days free for a new account (one trial each); `0` = none. Default `0`. |
| `RAZORPAY_KEY_ID` | `rzp_test_…` or `rzp_live_…`. Public: it goes to the browser. |
| `RAZORPAY_KEY_SECRET` | Server only. Never in the browser, a mobile bundle, a log or git. |
| `RAZORPAY_WEBHOOK_SECRET` | The secret typed when adding the webhook in Razorpay. Server only. |
| `ADMIN_API_KEY` | Bearer key for the admin API (support hub, scripts). |
| `ADMIN_EMAILS` | Comma-separated accounts that are admins inside the app (if the app has no admin role of its own). |

Plans are not environment variables: they are rows (section 2.3), seeded by
the migration in `schema.sql` with the user's names and prices. **Ask the
user for the plans** (name, days, price) before seeding; show them the
defaults (₹99 / 30 days, ₹249 / 90 days, ₹799 / 365 days) as a starting
point only.

```dotenv
# Plans and payments (bhadraavel-razorpay). Off until BILLING_ENABLED=true.
BILLING_ENABLED=false
TRIAL_DAYS=0
# Razorpay → Settings → API Keys. Test keys first (rzp_test_…), live after activation.
RAZORPAY_KEY_ID=
RAZORPAY_KEY_SECRET=
# Razorpay → Settings → Webhooks → the secret you set for https://<site>/api/billing/webhook
RAZORPAY_WEBHOOK_SECRET=
ADMIN_API_KEY=
ADMIN_EMAILS=
```

Secrets are typed by the user into the server's `.env`. Never ask them to
paste a key or secret into the chat, and never commit one.

## 4. Razorpay dashboard (hand these steps to the user)

1. **Sign up** at razorpay.com with the business (Bhadraavel Technologies
   LLP) and complete **KYC**: the LLP's PAN and documents, the authorised
   signatory, and the bank account settlements go to.
2. **Website review.** Razorpay checks the site before activating live
   payments. Before asking for activation, make sure these are live and in
   the footer, signed out: Terms, Privacy, Cancellation and Refunds,
   Shipping and Delivery, Contact Us (with the registered address, phone and
   email), and the Plans page with prices (`reference/legal.md`). Give the
   website URL and the business category (software / SaaS) in the
   activation form.
3. **API keys, test mode first:** Settings → API Keys → Generate Test Key.
   The secret is shown once: copy it straight into the staging server's
   `.env`. After activation, switch to Live mode and generate the live pair
   for production. Test and live keys never mix.
4. **Webhook** (separately in test and in live mode): Settings → Webhooks →
   Add New Webhook: URL `https://<site>/api/billing/webhook`, a long random
   secret (also into `RAZORPAY_WEBHOOK_SECRET`), events
   **payment.captured**, **payment.failed**, **order.paid**,
   **refund.processed**. An alert email for failures is worth setting.
5. **Payment capture:** Settings → Payment Capture → automatic capture
   (the core also captures an `authorized` payment itself, as a safety net:
   an uncaptured payment is returned to the customer after a few days).
6. **Branding:** Settings → Branding: the app's logo and accent colour, so
   the checkout window looks like the app.
7. Optional: **international cards** (Account & Settings → Payment
   methods) if the user wants payments from outside India; then say so in
   the FAQ.

## 5. What to build in the app

1. **Tables** from `reference/schema.sql` as a migration in the app's ORM,
   with the plans seeded.
2. **Billing module**: `reference/billing.ts.txt` copied in as
   `billing.ts` (ported to JavaScript if the app has no TypeScript: drop the
   types, keep every check), and a `BillingStore` for the app's database
   following `memory-store.ts.txt`.
   `transaction` must be a real database transaction; `claimPayment` must be
   one conditional `UPDATE … RETURNING`. Port `billing.test.ts.txt` to the app's
   test runner, against its test database if it has one.
3. **Routes** (signed-in unless noted; every input checked on the server):

   | Route | Does |
   |---|---|
   | `GET /api/billing/plans` (public) | Active plans with formatted prices, and whether billing and payments are on. |
   | `POST /api/billing/quote` `{ planId, couponCode? }` | `quote()`: the price with the coupon, or the coupon's refusal message. |
   | `POST /api/billing/order` `{ planId, couponCode? }` | `startPurchase()`: Checkout options, or `{ free: true }` when a coupon covered it. Rate-limit (10 a minute per account). |
   | `POST /api/billing/verify` `{ orderId, paymentId, signature }` | `verifyCheckout()`, then the person's new access (plan, until). |
   | `POST /api/billing/webhook` (public, no session, no CSRF) | `handleWebhook()` on the **raw body** and the `x-razorpay-signature` header. Answer quickly. Exempt it from the wall and from body parsers that re-serialise JSON. |
   | `GET /api/billing/me` | Access, current plan, paid-until, payment history. |

4. **The wall.** In the app's request gate (middleware / `requireUser()` /
   the auth hook), after sign-in: `ensureTrial()` then `accessFor()`; if
   `blocked`, pages redirect to `/pricing` and API calls answer
   `402 { error: "subscription_required", pricing: "/pricing" }` (the
   client sends the person to `/pricing` on a 402). **Let through**: the
   sign-in and sign-out flows, `/pricing`, the Account page (so they can see
   their history and sign out), `/api/billing/*`, the policy pages, Help /
   Contact and its API, What's new, static assets and the service worker,
   and anything an admin does. Load access once per request (cache it per
   request), not per component.
5. **Pricing page** (`/pricing`, public): plans from
   `/api/billing/plans`, the coupon field, the FAQ from `reference/faq.md`,
   the policy links, and on the wall the right heading from copy.md
   (never subscribed / trial ended / plan ended). Signed out, the button
   reads *Sign in to subscribe* and returns here after sign-in.
6. **Checkout in the browser** (load the script only on `/pricing`):

   ```js
   // after POST /api/billing/order answered { ok, free, checkout }
   if (r.free) return showSuccess(r.subscription);       // a 100% coupon
   await loadScript("https://checkout.razorpay.com/v1/checkout.js");
   const rzp = new Razorpay({
     ...r.checkout,                                      // key, order_id, amount, currency, name, description, prefill, notes
     theme: { color: ACCENT },
     handler: async (res) => {                           // success: verify on the server, never trust this alone
       const v = await post("/api/billing/verify", {
         orderId: res.razorpay_order_id,
         paymentId: res.razorpay_payment_id,
         signature: res.razorpay_signature,
       });
       v.ok ? showSuccess(v) : showCouldNotConfirm(res.razorpay_payment_id);
     },
     modal: { ondismiss: () => showCancelled() },
   });
   rzp.on("payment.failed", (e) => showFailed(e.error.description));
   rzp.open();
   ```

   If the app sends a Content-Security-Policy, allow Razorpay's hosts:
   `script-src https://checkout.razorpay.com`, `frame-src
   https://api.razorpay.com https://checkout.razorpay.com`, `connect-src
   https://api.razorpay.com` (and any other `*.razorpay.com` host the
   browser console reports as blocked).
7. **Account page, Plan section**: current plan and end date, the payment
   history (copy.md), *See plans*.
8. **Reminders** inside the app 7 days and 1 day before the end, and 3 days
   before a trial ends (copy.md). Push or email only if the app already
   sends them.
9. **Admin** (section 6).
10. **Policy pages** from `reference/legal.md`, in the footer (the
    `bhadraavel-footer` skill lists What's new · Privacy · Terms · Refunds ·
    Help; add Shipping and Delivery and Contact where Razorpay needs them).
11. **Play Store build**: hide every price, plan, coupon field and pay
    button when the app runs in the Android wrapper (`?src=play` or an
    `android-app://` referrer, remembered for the session), and show the
    store line from copy.md instead. The wall still applies there.
12. **Support**: the help form's categories already include *Billing /
    subscription* (the `bhadraavel-support` skill); link Help from the wall,
    the payment-failure messages and the Account page's Plan section.

## 6. Admin

Two ways in: the admin API with `Authorization: Bearer <ADMIN_API_KEY>`
(for the support hub and scripts; answer `404` when the key is not set, so
the API does not exist until configured), and an admin screen inside the app
for admins (the app's admin role, or `ADMIN_EMAILS`). Both call the same
functions; log every admin action with who, what and when.

| Action | API | Core |
|---|---|---|
| Look up a person: access, periods, payments, coupons used | `GET /api/admin/accounts?email=` | `accessFor`, store reads |
| Give days (bank transfer, apology, extended trial) | `POST /api/admin/accounts/grant` `{ email, days, note }` | `adminGrant` |
| End a period early (after a refund, a mistake) | `POST /api/admin/accounts/end-period` `{ email, subscriptionId }` | `endPeriod` |
| Refund a payment, full or part | `POST /api/admin/payments/:paymentId/refund` `{ amount? }` | `razorpayApi().refund` |
| List / add / change plans | `GET`, `PUT /api/admin/billing/plans/:id` | `upsertPlan` |
| Make a coupon | `POST /api/admin/billing/coupons` | `createCoupon` |
| List coupons with uses | `GET /api/admin/billing/coupons` | `couponReport` |
| Switch a coupon off, change its end or limit | `PATCH /api/admin/billing/coupons/:code` `{ active?, validUntil?, maxRedemptions? }` | `updateCoupon` |

**The coupon form** (admin screen): Code (or *Make one*: 8 letters and
digits, no look-alikes 0/O/1/I) · Discount: *percent* (1–100) or *amount*
(in rupees on the form, stored in paise) · Plans: all, or tick some · For one
person: an email (optional) · Starts / Ends (optional) · Uses per person
(default 1) · Total uses (optional) · First purchase only · Note (why it
exists). After saving, show the confirmation line from copy.md with the code
to share. Typical uses:

- **Switch a plan on for one person**: 100%, one plan, their email, uses 1.
- **A festival sale**: 20%, all plans, ends on a date, no total limit.
- **₹100 off the yearly plan** for the first 50 people: amount 10000 INR,
  plan yearly, total 50.
- **Win-back**: 30%, first purchase only off, for one email.

## 7. Switching on (the order matters)

1. Build everything with `BILLING_ENABLED=false`; deploy; the site is
   unchanged except the Plans page preview and the new policy pages.
2. On staging with **test keys** and the **test webhook**: buy each plan
   with Razorpay's test methods, apply each kind of coupon, close the
   window, fail a payment, let only the webhook count one (close the tab
   after paying), refund one, end a period, and watch the wall open and
   close.
3. Ask the user for the trial length (if any) and the announcement. Tell
   existing users in the app (a banner) and by email if the app has it,
   **before** switching on: when, the plans, the trial.
4. Get Razorpay activated (section 4.2), then put the **live** keys and the
   **live** webhook secret in production's `.env` and set
   `BILLING_ENABLED=true`. Restart. Buy the cheapest plan once with a real
   payment, then refund it from the dashboard.

## 8. Checklist before pushing

- The browser never sends an amount; the order, discount and currency are
  priced and stored on the server.
- Signatures checked on verify and on the webhook (raw body); keys and
  secrets only on the server.
- Verify and webhook together grant one period (the race test passes in the
  app's own suite).
- With billing on, a person with no current row is walled on every page and
  every API; the allow-list in 5.4 still works signed in and signed out;
  admins pass.
- Trial granted once, also to accounts made before switch-on.
- Coupons: every refusal shows its copy.md line; usage counted only on
  payment; 100% coupons skip Razorpay; sub-₹1 results round to ₹1.
- Refund marks the payment; access changes only through the admin.
- Pricing page, wall, Account section, reminders, admin screen and policy
  pages read exactly as copy.md and legal.md (business details filled in by
  the user, none invented).
- Play Store build shows no prices or pay buttons.
- README: a *Plans and payments* section (the rules in section 2, the
  dashboard steps, the admin actions), the configuration table,
  `.env.example`, the compose file; the app's release log and version bump
  (copy.md has the lines).
