---
name: bhadraavel-appreq
description: Gather, challenge and write down the requirements for a new Bhadraavel app before any code is written - template (one codebase, many clients by configuration) or one-time build, the actors and who owns which data, whether the client's own admin runs the app or Bhadraavel support still helps, what the Bhadraavel operator console needs (users, subscriptions, plans, tenants), the minimum the client must hand over for launch, deep research into the client's domain with suggestions to improve their asks, honest push-back on requirements that will hurt them, and whether a new GitHub repository is needed (and creating it). Produces docs/requirements.md as the signed-off brief. Use whenever the user says they want to build a new app, a new product, a new client project, a white-label or template app, asks for requirements, a scope, a brief, a discovery session, or "what do we need from the client".
---

# Requirements for a new Bhadraavel app

Before anything is built, this skill walks the user (and through them, the
client) through a fixed set of questions, researches the domain, pushes back
where an ask will hurt the client, and writes one brief:
`docs/requirements.md`. Nothing is coded until the user has read the brief
and said go.

| File | What it is |
|---|---|
| `reference/brief-template.md` | The shape of `docs/requirements.md`: every section this skill fills, in order. |
| `reference/domain-research.md` | How to research a domain: the checklist, the sources, the Indian regulations that keep coming up, and how to turn findings into suggestions. |
| `reference/template-config.md` | How a template app is made configurable for many clients: the client config file, what goes in it and what never does, tenancy options. |

## 1. What the user asked for (4 November 2026)

- "When we wanted to build a new app, it should [ask] if this app is going to
  act as a **template or one-time only**."
- "If it is a template, you need to configure such a way that it can be
  catered to **multiple clients based on minimalistic configurations only**."
- "If it is a one time only, then **build the app directly without thinking
  about reusable strategy** in mind."
- "Next, check **who are the actors** and **how they will manage data**."
- "Next, how will data and app be managed: by an **admin role handled by the
  client itself**, or do they still need **minimalistic support from the
  Bhadraavel support team**."
- "Next, do we need to have any **interface in Bhadraavel support** to manage
  the support effectively, like user management, subscription management,
  plan management etc."
- "Next will be **what are the minimum set of requirements needed from the
  client for launch**."
- "Additionally, do a **thorough deep research on the domain** (if you are
  unsure of the domain, check with them). Provide suggestions so that they
  can improvise their requirements to the best."
- "Sometimes you might feel that their requirements are absurd. **Provide
  recommendations genuinely** on what you feel is best for their needs; **if
  they still insist to go by their way, we will proceed**."
- "Also determine if **creating a new repo in GitHub** is necessary. If yes,
  we need to create it."

## 2. Decisions (the contract; do not reopen without the user)

1. **Questions first, code never in this skill.** The skill ends with a brief
   and, if needed, an empty repository. Building starts only after the user
   says the brief is right.
2. **Ask in order, a few at a time.** Use the question tool (AskUserQuestion
   in Claude Code) with 1 to 4 questions per round, each with concrete
   options and a recommended one first, marked *(Recommended)*. Never dump
   all the questions at once; later questions depend on earlier answers.
   Anything the user already said in their request is an answer: do not ask
   it again, write it down.
3. **Template or one-time is the first question**, because it changes every
   later answer (section 3, step 1).
4. **One-time means one-time.** No client config file, no tenant id, no
   feature flags "for later", no abstraction for a second client. Build the
   simplest app that does this client's job. If the user later turns it into
   a template, that is a new decision and a refactor, and that is fine.
5. **Template means configuration, not forks.** One codebase, one repository;
   each client is a config file (and its secrets) and nothing else. A client
   who needs code no one else needs is either a feature flag everyone could
   use, or a one-time build. Never a branch or a copied repo per client.
6. **The domain is researched before suggestions are made.** If the domain is
   unclear from the request (for example "an app for my uncle's shop"), ask
   what the business does before researching. Never guess a domain.
7. **Push back once, honestly, then follow.** When an ask will cost the
   client (legal risk, data loss, a cost out of proportion, a worse
   experience for their own users, something the platform forbids), say so
   plainly with the reason and a better option. If the user still wants it
   their way, record it in the brief under *Client decisions against our
   advice* with the risk, and build it their way. Do not raise it again.
8. **Every app gets the house skills.** The brief always lists the footer
   (`bhadraavel-footer`) and the support desk (`bhadraavel-support`); payments
   (`bhadraavel-razorpay`), sharing (`bhadraavel-share`) and generated images
   (`bhadraavel-gemini-image`) when the answers call for them. Do not
   re-specify what those skills already decide; name the skill.
9. **A repository is created only after the user confirms its name and
   visibility** (section 5). Creating one is outward-facing.

## 3. The interview, in order

Each step: what to ask, the options to offer, what to recommend, and what to
write in the brief. Skip a step's question when the answer is already known.

### Step 1. Template or one-time

