# <App name>: requirements

Date: <date> · Client: <client> · Prepared by: Bhadraavel Technologies LLP
Status: Draft | Confirmed by <name> on <date>

## 1. Summary

Two or three sentences: what the app does, for whom, and why now.

## 2. Template or one-time

- Kind: **Template** | **One-time build. No reuse strategy.**
- Template only: pilot client, next clients, tenancy (one deployment per
  client | one deployment for all), and the client config (see 2.1).

### 2.1 Client config (templates only)

| Setting | Example | Required |
|---|---|---|
| Name, logo, colours | | yes |
| Domain | | yes |
| Languages | | |
| Modules on | | |
| Plans and prices | | |
| Tax details (GSTIN, state) | | |
| Admin accounts | | yes |

## 3. Actors

| Actor | Signs in with | Creates | Reads | Updates | Deletes | Device |
|---|---|---|---|---|---|---|

## 4. Data

| Data | Owner | Who sees it | Sensitive? | Source | Kept for | On account close |
|---|---|---|---|---|---|---|

Offline needs: <none | who and what>.

## 5. Running the app

- Model: client self-managed | client-managed with light Bhadraavel support |
  Bhadraavel-managed.
- Client admin can: <list>.
- Only a Bhadraavel operator can: <list>.
- Support channel: the support desk (`bhadraavel-support`), categories: <list>.

## 6. Bhadraavel operator interface

| Screen | Needed | Where | Notes |
|---|---|---|---|
| Client (tenant) management | | | |
| User management | | | |
| Subscription management | | | |
| Plan management | | | |
| Audit log | | | |
| Usage and health | | | |

## 7. Features

### 7.1 Launch

Numbered, each one testable: "A receptionist can book a slot for a patient
from the phone in under a minute."

### 7.2 Later

### 7.3 House skills

Footer (`bhadraavel-footer`), support desk (`bhadraavel-support`), and:
<payments `bhadraavel-razorpay` | share `bhadraavel-share` | images
`bhadraavel-gemini-image`>.

## 8. Launch checklist (from the client)

| Item | Must have / can follow | Owner | Due | Done |
|---|---|---|---|---|

## 9. Domain research

Short findings, each with its source link.

## 10. Suggestions

| # | Suggestion | Why (source) | Effort | Launch / later | Taken? |
|---|---|---|---|---|---|

## 11. Our recommendations and the client's decisions

| Ask | Our advice and why | Client's decision |
|---|---|---|

### Client decisions against our advice

Each with the risk, as told to the client on <date>.

## 12. Repository

- Case: new one-time app | new template | client of template <name> |
  feature of <app> | website.
- Repository: `bhadraaveltechnologies/<name>` (private) | none needed.
- Added to SkillFactory `sync-targets.json`: yes | no.
- Registered on the support hub: yes | not yet.

## 13. Open questions

| Question | Who answers | By |
|---|---|---|

## 14. Considered, not now
