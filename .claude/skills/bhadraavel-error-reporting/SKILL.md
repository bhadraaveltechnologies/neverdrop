---
name: bhadraavel-error-reporting
description: Wire any Bhadraavel app to the error bus on the shared support hub at support.bhadraaveltechnologies.com - the app reports its own failures (server, background jobs and browser) to the hub, which folds repeats into one issue with counts, releases, routes and staff roles, shown on the hub's Errors pages; a gentle "something went wrong" page with a reference the help form picks up; the per-app switch on the hub's Apps page; scrubbing so no customer or patient detail ever leaves the app; and the README section. Use whenever the user asks for error reporting, crash reporting, "send errors to the support hub", the error bus, an error page, or says they want to know about failures before the customer does.
---

# Bhadraavel error reporting (the error bus)

Every Bhadraavel app can report its failures to one place: the **error bus**
on the support hub (`support-hub` repo, `docs/error-bus-design.md`, pages
under `/errors`). The hub recognises the same failure from any day or any
user as one *issue*, counts it per hour for ever, keeps a sample of
occurrences, says which release it started in, which route and which role,
and pings Telegram (through n8n) when an issue is new or comes back after
being resolved. The switch is **per app, on the hub** — a column on the
app's `support_apps` row, never code.

This skill is the contract and the checklist. The reference implementation
is **myclinicapp** (the pilot), and its files are in `reference/`:

| File | What it is |
|---|---|
| `reference/errors.ts.txt` | The server-side reporter (copy as `src/lib/errors.ts`). Scrubbing, expected-error filter, stack parsing, dedupe, queue, batching, the config poll. No dependencies. |
| `reference/errors.test.ts.txt` | Its tests; the SkillFactory CI runs them. |
| `reference/instrumentation.ts.txt` | Next's `register()` and `onRequestError` hooks (`src/instrumentation.ts`). |
| `reference/api-errors-route.ts.txt` | The browser's relay, `POST /api/errors` (`src/app/api/errors/route.ts`). |
| `reference/ErrorListener.tsx.txt` | `window` error / rejection listeners and `reportToServer()` (`src/components/ErrorListener.tsx`). |
| `reference/error.tsx.txt`, `reference/global-error.tsx.txt` | The gentle error pages (`src/app/error.tsx`, `src/app/global-error.tsx`). |

## 1. What the user asked for (5 November 2026)

- "A centralised mechanism to report errors occurring in various apps across
  the board which will help in troubleshooting issues."
- "A flag in the support portal for every registered app to enable error
  bus integration. Once enabled, whenever there is an issue, app should
  report the details (complete tech info), which app, which user, when it
  triggered, what can be the reason."
- "If I drill down to one error, I should be able to figure out how many
  instances of such error occurred in the past as well as future."
- "A common landing page in the support portal which provides visibility
  into the issues being reported collectively vs individual app perspective."

## 2. Decisions (do not reopen without the user)

1. **One set of tables on the hub, scoped by `app_id`** — not a table per
   app. The app's identity comes from its key, never from the body.
2. **Built into the hub, not Sentry.** The event format follows Sentry's
   field names (`exception.values[].stacktrace.frames`, `level`, `release`,
   `user`, `tags`, `breadcrumbs`) so a reporter could point there one day.
3. **The user on a report is an id and a role** (`staff:12`, `doctor`;
   `operator`), never a name, phone, email, or a customer/patient.
4. **Telegram pings go to one ops chat**; nothing for repeats. Only
   `error.new` and `error.regressed`.
5. **Event details are kept 30 days** (per-app setting); issue summaries
   and hourly counts are kept for ever.
6. **Reporting can never hurt the app.** Nothing in the reporter throws;
   it queues, batches, times out at 2.5 s, drops when the hub is down, and
   a failure while reporting is never itself reported.
7. **No patient or customer data leaves the app**, ever (section 4).

## 3. The hub's contract (what the app's server calls)

Both calls carry `Authorization: Bearer <SUPPORT_HUB_KEY>` — the **same key
as the help desk** (`bhadraavel-support`). No new secret. The key never
reaches a browser or a mobile bundle.

| Call | Purpose |
|---|---|
| `GET /api/v1/errors/config` | `{ enabled, sample_rate, min_level, poll_seconds }`. Poll every 5 minutes; `enabled: false` means **stop sending at the source**. Default settings: on/off *off*, sample 1.0, min level `error`, retention 30 days. |
| `POST /api/v1/errors` | `{ "events": [ … ] }`, up to 50 per batch, 64 KB per event. Always `202` once the key is accepted: `{ accepted, duplicates, dropped, new_issues, disabled? }`. `disabled: true` → stop until the next config poll. Never retry on what the hub thought of the content. |