Ask: *Is this app a template we will sell or set up for several clients, or a
one-time build for one client?*

- **Template**: name the first client (the pilot) and, if known, the next
  two. Ask what will differ between clients and write it down; that list is
  the client config (see `reference/template-config.md`). Typical: name,
  logo, colours, domain, languages, contact details, which modules are on,
  plans and prices, tax details, the client's admin emails. Ask the tenancy
  question: **one deployment per client** (recommended when clients are few,
  data must be kept apart, or clients pay for their own hosting) or **one
  deployment for all clients** (recommended when clients are many and small;
  every row carries a client id and every query is scoped by it).
- **One-time**: name the client and move on. Write *"One-time build. No
  reuse strategy."* in the brief and keep every later answer free of
  configuration talk.
- Recommend: one-time unless the user names at least a second likely client
  or says it is a product. A template built for one client is overhead the
  client pays for.

### Step 2. Actors and their data

Ask: *Who uses the app, and what does each of them create, see, change or
delete?*

Build a table, one row per actor: the role (for example patient, doctor,
receptionist, client admin, Bhadraavel operator, the public), how they sign
in (none, email one-time code, Google, phone OTP, password), what they
**create**, **read**, **update**, **delete**, and on which device (phone,
desktop, both). Then, for the data:

- **Who owns each kind of record** (the person, the client's business, or
  Bhadraavel), who may see it, and who may export or delete it.
- **Personal or sensitive data**: health, financial, children's, location,
  identity documents, caste or religion. Flag each; the domain research
  (step 6) brings the rules for them.
- **Where data comes from**: typed in, imported from a spreadsheet or another
  system, from an API, from devices. Ask for a sample of any import.
