---
name: bhadraavel-testenablement
description: Test a feature of any Bhadraavel app the way the owner can read it - a re-runnable suite that drives the real app in a browser, scenario by scenario, with a screenshot of each; a report in plain words (what was done, what was expected, what happened, pass or fail); results stored in the repository under test-results/<MMDDYYYY>/ with a README of the tests covered that day, updated on every run the same day; and an index of days. Carries a tested results writer and browser helpers in reference/. Use whenever the user asks for test results, a test report, screenshots of testing, "show me the tests", proof that a feature works, an end-to-end or browser test suite, or says to test a module and store the results.
---

# Bhadraavel test enablement

The owner does not read test logs. They want to **see** that a feature
works: each scenario explained in plain words, a screenshot of the moment,
and a clear pass or fail, kept in the repository by day. This skill is how
that is produced, the same way in every app.

The pilot is **myclinicapp's pharmacy module** (13 November 2026):
`tests/e2e/pharmacy.mjs`, 33 scenarios, results in
`test-results/11132026/`. The reusable parts are in `reference/`:

| File | What it is |
|---|---|
| `reference/test-results.mjs.txt` | The results writer (copy as `tests/e2e/lib/test-results.mjs`). `createRun()` gives `test()` and `finish()`; writes the report, the screenshots, the day's README, `runs.json` and the index of days. No dependencies. |
| `reference/test-results.test.mjs.txt` | Its tests; the SkillFactory CI runs them. |
| `reference/browser.mjs.txt` | Browser helpers (copy as `tests/e2e/lib/browser.mjs`): the local-only guard, sign-in with the on-screen code, `submit()`, `fresh()`, `flash()`, a page sized for readable, committable screenshots. |
| `reference/suite-example.mjs.txt` | A three-scenario suite in the standard shape, cut down from the pilot. Start a new suite from it. |

## 1. What the user asked for (13 November 2026)

- "I would like to see the test results of yours for this pharmacy module.
  Generate test results with suitable explanations and screenshots
  explaining the scenario."
- "Have them uploaded to a folder called `test-results` and store into a
  folder with naming as today's date in **MMDDYYYY** format."
- "The results can be in docs, docx or md, whichever works for you."
- "Maintain a `readme.md` which talks about the list of tests covered
  today. If we had to run tests same day, let's update the readme.md."
- "Have this testing capability captured as a skill."

## 2. Decisions (do not reopen without the user)

1. **Markdown**, in the repository. It shows on GitHub with the
   screenshots inline, needs no software, and its history is the
   repository's. Not docx.
2. **`test-results/<MMDDYYYY>/`** at the repository root, the date in the
   app's timezone (India), not the server's. One folder per day.
3. **The day's `README.md` is rewritten on every run that day** from
   `runs.json`: the latest result of each suite, the list of tests
   covered, and a log of every run. A second run never erases the first
   from the log; a second *suite* the same day sits beside the first.
4. **Every scenario has a screenshot**, taken after the check, of the whole
   page. A check that only reads data says so instead.
5. **A real browser against the real app** (Chromium, the built app, a real
   database), not mocks. The rules' unit tests are listed in the same
   report, as a second table.
6. **A suite only runs against localhost.** It resets its feature's test
   data, so it refuses any other app or database address.
7. **Results are committed** with the change they prove, and the pull
   request quotes them ("33 of 33 passed"). A failing scenario is reported
   as failing; it is never removed, skipped or reworded to pass.

## 3. The layout

```
tests/e2e/<feature>.mjs            the suite (one per feature or module)
tests/e2e/lib/test-results.mjs     from reference/
tests/e2e/lib/browser.mjs          from reference/
tests/e2e/lib/<app>.mjs            the app's own: test accounts, sign-in, clean start (once there is more than one suite)
tests/e2e/start-local.sh           starts the built app the way the suites expect
test-results/
  README.md                        index: one row per day
  <MMDDYYYY>/
    README.md                      tests covered that day + the run log
    runs.json                      the day's state (what the README is built from)
    <feature>.md                   the report
    <feature>/t01-….png            the screenshots
```

- Keep `tests/e2e/` out of the unit-test glob (`tests/*.test.ts` does not
  match it) so `npm test` and CI never start a browser.
- Add `test-results` to `.dockerignore`: screenshots must not enter the
  image.
- Playwright is installed globally in the build environments, not in the
  app's `package.json`. The suite loads it with `createRequire` (ESM
  `import` ignores `NODE_PATH`); run with `NODE_PATH=$(npm root -g)`.
  When the suite imports the app's TypeScript (to compute an expected
  value from the same rule), add `--import tsx`.

## 4. Writing a suite

Start from `reference/suite-example.mjs.txt`. Its shape, in order:

