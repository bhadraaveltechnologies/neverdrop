---
name: bhadraavel
description: The front door to every Bhadraavel skill. Finds the skills installed in this app, asks what the user is trying to do, and runs the right one — or a bundle of them in the right order (a new app from scratch, adding payments, connecting to the support desk and the error bus, branding and images, automatic deploys). Use whenever the user types /bhadraavel, asks "what skills do we have", "which skill should I use", wants a menu or a catalog of the Bhadraavel skills, or describes a goal without naming a skill.
---

# /bhadraavel — the master skill

The user keeps one name in mind: this one. Everything else is found and
offered from here. This skill does **no building of its own**: it finds
the catalog, asks a few questions, and invokes the skill(s) that fit
with the `Skill` tool, in order, letting each one do its own work and ask
its own questions.

## 1. Find the catalog (never hard-code it)

Every time this skill runs, read the skills actually installed, so a skill
added to the factory appears here by itself and a skill that is missing
from this app is noticed:

1. `Glob` for `.claude/skills/*/SKILL.md` in the repository, and
   `~/.claude/skills/*/SKILL.md` for the user's global ones.
2. From each file read only the frontmatter: `name` and `description`
   (the first sentence of the description is the menu line).
3. Skip this skill itself. Keep app-local skills that are not from the
   factory (such as `github-vps-deploy`) — they belong on the menu too.
4. Note which of the bundle members in section 4 are **not installed**
   here: say so when offering that bundle, and that the SkillFactory's
   sync (`Bhadraa-SkillFactory`, `sync-targets.json`) brings them.

## 2. Look at what the app already has

Before asking, spend a moment on the repository so the questions are
about what is missing, not what is done. Cheap markers:

| Skill | Already applied when |
|---|---|
| `bhadraavel-appreq` | `docs/requirements.md` exists |
| `bhadraavel-footer` | a footer with "Crafted by Bhadraavel Technologies LLP" (grep `Crafted by`) |
| `bhadraavel-support` | `SUPPORT_HUB_KEY` in `.env.example`, a help page / `support` module |
| `bhadraavel-error-reporting` | `lib/errors.ts` (or `errors.js`) with `captureException`, `app/error.tsx` |
| `bhadraavel-razorpay` | `RAZORPAY_KEY_ID` in `.env.example`, a `billing` module, `/pricing` |
| `bhadraavel-image-editor` | an `ImageEditor` component |
| `bhadraavel-share` | a Share button / `share` module |
| `github-vps-deploy` | `.github/workflows/deploy.yml` and `deploy/redeploy.sh` |

