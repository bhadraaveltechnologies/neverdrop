---
name: bhadraavel-appusage
description: Track how a Bhadraavel app is used, day by day - new customer registrations, trials started, first payments and renewals (with revenue and refunds), and the visitors to each page or feature that day (signed in by account, signed out counted without cookies or stored IP addresses), each with the city, state and country they came from, summarised; plus the customer list for any day with name, email, phone, trial or paid, plan and end date, and where they are. Builds the tracking core (tested reference in reference/), the tables, an admin Usage screen with CSV export, an admin API the support hub can read, an optional daily summary, and the Privacy Policy section. Use whenever the user asks for usage tracking, analytics, a dashboard of signups, renewals or visitors, "who used the app today", page or feature views, customer reports, or where customers come from.
---

# App usage: registrations, renewals, visitors, customers

This skill makes an app answer, for any day: *who joined, who started a
trial, who paid for the first time, who renewed, how many people opened each
part of the app, where they came from, and who they are.* It works in any
stack: the core is framework- and database-free, the app supplies a store
and a place lookup.

| File | What it is |
|---|---|
| `reference/usage.ts.txt` | The core: day in the app's time zone, client IP and place (CDN header or offline database, never stored), bot and prefetch filtering, path → feature, the daily-salted key for signed-out visitors, `trackVisit`, `trackEvent`, `eventForSubscription` (first payment or renewal), `statusOf` (paid / trial / free access / expired / no plan), `dailyReport`, `summarisePlaces`, CSV with formulas defused, `prune`. **Port the store, keep the logic.** |
| `reference/memory-store.ts.txt` | A working in-memory `UsageStore`, each method annotated with its SQL: the template for the real one. |
| `reference/usage.test.ts.txt` | 13 tests: the IST day boundary, proxy IPs, places, features, bots, anonymous keys, visit rows, renewal vs first payment, status, the whole daily report, CSV, pruning. Port them with the core. |
| `reference/schema.sql` | `usage_events`, `usage_visits`, the `users.last_*` place columns, `usage_access_log`, and the backfill. |
| `reference/copy.md` | The Usage screen's words, the daily summary, the Privacy Policy section. |

Code files end in `.txt` because this folder is copied into every app's
`.claude/skills/`, where an app's test runner and linter would otherwise pick
them up. Copy them into the app **without** the `.txt` (`usage.ts`,
`memory-store.ts`, `usage.test.ts`). In the SkillFactory,
`scripts/test-references.sh` runs the tests (Node 22.18+).

## 1. What the user asked for (21 November 2026)

- "An app should be tracked for **new customer registrations for that
  day**, **customer renewals for that day**, **customers visiting that
  page/feature for that day**, etc."
- "Collect entire customer information including **trial vs paid,
  subscription, customer name, email address, phone number**, visiting from
  **location (can be overall summarized) like city, state, country**."

## 2. Decisions (the contract; do not reopen without the user)

1. **The app keeps its own numbers.** Tables in the app's own database, a
   Usage screen in the app's admin, an admin API for the support hub. No
   third-party analytics script (no Google Analytics, no tag manager): the
   data names customers, so it does not leave the app.
2. **Two kinds of record.** *Events* (registered, trial_started,
   first_paid, renewed, coupon_grant, admin_grant, refunded) are written at
   the moment they happen, next to the row that makes them true, and kept
   with the account. *Visits* are one row per visitor per feature per day
   with a hit count, and are pruned after `USAGE_RETENTION_DAYS` (400).
3. **The day is the app's day**: `USAGE_TIME_ZONE`, default `Asia/Kolkata`.
   A registration at 01:30 IST belongs to that IST date, not UTC's.
4. **Renewal means paid again.** A paid (razorpay) subscription is
   `renewed` when the account already had a paid one, otherwise
   `first_paid` (a new customer, or a trial converted). Trials, coupons and
   admin grants are their own events and are never counted as revenue.