One event:

```jsonc
{
  "event_id": "uuid",                      // a retried batch never counts twice
  "occurred_at": "2026-11-05T10:12:03Z",
  "level": "error",                        // fatal | error | warning
  "environment": "production",
  "release": "0.1.0+72d1526",              // APP_VERSION + short commit: "which deploy did this start in?"
  "platform": "node",                      // node | browser | flutter | android
  "source": "server",                      // server | client | job | public (public = not signed in)
  "instance": "vijaya-ortho",              // which deployment, for template apps
  "count": 1,                              // the app folded n identical events into this one
  "exception": { "values": [ { "type": "TypeError", "value": "…", "stacktrace": { "frames": [
      { "filename": "src/lib/auth.ts", "function": "requireUser", "lineno": 56, "in_app": true } ] } } ] },
  "message": null,                         // for captureMessage() without an exception
  "request": { "method": "POST", "route": "/visit/[appointmentId]", "route_type": "app action", "status": 500 },
  "user": { "id": "staff:12", "role": "doctor" },
  "runtime": { "node": "22.11.0", "browser": null },
  "tags": { "module": "visits", "pg_code": "23505" },
  "breadcrumbs": [ { "at": "…", "category": "action", "message": "saveVisit" } ],
  "fingerprint": null                      // set it when the app knows better than the hub's grouping
}
```

`request.route` is always a **route template** (`/visit/[appointmentId]`),
never a real path. The hub groups by the exception type and the top in-app
frames (file and function, not line numbers), or, without frames, by the
type, the message with numbers/ids/quoted values replaced, and the route.
It scrubs everything again on arrival.

## 4. Privacy: what never goes

Scrub **in the app**, before anything is queued (the hub scrubs again):

- Never collect request bodies, form data, query strings, cookies, headers
  (a reduced user agent is fine), full URLs, signed tokens (`/a/…`,
  `/d/…`), or SQL parameters.
- Postgres errors: keep `code`, `constraint`, `table`; drop `detail`
  (`Key (phone)=(…) already exists`).
- Pattern scrub on every string: Indian phone numbers, emails, 12-digit
  numbers, bearer/`sh_` keys, JWTs, a 4–8 digit number next to the word
  *code/otp/pin*, signed links, query strings, and the app's bill/patient
  number formats. Dates, times and small numbers stay — they make a message
  readable.
- Key scrub on context objects: any key matching
  `name|phone|email|address|dob|diagnos|notes|rx|token|otp|password|secret|cookie|body|params|query|form`
  becomes `[redacted]`.
- The user: id and role only. A visitor/patient is `user: null`,
  `source: "public"`.
- One line in the app's privacy page: technical error reports, which
  contain no personal details, go to Bhadraavel Technologies' support
  systems.

## 5. What to build in the app (Next.js; other stacks in section 7)