- **How long it is kept** and what happens when an account is closed.
- **Offline**: does any actor work without a connection (field staff,
  villages, hospitals' basements)?

Push back on: actors who share one login ("the staff will all use the admin
account"; recommend a login each, so there is an audit trail and a way to
remove someone who leaves), and on collecting sensitive data the app does
not need.

### Step 3. Who runs the app day to day

Ask: *Once it is live, who manages users and data: the client's own admin,
or Bhadraavel support on their behalf?* Offer three:

- **Client self-managed** (recommended for most): the client has an admin
  role in the app for their users, content and settings. Bhadraavel support
  only handles tickets through the support desk and fixes bugs.
- **Client-managed with light Bhadraavel support**: the client admin does the
  daily work; Bhadraavel operators can step in for a short list of tasks
  (reset an account, restore a deleted record, change a plan, import data).
  Write down the list, who asks (a ticket on the support desk), and how fast.
- **Bhadraavel-managed**: the client has no admin; Bhadraavel does
  everything. Recommend against unless the client pays for that service: it
  makes every routine change a ticket.

Write in the brief: the admin role's powers (a list), what only a Bhadraavel
operator may do, and the support channel (always the support desk; see
`bhadraavel-support`).

### Step 4. The Bhadraavel operator interface

Ask: *Does the Bhadraavel team need its own screens to run this app?* It is
needed when step 3 is the second or third option, when the app is a template,
or when the app charges money. Offer, as a multi-select:

- **Client (tenant) management** - templates only: add a client, edit their
  config, suspend, see their usage.
- **User management** - find any account, see its role and status, resend a
  sign-in, disable, delete on request (with the person's data export).
- **Subscription management** - see a client's or person's plan and its
  dates, grant or extend days, refund (the `bhadraavel-razorpay` admin
  screen does this per app).
- **Plan management** - plans, prices, coupons (also `bhadraavel-razorpay`).
- **Audit log** - who did what, when, from the operator side especially.
- **Usage and health** - sign-ups, active users, errors, storage, last
  backup.

Where it lives: an **operator role inside the app** (recommended: the app
already knows its data; an `OPERATOR_EMAILS` list or a role, never a shared
password), and the **support hub** for tickets, which already exists at
support.bhadraaveltechnologies.com. A separate cross-app console is a
project of its own; suggest it only when several template clients need the
same screens. Every operator action is written to the audit log and is
visible to the client admin.

### Step 5. The minimum the client must hand over for launch

Build the launch checklist from the answers so far, with an owner and a date
for each line. Always:

- Legal name of the business, address, GST number (if registered), contact
  email and phone for the policy pages and the footer's Contact page.
- The domain (or approval to use a subdomain of bhadraaveltechnologies.com),
  and who holds the DNS.
- Logo (SVG or a large PNG), colours, and the app's name in every language
  it will show.
- The list of admin accounts (emails or phone numbers) and their roles.
- The content the app cannot start without: the first catalogue, price list,
  services, staff, questions, whatever the domain needs; with a sample in
  the format it will come in.
- Approval of Privacy Policy and Terms (drafted by us from the
  `bhadraavel-razorpay` legal reference or the app's own, read by them).

When it applies:

- Payments: a Razorpay account in the client's name with KYC done, or the
  decision that Bhadraavel collects and pays out (and the contract for it);
  plan names and prices; GST treatment (see `bhadraavel-razorpay`).
- Regulated data: the consent wording, and any licence or registration the
  domain needs (for example a clinic's registration, an FSSAI licence for
  food, a drug licence for a pharmacy).
- Messaging: a WhatsApp Business number, an SMS sender id with DLT
  registration (India), or an email sender domain with SPF and DKIM.
- App stores: a Google Play / Apple developer account in the client's name,
  if the app ships to stores.
- Data migration: the export from their current system or spreadsheet.

Mark each line **must have for launch** or **can follow**. Keep the must-have
list short; a launch waiting on a nice-to-have is a launch that slips.

### Step 6. Domain research and suggestions

Follow `reference/domain-research.md`. If the domain is not clear, ask first
(decision 6). Research with web search: how the best apps in this domain
work, what the domain's users expect, the rules that apply in the client's
country and state, and the common ways such projects fail. Then write
**Suggestions** in the brief: each one a short title, why (the finding with
its source), the effort (small / medium / large), and whether it is for
launch or later. Five to ten good suggestions beat thirty generic ones. Ask
the user which to take; the taken ones become requirements, the rest stay
under *Considered, not now*.

### Step 7. Challenge, then confirm

Read the whole set of requirements back as the brief. For anything that
looks unwise, say so once, with the reason and a better option (decision 7).
Typical flags:

- No sign-in where personal data is shown; or sign-in where none is needed.
- "Everything on day one": suggest a launch scope and a second phase.
- Storing card numbers, Aadhaar numbers or passwords the app does not need.
- A native app when a phone-friendly website (with home-screen install)
  does the job; or the reverse, when the app needs background location,
  Bluetooth or offline work.
- Copying a competitor's name, look or content.
- WhatsApp or SMS blasts to people who did not opt in.
- A price that does not cover hosting, messaging and payment fees.
- A custom build of something a well-known service does well (maps,
  video calls, accounting).

Then ask the user to confirm the brief, or say what to change. Their word
on a flagged item is final; record it and move on.

## 4. Writing the brief

Write `docs/requirements.md` from `reference/brief-template.md`, in the
repository the app will live in (section 5), or in the current working
directory when the repository does not exist yet (and move it in once it
does). Plain English, short sentences, the user's own words in quotes where
they made a rule. Date it. List open questions at the end with who answers
each. Commit it with the repository's first commit, or on the working
branch.

## 5. Does it need a new GitHub repository?

Decide from the answers and tell the user which case it is:

| Case | Repository |
|---|---|
| A new one-time app | **New repository.** |
| A new template (the first client is the pilot) | **New repository** for the template. Clients are config inside it (or per-client deployment settings), never repositories. |
| A new client of an existing template | **No new repository.** Add the client's config to the template's repository. Exception: the client's contract requires them to own the code; then a repository in *their* organisation, synced from the template's releases, and say what that costs. |
| A feature or module for an existing app | **No new repository.** Work in that app's repository. |
| A website or landing page only | Usually a folder or route in `website`; new repository only if it is a separate brand. |

When a new repository is needed:

1. Propose a name: lower-case, hyphenated, short, the product's name not the
   client's (for a template), the client's for a one-time app (for example
   `myclinicapp`, `acme-orders`). Owner **bhadraaveltechnologies**,
   **private**. Ask the user to confirm both before creating.
2. Create it: with the GitHub MCP tool `create_repository` (organisation
   `bhadraaveltechnologies`, private, with a README) when the session is
   allowed to; otherwise give the user the exact steps (GitHub →
   bhadraaveltechnologies → New repository → name → Private → Add a README)
   or `gh repo create bhadraaveltechnologies/<name> --private --add-readme`.
   Never create it under a personal account.
3. First commit: `README.md` (what the app is, for whom, the brief's
   summary), `docs/requirements.md`, `.gitignore` for the chosen stack, and
   `.env.example` with the names only.
4. Add it to the SkillFactory's `sync-targets.json` (`{ "repo": "<name>" }`,
   with `"base"` when pull requests go to a branch other than the default)
   and commit that to Bhadraa-SkillFactory, so the house skills reach it.
   Remind the user that the `SKILLS_SYNC_TOKEN` must cover the new
   repository (see the SkillFactory README) unless it has access to all.
5. Register the app on the support hub (the command is in
   `bhadraavel-support`) once the app's name, id and ticket prefix are known.

## 6. Done when

- Every step in section 3 has an answer in the brief, or an open question
  with an owner.
- The domain research is in the brief with sources, and the user has chosen
  which suggestions to take.
- Flagged requirements are either changed or recorded as client decisions
  against our advice.
- The repository question is answered; if a repository was needed, it exists,
  holds the brief, and is in `sync-targets.json`.
- The user has said the brief is right. Only then does building start, with
  the brief as the scope.
