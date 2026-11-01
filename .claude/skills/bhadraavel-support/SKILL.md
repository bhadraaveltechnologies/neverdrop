---
name: bhadraavel-support
description: Wire any Bhadraavel app to the shared support desk at support.bhadraaveltechnologies.com - a Help link in the footer and at the places people get stuck, a public help form that files tickets on the hub (with a local copy when the hub is down), a signed-in "Your requests" section showing each ticket's status and the desk's replies, the category list the form offers and the registration command that must match it, and the README section. Use whenever the user asks for help, support, tickets, a contact form, "integrate with the support portal", or says help requests are not reaching the desk.
---

# Bhadraavel support desk integration

Every Bhadraavel app files its help requests on one desk, the **support hub**
at `https://support.bhadraaveltechnologies.com` (repo `support-hub`). The hub
sends the acknowledgement and the operator's replies by email, pings Telegram,
and shows every app's tickets in one console. The app never emails anyone
about support itself.

This skill is the checklist and the contract. Reference implementations:
Panchangam (`src/support.js`, `public/help.html`, `public/help.js`, the Help
tab in `public/app.js`), Memorize It (`lib/support/hub.ts`, `/contact`),
Go Green Health Vault (`docs/support-desk.md`, `/help`).

## 1. The hub's contract (what the app's server calls)

All calls carry `Authorization: Bearer <SUPPORT_HUB_KEY>`; the key scopes
everything to the app and must never reach a browser or a mobile bundle.

| Call | Purpose |
|---|---|
| `POST /api/v1/tickets` | File a ticket. Body `{ email, subject, body, category?, locale?, user_ref?, source?, code?, email_verified? }`. Signed in: send `email_verified: true` with `user_ref` (the app vouches). Signed out: send the `code` the person typed; a wrong or stale one is a `400` to show as is. The answer carries `email_verified`. Header `Idempotency-Key: <uuid made when the form rendered>` so a retry after a timeout returns the same ticket. Answers `201 { ok, ref: "PAN-1042", id }` (200 on a replay), `400 { error }` when the content is refused, `401` when the key is wrong. |
| `POST /api/v1/verify` | `{ email, locale? }` → `{ ok, delivered, reason? }`. Emails a six-digit one-time code (ten minutes, five tries, one email a minute) from the app's sender in the app's language. The app's server calls it when a signed-out person presses Send. |
| `GET /api/v1/tickets/:id` | One ticket with its thread: `{ ticket: { ref, status, category, subject, body, created_at, updated_at, last_admin_reply, messages: [{ author: "user"\|"admin", body, created_at }] } }`. Internal notes are never returned. |
| `GET /api/v1/tickets?status=open\|in_progress\|resolved\|closed\|all&page=1` | The app's tickets, newest first, for an admin view inside the app. |
| `POST /api/v1/tickets/:id/replies` `{ body, status }` | Reply as the operator from inside the app's own admin (optional). |

Rules the hub enforces: a valid email, subject 2 to 200 characters, body 2 to
5000 characters, and **the category must be one the app registered with**
(when the registration lists any). Statuses are `open`, `in_progress`,
`resolved`, `closed`.

The hub has no "list tickets for this person" call, so the app keeps its own
row per ticket (the hub id and ref, the user id, subject, category, created
at) and fetches status and replies by id when the person looks.

## 2. What to build in the app

1. **Server module** (`support.js` / `support/hub.ts`):
   - `CATEGORIES`: the list the form offers (see section 3).
   - `validateTicket(input)`: the hub's own rules, so nobody sees a hub refusal.
   - `createTicket({ who, input, submissionId })`: validate; if the hub is
     configured, POST with the idempotency key; **when the hub says
     "choose a category from the list", file again without a category and
     put `[Category] ` in front of the body** so a registration mismatch
     never turns a person away; on 401 or no answer, log it and keep the
     ticket locally with status `local`; always insert the local row
     (`support_ticket`: id = submissionId, userId, email, category, subject,
     body, ref, hubId, status filed|local, createdAt).
   - `requestCode({ email })`: the hub's `POST /api/v1/verify`, called from
     a `POST /api/support/code` route (rate limited) when a signed-out
     person presses Send; the form then shows the code field and the person
     presses Send again with the code.
   - `adoptTickets(who)`: rows filed signed out, **with `emailVerified`
     true**, whose email matches the signed-in person's (case-insensitive)
     get their user id, so a request from someone who could not sign in
     shows under Your requests once they are in. Never link an unverified
     row: anyone can type an address. Call it before listing. Store emails
     lowercased and keep `email_verified` from the hub's answer.
   - `myTickets(who)`: adopt, then the person's rows, newest first, each enriched
     from `GET /api/v1/tickets/:id` (the 10 newest at most, in parallel,
     with a short timeout; on failure show the local row as is): `status`,
     `updatedAt`, `replies` (the admin messages), `lastReply`.
   - `localTickets()`: rows with status `local`, for the admin.
   - `hubStatus`: the last call's outcome (`lastOk`, `lastError`, `lastAt`),
     shown on the admin screen.