1. **`src/lib/errors.ts`** from `reference/errors.ts.txt`. Change only the
   `APP_VERSION` line (import the app's own), `INSTANCE` (the deployment id,
   e.g. `CLIENT_ID`), the bill/patient number patterns, and
   `EXPECTED_NAMES` (the app's own "refused on purpose" error classes).
   Exports: `captureException(err, ctx)`, `captureMessage(text, level, ctx)`,
   `captureFromBrowser(raw, user)`, `expected(err)`, `isExpected(err)`,
   `scrub(s)`, `parseStack(s)`, `flushNow()`, `stats`, `RELEASE`.
2. **`src/instrumentation.ts`** from the reference: `register()` adds
   `unhandledRejection` / `uncaughtException` handlers and flushes on
   SIGTERM; `onRequestError` catches every uncaught failure in a page,
   layout, server component, server action, route handler or middleware,
   with the route template and kind. (Needs `instrumentationHook` on Next
   < 15; on 15+ it is on by default.)
3. **Background jobs**: wrap each run — `runJobs().catch((e) =>
   captureException(e, { source: "job", route: "jobs/<name>" }))`.
4. **Swallowed failures**: where a `catch` turns a real failure into a
   fallback (the hub unreachable, a logo that failed to load, a broken
   config), add `captureException` / `captureMessage` with a fixed
   `fingerprint` so it stays one issue. Expected refusals (a taken slot, a
   wrong code, a redirect, validation) are **not** reported: list their
   classes in `EXPECTED_NAMES` or wrap with `expected(err)`.
5. **`src/app/api/errors/route.ts`** from the reference: the browser's
   relay. Rate limited (30/min per IP), adds the signed-in user's id and
   role from the session, calls `captureFromBrowser`, answers `204` with
   `new Response(null, { status: 204 })` — **not** `NextResponse.json(…, 204)`,
   which throws (the bus caught this one itself).
6. **`src/app/error.tsx`** and **`src/app/global-error.tsx`** from the
   reference: gentle, no blame, *Try again*, *Go to the start*, *Get help*
   linking to `/help?ref=<digest>`; the help form pre-fills the subject with
   the reference. Keep the app's tone rules (see its CLAUDE.md).
7. **`src/components/ErrorListener.tsx`** from the reference, rendered once
   in the root layout: `window.onerror` and `unhandledrejection`, ignoring
   extension and `ResizeObserver` noise, `ChunkLoadError` as a warning,
   posting through `/api/errors` with `sendBeacon`. Its `routeOf()` turns
   the real path into a template before sending.
8. **Release stamp**: `release = APP_VERSION + "+" + GIT_SHA[0:7]`. The
   Dockerfile takes `ARG GIT_SHA` → `ENV GIT_SHA`; compose passes
   `build.args.GIT_SHA: ${GIT_SHA:-}`; `deploy/redeploy.sh` exports
   `GIT_SHA="$(git rev-parse HEAD)"` before `up -d --build`.
9. **Config**: reuses `SUPPORT_HUB_URL` / `SUPPORT_HUB_KEY`. Add
   `ERRORS_DISABLED` (`1` = local kill switch) to `.env.example`, the
   compose pass-through and the README's configuration table.
10. **Tests**: `tests/errors.test.ts` from `reference/errors.test.ts.txt`
    (scrub, stack parsing, expected filter, never throws).

## 6. Switching it on (hand this to the user)

On the hub: **Apps → the app's card → Error reporting → Switch on**, then
**Send test error** — the toast should say *Test error stored — open
Errors to see it*. *Settings* holds the sample rate, minimum level
(`warning` to see warnings too), retention days, spike threshold and
*product* (the codebase, when several apps run it: every clinic is
`myclinicapp`). The app picks the switch up within five minutes; until
then the hub refuses its reports anyway.

Then **`/errors`** on the hub is every app together, `/errors?app=<id>` one
app, `/errors/<id>` one issue (counts, charts, release/route/role facets,
the latest occurrence, Resolve / Resolve in release / Ignore / Mute).

**Proving the pilot:** a deliberate throw in a staff action shows on
`/errors` within seconds; fifty repeats show as one issue counting fifty;
Resolve, then a recurrence reopens it as *came back*; the switch off stops
new reports within five minutes; a search of the stored payloads for a
phone number finds nothing.

## 7. Other stacks

- **Express** (panchangam, website): the same `errors.ts` minus the Next
  bits works as `src/errors.js`; add `app.use((err, req, res, next) =>
  { captureException(err, { route: req.route?.path ?? req.path, method:
  req.method, status: 500, user }); next(err); })` **after** the routes,
  plus the process handlers. Browser side is the same listener as a plain
  script posting to `/api/errors`.
- **Flutter / Android** (panchapatchi-sastra, neverdrop): a small HTTP
  client posting the same event shape to the app's **own** backend relay,
  which adds the key; `platform: "flutter" | "android"`; stack frames from
  `StackTrace.current` / `Throwable.stackTrace` mapped to `{filename,
  function, lineno}`; `in_app` = the app's own package. The hub key never
  ships in an app binary.

## 8. Documentation to update

README: an *Error reporting (the error bus)* section — what is reported,
what never leaves the app, the gentle page and its reference, that the
switch is on the hub, `ERRORS_DISABLED` and `GIT_SHA` in the configuration
table, and `captureException` / `expected()` for developers. `.env.example`
next to the hub key. No release-log entry unless the app's rules call for
one (the error page replacing the framework's bare screen is the only
user-visible change).

## 9. Checklist before pushing

- `errors.ts` in place; `APP_VERSION`, `INSTANCE`, number patterns and
  `EXPECTED_NAMES` adapted; tests pass.
- `onRequestError`, process handlers, job wrapper, the swallowed-failure
  sites with fixed fingerprints.
- `/api/errors` relay answers 204 via `new Response`; rate limited; user =
  id and role from the session.
- `error.tsx` and `global-error.tsx` in the app's tone, reference carried to
  `/help?ref=`; `ErrorListener` in the root layout.
- `GIT_SHA` through Dockerfile, compose and `redeploy.sh`; `ERRORS_DISABLED`
  in `.env.example`, compose and README.
- Nothing personal in a sample payload: send a test error carrying a phone
  number and an email in the message and in a tag, and read it back on
  `/errors/<id>` — both must read `[phone]`, `[email]`, `[redacted]`.
- The user has been told how to switch it on and how to send the test error.