1. **Guard**: `localOnly(BASE, DATABASE_URL)` before anything else.
2. **Clean start**: empty the feature's tables and settings, and create
   exactly the data the scenarios need (a finished prescription, a
   pharmacist account). Never rely on what the last run or a manual test
   left behind.
3. **Sign in once per role.** The apps make a phone wait 30 seconds
   between one-time codes; a second sign-in for the same number in one run
   fails.
4. **Scenarios**, each one call:
   ```js
   await run.test(area, title, whatWasDone, whatIsExpected, page, async () => ({ pass, actual }));
   ```
   - `area` groups scenarios in the report ("Stock", "Payment", "Roles").
   - `title` is a sentence the owner would say: "Expired stock is never
     sold", not "test_expiry_allocation".
   - `whatWasDone` and `whatIsExpected` are written **before** the check
     and say real values ("Tried to add 99 Shelcal 500 when 15 are in
     stock"; "Refused, saying how many there are").
   - `actual` quotes what the screen said and what the data holds.
   - Do the action **before** `run.test()`, check inside it; the
     screenshot is taken when the check returns.
5. **Unit tests** of the feature's rules via `runUnitTests()`, then
   `run.finish({ unit, notCovered, rerun })`, then exit 1 if anything
   failed.

### What to cover (the pilot's list, as a checklist)

- The feature **off** and **on** (plan, flag, role): hidden when off.
- The main path, end to end, with the numbers checked to the paisa
  against the rule computed independently (import the app's pure rule, or
  write the sum out).
- **Every refusal**: each validation and business rule gets a scenario
  that tries to break it (oversell, expired, duplicate, missing licence,
  too many returned) and shows the message.
- What must **not** change: a paid document cannot be edited; a cancelled
  draft takes nothing.
- The **printed or shared document**: every field it must carry.
- **Each role**: what it sees, and each page it must not open (type the
  address directly).
- A **books-balance** check in the database (stock on hand equals the
  ledger; totals equal the invoices).
- End the report with **"Not covered by this run"**, honestly.

### Running every test of an app, and recording it

"Run all the tests" means the checks with no screen as well as the browser
suites. Record them the same way, as a suite of kind `"checks"`:

```js
const run = createRun({ root: ROOT, suite: { key: "checks", name: "Unit tests, typecheck and build", kind: "checks" } });
await run.test("Typecheck", "The code typechecks", "Ran npx tsc --noEmit.", "No errors.", null, async () => ...);
```

One entry for the typecheck, one for the production build, and one per unit
test (run each test file with `runUnitTests()` and use the file as the
area). A checks suite has no screenshots and its report says so. Then run
each browser suite. Order matters: **build first, restart the app on the
new build, then the browser suites**. The day's README then lists every
suite side by side. myclinicapp's `tests/e2e/checks.mjs` is the example.

## 5. The parts that took debugging

- **Look at the screenshots yourself before reporting.** In the pilot all
  32 checks passed while a screenshot showed a prescription still waiting
  after it was dispensed. The app was right (leftover data from manual
  testing: a second prescription for the same patient), but the report
  would have confused the owner. The fix was a cleaner start and one more
  scenario ("Once dispensed, the prescription leaves the waiting list").
  A green run is not finished until a few screenshots have been read.
- **Forms race.** Clicking submit and reading the page straight away reads
  the *old* page: the server action's redirect has not landed. Use
  `submit(page, button)` (waits for the POST, then for the network to go
  quiet). Filling the next form while the last redirect is still in
  flight loses the typing; go to the clean address first (`fresh(page)`).
- **Stale messages.** After one action the address still carries
  `?ok=…`; a wait for "a message" is satisfied by the old one. Call
  `fresh(page)` before the next action whose message you will read.
- **Check the data as well as the screen.** "Saved." on screen plus a row
  count from the database; a message alone can lie.
- **Strict locators.** Next adds its own `role="alert"` element; select the
  app's notice by class, not by role. A form is found by something only it
  has (`form:has(h2:has-text("Receive stock"))`), never by "the first
  submit button".
- **Dates.** The folder is the day in India: 20:30 UTC on the 13th is
  already the 14th there. Folders sort as dates (`01052027` is after
  `12312026`); the writer handles both.
- **Screenshot size.** 1240 px wide at 1.5x, full page: sharp enough to
  read, about 250 KB each (33 scenarios ≈ 8 MB). Each run replaces the
  suite's screenshots of that day rather than adding to them.
- **Simulating time.** For "expired on the shelf", insert the batch (and
  its ledger line) directly with a past date; the app rightly refuses to
  receive expired stock through the screen.
- **A suite that stops at sign-in.** The apps allow a phone six sign-in
  codes an hour, 30 seconds apart; a day of test runs uses them up and the
  next run dies waiting for the code, before its first scenario. In the
  clean start, delete the test accounts' rows from the codes table
  (`DELETE FROM otp_codes WHERE phone = ANY($1)`): local test data only.
- **Disabled options.** Read a greyed-out `<option>` with
  `evaluate((o) => o.disabled)`; Playwright's `isDisabled()` answered false
  for one that was disabled.
- **Service down.** In the cloud build environment Postgres and the app
  stop when the container idles: start both and check the health address
  before every run.

Learned when every remaining feature of myclinicapp got a suite (six more,
the same day):

- **A failing scenario may be the app.** Two of those six suites failed on
  real faults: cancelled appointments missing from the desk's list (a NULL
  note failed a `NOT LIKE` test), and a false "opened upload" line in the
  record trail. Before touching the scenario, find out which side is
  wrong; fix the app in the same change and say so in the report.