Say what you found in one short list ("Already here: footer, support
desk. Not yet: error reporting, payments.") and then ask.

## 3. Ask, with options

Use the structured question tool (`AskUserQuestion`) so the user picks
rather than types. First question, always:

> **What are you here for?**
> 1. **Start a new app** — the full sequence, from the brief to the first deploy (bundle A)
> 2. **Add something to this app** — pick one feature, or a bundle
> 3. **See the whole catalog** — every skill in one line each, then choose
> 4. **Check this app** — which Bhadraavel standards are in place and which are missing (section 2, in full)

For **2**, offer the bundles of section 4 that make sense for what was
found, plus "one skill" which then lists the catalog. When one skill is
chosen that has prerequisites (section 4's "needs" column), say so and
offer to run them first.

Do not ask more than is needed to choose: two questions is the usual
case, three at most. Everything about *how* a feature should behave is
the chosen skill's job to ask.

## 4. The bundles

A bundle is an ordered list. Run each member with the `Skill` tool, one
after the other, finishing one before starting the next, and **pause
between members only when the next one needs a decision from the user**
(each skill asks its own). Before starting a bundle, show the list with a
one-line reason per step and let the user drop steps.

### A. New app from scratch

| Step | Skill | Why here |
|---|---|---|
| 1 | `bhadraavel-appreq` | the brief first: actors, data, template or one-off, what the client hands over; creates the repository and adds it to the factory's sync |
| 2 | *(the app's own build, from the brief)* | not a skill: build the product |
| 3 | `bhadraavel-footer` | the maker's line, version, legal links — every page needs it before Help/Refunds links exist |
| 4 | `bhadraavel-support` | Help links, the help form, "Your requests"; registers the app on the hub and hands over the key |
| 5 | `bhadraavel-error-reporting` | same key, switch on the hub; the gentle error page links to Help from step 4 |
| 6 | `bhadraavel-razorpay` — **only if the app is paid** | plans, checkout, wall, policy pages; the footer's Refunds/Terms links start working |
| 7 | `bhadraavel-image-editor` — **only if there is a logo or people's photos** | operator-only uploads |
| 8 | `bhadraavel-share` — **only for apps with a result or a screen worth sharing** | the Share button |
| 9 | `github-vps-deploy` | CI on pull requests, auto-redeploy on main; last, once there is something to deploy |

Ask about 6, 7 and 8 in one question (multi-select) before starting.

### B. Add payments to an existing app

| Step | Skill | Why |
|---|---|---|
| 1 | `bhadraavel-footer` *(if missing)* | Refunds, Terms and Privacy links must exist for Razorpay's review |
| 2 | `bhadraavel-razorpay` | plans, checkout, webhook, wall, coupons, admin, policy pages |
| 3 | `bhadraavel-support` *(if missing)* | "Questions? Help reaches us" on the pricing wall and payment failures; the razorpay skill links to it |

### C. Connect to the support desk and the error bus

| Step | Skill | Why |
|---|---|---|
| 1 | `bhadraavel-footer` *(if missing)* | the footer's Help link |
| 2 | `bhadraavel-support` | help form, Your requests, hub registration, the key |
| 3 | `bhadraavel-error-reporting` | reuses the key; switch on the hub; error page → Help |

### D. Branding and images

| Step | Skill | Why |
|---|---|---|
| 1 | `bhadraavel-footer` | trishul, vel, maker's line, version |
| 2 | `bhadraavel-image-editor` | logo and people's photos, operator-only |
| 3 | `bhadraavel-gemini-image` — **only when the user asks for a generated picture** | banner, icon, illustration |
| 4 | `bhadraavel-share` | a screen or result as a picture, through the share sheet |

Offer D as a multi-select rather than a fixed order; 1 and 2 are the
usual pair.

### E. Automatic deploys

| Step | Skill | Why |
|---|---|---|
| 1 | `github-vps-deploy` | build on PRs, redeploy the VPS on main, health check |

When `github-vps-deploy` is not installed in the app, say it lives in the
`website` and `support-hub` repositories' `.claude/skills/` and offer to
copy it in.

### F. Keep an app to the standard (audit, then fix)

Section 2 in full, as a table of applied / missing, then offer to run the
missing ones as a bundle in the order of A.

## 5. Running a skill from here

- Invoke with the `Skill` tool by its exact `name`. Pass what the user
  already said as `args` so the skill doesn't ask again.
- Let the skill finish, including its own checklist, before the next.
- Each skill may ask about the release log and version bump per the
  app's CLAUDE.md; don't answer on the user's behalf.
- After a bundle, give one short summary: what was done, what each skill
  asked the user to do on the hub, in Razorpay, or on GitHub (keys,
  registrations, secrets), and what was skipped.

## 6. Catalog view

When asked for the whole catalog, print it as a table — `/<name>` and
the first sentence of its description — grouped as: **start** (appreq),
**every app** (footer, support, error-reporting, deploy), **paid apps**
(razorpay), **images and sharing** (image-editor, gemini-image, share),
**other** (anything else installed). Then ask which to run.

## 7. Adding a skill to the factory

When the user asks for a new shared skill, tell them it goes in
`Bhadraa-SkillFactory/skills/<name>/SKILL.md` (lower-case, hyphens, the
`bhadraavel-` prefix; reference code as `*.ts.txt`), with a row in that
README; the sync copies it to every app. This menu picks it up on the
next run — nothing to add here, unless it belongs in a bundle (section 4).