2. **Routes**, open to everyone, signed in or not, placed before the sign-in
   gate (a person who cannot sign in needs help most), behind the app's
   human check for visitors and a tight rate limit (5 per 10 minutes):
   `GET /api/support/config` → `{ categories, hub, tickets }` (tickets only
   when signed in), `POST /api/support/tickets`.
3. **Public help page** (`/help`): email (filled and locked when signed in),
   category, subject, message, Send. Send is never left disabled waiting on
   the human check: send first, and if the server answers 403 `humanCheck`,
   run the check and send again. After sending: *"Sent. Your ticket number
   is PAN-1042; a confirmation is on its way by email."* (or *"Sent. We have
   your message and will reply by email."* when kept locally).
4. **"Your requests" section**, signed in (on the help page and in the Help
   tab or Account page): one row per ticket: ref, subject, category, date,
   a status badge (Open / In progress / Resolved / Closed, or *With us, not
   yet on the desk*), and the desk's replies, newest last, folded under the
   row. Replies also arrive by email; say so once.
5. **Help links** where people get stuck (section 4), and the footer's
   Help link (the `bhadraavel-footer` skill).
6. **Admin screen**: whether the key is set, the last call's outcome, and
   the locally kept tickets.
7. **Config**: `SUPPORT_HUB_URL` (default the hub's address) and
   `SUPPORT_HUB_KEY` in `.env.example`, the compose file (pass-through) and
   the README's configuration table.

## 3. Categories: the one list, in two places

The form's dropdown and the hub registration must carry the **same strings**.
The app's `CATEGORIES` constant is the source of truth; the dropdown is
filled from `GET /api/support/config` (never typed into the HTML), and the
registration command is written from the same constant.

Default list for a new app (adapt the domain line):

```
Can't sign in
Billing / subscription
<one line for the app's own content, e.g. "A panchangam value looks wrong">
Something is broken (bug)
Feature request
Other
```

**Always hand the user the list and the registration command** so they can
set the hub to match, in this form:

```bash
# on the hub's server, in ~/support-hub
docker compose exec hub node scripts/add-app.mjs \
  --id <app-id> --name "<App name>" --prefix <PFX> \
  --from "<App name> <support@bhadraaveltechnologies.com>" \
  --reply-to <app-id>@replies.bhadraaveltechnologies.com \
  --url https://<site> --locale en --telegram 645043432 \
  --categories "Can't sign in|Billing / subscription|…|Other"
# changing only the categories of an app already registered:
docker compose exec hub node scripts/add-app.mjs --id <app-id> --categories "…"
# check: docker compose exec hub node scripts/add-app.mjs --list
```

The command prints the key once; it goes in the app's `.env` as
`SUPPORT_HUB_KEY`. Taken ids and prefixes so far: `gogreen`/GGH,
`panchapatchi`/PCH, `panchapatchi-dev`/PPSD, `memorize`/MEM, `panchangam`/PAN.

## 4. Where help links belong

Put a link to `/help` (or the Help tab) at every place a person can be
stuck, with wording that names the moment:

- **Footer** of every page (the `bhadraavel-footer` skill): "Help".
- **Sign-in / landing page**: under the sign-in button, "Trouble signing
  in? Get help." This link must work signed out.
- **Subscription wall / pricing / expired-trial card**: "Questions? The Help
  tab reaches us."
- **Payment result and failure messages**: "If you were charged but see no
  plan, tell us through Help with the payment reference."
- **Error pages** (404, 500, "could not load"): "Still stuck? Get help."
- **Account / More / Settings page**: a "Help & support" row.
- **In-app Help tab** (signed in) with the form and "Your requests".

Do not add a chat widget, a mailto link or a second form: everything goes
through the one hub so the desk sees it.

## 5. Documentation to update

In the app's README (or docs): a *Help and support* section saying that
requests go to the shared desk, the ticket number format, that replies come
by email and also show under "Your requests", the local fallback and the
admin view, the category list (verbatim), the registration command, and the
two environment variables in the configuration table. Also `.env.example`
(the command next to the key) and the release log (a user-facing line:
"Help: a request reaches us…", "Your requests shows the desk's replies").

## 6. Checklist before pushing

- Form validates like the hub; categories come from the server.
- A ticket is filed with the idempotency key; a replay returns the same ref.
- Category mismatch retries without category; 401 and timeouts keep the
  ticket locally and are logged and shown to the admin.
- "Your requests" shows status and replies from the hub, and degrades to the
  local row when the hub is down.
- Signed out, Send asks for the emailed code first; a wrong code shows the
  hub's message and keeps the field open; a ticket confirmed by code appears
  under Your requests after sign-in, an unconfirmed one never does.
- Help page works signed out; Send is never stuck disabled.
- Help links at the places in section 4; footer link present.
- README, `.env.example`, compose, configuration table, release log.
- The user has been given the category list and the registration command.