5. **Customer information comes from the app's own records**: name, email
   and phone from the users table (phone only if the app collects it; never
   ask for it just for this report), trial or paid, plan and end date from
   `subscriptions` (the `bhadraavel-razorpay` tables), place from the visits.
   An app without plans shows everyone as *No plan* and has no revenue tile.
6. **Place is city at best, and approximate.** From the CDN's headers when
   there is one (Cloudflare `cf-ipcountry`, `cf-ipcity`, `cf-region`), else
   an offline database (section 4). The IP address is **never stored**, not
   in the tables and not in logs written by this code. No GPS, no browser
   location prompt. The screen summarises by country, state or city.
7. **Signed-out visitors are counted, not followed.** Their key is an HMAC
   of IP and user agent under a salt derived from `USAGE_SALT_SECRET` and the
   day: stable for one day, unlinkable across days. No cookie is set, so no
   cookie banner is needed for this.
8. **Not counted:** bots and empty user agents, non-GET requests, prefetch
   and prerender requests, API calls, assets, health checks, `/admin`, and
   anyone who is an admin (the team's own clicks are not customers).
9. **Tracking never slows or breaks a page.** Visits are written without
   awaiting the response (or after it is sent); a failure is logged once
   and swallowed.
10. **Personal data stays on the admin screen.** The Usage screen and the
    API are admin-only; every view of the customer list and every CSV export
    goes to `usage_access_log`. The daily summary carries numbers only, never
    names, emails or phones.
11. **Say it in the Privacy Policy** (the section in `copy.md`) before the
    tracking goes live. Erasure of an account deletes its `usage_events` and
    its `usage_visits` rows.

## 3. Wiring it into the app

1. **Core and store.** Copy `usage.ts` (and its tests) into the app's server
   code; write the `UsageStore` on the app's database from the SQL in
   `memory-store.ts`; add `schema.sql` to the migrations. Run the backfill
   in `schema.sql` once so the first days are not empty.
2. **Feature map.** One list in one place, path pattern → the name an
   operator would use, first match wins, for every page a customer can open:
   ```ts
   features: [
     { feature: "Home", match: /^\/$/ },
     { feature: "Calendar", match: /^\/calendar(\/|$)/ },
     { feature: "Notes", match: /^\/notes(\/|$)/ },
     { feature: "Pricing", match: /^\/pricing$/ },
     { feature: "Help", match: /^\/(help|contact)(\/|$)/ },
   ]
   ```
   Anything unlisted shows as *other*; when *other* grows, add a line.
   Single-page apps whose "features" are tabs inside one URL: call
   `trackVisit` from a tiny `POST /api/usage/view { feature }` the client
   fires when a tab opens (the same rules apply: signed-in user from the
   session, place from the request, rate-limited, feature checked against
   the list).
3. **Visits.** Middleware (Express) or a `middleware.ts` / route-handler
   hook (Next.js) that calls `trackVisit(store, geo, cfg, { path, method,
   headers, remoteAddress, behindProxy, user })` for page requests, with
   `behindProxy` true when the app sits behind Traefik or nginx (it does on
   the VPS). Do not await it in the request path.
4. **Events**, in the same function (ideally the same transaction) that
   writes the row:
   - account created → `trackEvent({ kind: "registered", userId, place })`;
   - subscription activated (razorpay `activate()`, `ensureTrial`, coupon
     redemption, admin grant) → `kind = await eventForSubscription(store,
     sub)`, then `trackEvent` with the plan, amount and currency of the
     payment, `source`, and `id` = the payment id (so the webhook and the
     checkout callback cannot count it twice);
   - refund → `trackEvent({ kind: "refunded", amount, … })`.
   Place for an event: `placeOf(headers, clientIp(…), geo)` from the request
   that caused it (null from a webhook; the report falls back to the
   account's visits and its last place).
5. **Upkeep.** `prune()` once a day (the app's existing scheduler, or on the
   first request after midnight), and the geo database refresh (section 4).

## 4. Place lookup

- **Behind Cloudflare**: switch on *Add visitor location headers* (Rules →
  Managed Transforms); `placeOf` reads them and needs no database.
- **Otherwise**: DB-IP's free **IP to City Lite** database (MMDB format,
  CC BY 4.0, monthly, no account or key) read with the `maxmind` npm package
  (Node) or `geoip2` (Python):
  ```ts
  import { open } from "maxmind";
  const reader = await open(process.env.USAGE_GEO_DB ?? "/data/geo/dbip-city-lite.mmdb");
  export const geo = { lookup(ip) {
    const r = reader.get(ip) as any;
    return { city: r?.city?.names?.en ?? null,
             region: r?.subdivisions?.[0]?.names?.en ?? null,
             country: r?.country?.iso_code ?? null };
  } };
  ```
  Download it in the Docker build or on the server, monthly:
  `curl -fsSL https://download.db-ip.com/free/dbip-city-lite-$(date +%Y-%m).mmdb.gz | gunzip > dbip-city-lite.mmdb`
  (keep the previous file if the new month's is not out yet). The licence
  needs the attribution line on the Usage screen (`copy.md`). Without the
  file, places read *Unknown* and nothing else breaks. MaxMind GeoLite2 works
  the same way but needs an account and a licence key.

## 5. The Usage screen and the admin API

- **`/admin/usage?day=YYYY-MM-DD`** (default today), admins only, built from
  `dailyReport()`: the tiles, status chips, *By feature*, *Where visitors
  came from* (country / state / city via `summarisePlaces`), and the
  customer table with its filters and search. Wording in `copy.md`. Opening
  the customer table writes a `view` row to `usage_access_log`.
- **CSV**: `customersCsv()` for one day, or a date range of at most 92 days
  (merge the days' customers, one row per person with the union of
  features and events). Writes an `export` row.
- **Admin API** for the support hub and scripts, behind the app's
  `ADMIN_API_KEY` (as in `bhadraavel-razorpay`): `GET /api/admin/usage?day=`
  → the `DailyReport` as JSON; `GET /api/admin/usage/customers.csv?from=&to=`.
  Both logged with actor `api`.
- **Daily summary (optional)**: at 08:00 in the app's time zone, the day
  before's numbers (no personal details) to the operators' Telegram chat or
  email, in the form in `copy.md`.

## 6. Configuration

| Variable | Meaning |
|---|---|
| `USAGE_ENABLED` | `true` to record. Off: nothing is written, the screen says so. |
| `USAGE_TIME_ZONE` | The app's day. Default `Asia/Kolkata`. |
| `USAGE_SALT_SECRET` | Long random string (`openssl rand -hex 32`) for the signed-out visitor key. Changing it only changes keys from that moment. |
| `USAGE_RETENTION_DAYS` | Days of visit rows kept. Default 400. |
| `USAGE_GEO_DB` | Path to the MMDB file. Unset: CDN headers only, else *Unknown*. |
| `USAGE_TRUST_PROXY` | `true` behind Traefik/nginx, so `X-Forwarded-For` is read. |
| `USAGE_SUMMARY_TELEGRAM_CHAT` | Optional: where the daily summary goes. |

Put them in `.env.example`, the compose file (pass-through) and the README's
configuration table.

## 7. Done when

- The core's tests pass in the app, and a store test runs the same report
  against the real database.
- Registering, starting a trial, paying, renewing (a second payment) and a
  refund each show on the day's screen once, with the right customer and
  status; the webhook arriving after the checkout callback does not double
  a payment.
- Opening three features signed in and two signed out (another browser)
  shows 2 + the anonymous visitors per feature; an admin's own browsing adds
  nothing; no table or log line holds an IP address.
- Places show for a public IP (try from a phone on mobile data) and read
  *Unknown*, not an error, without the database.
- The customer list shows name, email, phone (where the app has it), status,
  plan, end date and place; the CSV opens in Excel with Tamil names intact
  and a phone number starting with `+` is not read as a formula.
- The Privacy Policy section is live in every language the app ships, before
  `USAGE_ENABLED` is switched on.
- The release log: no entry for the admin-only screen; one *Improved* line
  for the Privacy Policy change, following the app's CLAUDE.md (ask first).