- **A page that never goes quiet.** If `networkidle` hangs, list the
  requests still open. There it was a Next `<Link>` to a file route
  (`/uploads/<id>`): the background prefetch asked for the file, never
  finished, and wrote an audit entry nobody caused. Links to files and
  downloads are plain `<a href target="_blank">`, never `<Link>`.
- **The sign-in limit per address.** Besides the per-phone limit, the apps
  allow about ten sign-in requests per client address every ten minutes,
  kept in memory. A day of suites from one machine trips it. Give each
  test browser its own address (`extraHTTPHeaders: { "x-forwarded-for":
  "10.x.y.z" }` on the context), as real people behind the proxy have.
  Never raise or switch off the limit for the tests.
- **Sign each role in once.** Keep one page per role for the whole suite
  (`as("desk")`, `as("doctor")`) instead of signing in per scenario: fewer
  codes used, and a much faster run.
- **Suites share one database.** Each passed alone; run one after another,
  the appointments suite failed because tokens the visits suite left
  waiting pushed its own off the waiting-room screen. A suite clears what
  it depends on at its start (its own made-up people by phone, and
  anything waiting today in the queue it reads), and leaves the plan and
  settings as the other suites expect when it finishes. **Run every suite
  in one go on the final build before reporting**, not only the new one.
- **Know the test accounts.** "A doctor cannot open this page" failed
  because the seeded doctor was also the clinic admin, who may. Read the
  roles of the account before writing a who-can-do-what scenario, and use
  one with only the role being tested.
- **A rebuild breaks the running app.** `next build` (which the checks
  suite runs) clears the standalone copy's static files; pages still load
  but nothing on them works, so every suite then dies at sign-in with no
  error on screen. Copy `.next/static` and `public` back and restart.
  Start the app with its public address set to the address the suites
  use, or the links in patients' messages point at a port nobody listens
  on. Keep both in one start script (myclinicapp's
  `tests/e2e/start-local.sh`) rather than a remembered command.
- **Two elements for one selector.** A layout class can match twice on
  some pages (`.wrap`); take the one meant (`.last()`), or select by
  something only that block has.

## 6. Running, and what to hand over

```bash
# the app, built, on :3300, with codes on screen and no support-hub key
bash tests/e2e/start-local.sh   # again after every build
NODE_PATH=$(npm root -g) node --import tsx tests/e2e/<feature>.mjs
```

Then:

1. Read the summary line; open the report; **look at several
   screenshots**, including the last one of each area.
2. If anything failed, fix the app (or, if the scenario was wrong, the
   scenario) and run again the same day: the README keeps both runs.
3. Commit `tests/e2e/`, `test-results/` and the feature together; quote
   the result in the pull request, with what was not covered.
4. Tell the user where the results are (`test-results/<MMDDYYYY>/README.md`),
   the pass count, anything the screenshots taught you, and what was not
   covered. Send the day's README and the report as files where the
   surface allows.

## 7. Rules

- **Never run a suite against a real customer's app or data.** The guard
  is not to be loosened or bypassed with an environment variable.
- **Test data only** in screenshots: made-up names, phone numbers,
  licence numbers. Never copy a real patient or customer into a suite.
- **Never weaken a check to make a run green**, and never delete a failing
  scenario. Report it failed, with its screenshot.
- Wording in the report follows the app's voice: plain, gentle, no
  jargon. A scenario title is something the owner could read aloud.
- The README section for the app: add "Test results" pointing at
  `test-results/README.md` and giving the run command (see myclinicapp's
  README).

## 8. Checklist

- [ ] `tests/e2e/lib/test-results.mjs` and `browser.mjs` copied from `reference/`
- [ ] The suite starts with `localOnly()` and a clean start
- [ ] Off/on, main path, every refusal, unchanged-after, document, roles, books-balance
- [ ] Numbers checked against the rule computed independently
- [ ] Screenshots read by you, not only the pass count
- [ ] Every suite of the app run in one go on the final build
- [ ] "Not covered by this run" filled in honestly
- [ ] `test-results` in `.dockerignore`; `tests/e2e` outside the unit-test glob
- [ ] Results committed; pull request quotes them; README has the section
