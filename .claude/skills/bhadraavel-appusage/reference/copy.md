# Wording: the Usage screen, the daily summary, the privacy section

Plain English. Use the app's own tone and translate the privacy section into
every language the app ships; the admin screen is operator-only and stays in
English.

## The Usage screen (`/admin/usage`)

**Title:** Usage

**Under the title:** Who joined, renewed and visited, day by day. Times are
India time (IST). Your team's own visits are not counted.

**Day picker:** ‹ Previous day · *21 November 2026* · Next day › · Today

**Tiles (in this order):**

| Tile | Number | Small line under it |
|---|---|---|
| New customers | registrations | *3 started a trial* |
| Paid for the first time | first payments | *2 after a trial* |
| Renewals | renewals | |
| Revenue | first payments + renewals, ₹ with GST as charged | *1 refund (₹999)* when there was one |
| Visitors | distinct visitors | *48 signed in · 112 not signed in* |
| Page views | page views | |

**Customers seen today** (by status, as chips): Paid 31 · Trial 12 · Free
access 2 · Expired 3 · No plan 0

**Section: By feature** - table: Feature · Visitors · Customers · Page views.

**Section: Where visitors came from** - toggle *Country · State · City*;
table: Place · Visitors · Customers. Footnote: *Places are worked out from
the network address when the page is opened and are approximate (city
level at best). The address itself is not kept.* Then the attribution the
database licence needs: *IP Geolocation by [DB-IP](https://db-ip.com).*

**Section: Customers** - filter chips *All · Joined today · Renewed today ·
Paid · Trial · Expired*, a search box (*Name, email or phone*), and a table:
Name · Email · Phone · Status · Plan · Ends · Joined · City, State, Country ·
Used today · Events today. Status words: **Paid**, **Trial**, **Free
access** (coupon or admin grant), **Expired**, **No plan**.

**Button:** Download CSV (this day) - and *Download CSV (date range)* in the
menu next to it, up to 92 days.

**Line above the customer table:** *Personal details. Use them only to run
and support this app, and do not copy them anywhere else. Every view and
download is logged.*

**Empty states:**
- No events and no visits: *Nothing recorded on this day yet.*
- Before the skill was applied: *Usage is recorded from 21 November 2026.*
- Place unknown: *Unknown* (in the place table), *-* (in the customer row).

## The daily summary (optional, sent at 08:00 IST for the day before)

Subject / first line: **{App}: yesterday, {20 Nov}**

```
New customers 5 (trials 3) · First payments 2 · Renewals 4
Revenue ₹6,993 · Refunds 0
Visitors 160 (48 signed in) · Page views 902
Top features: Calendar 96, Notes 41, Pricing 22
Top places: Tamil Nadu 88, Karnataka 31, Kuala Lumpur 9
{link to /admin/usage?day=2026-11-20}
```

No names, emails or phone numbers in the summary: it travels by Telegram or
email. The people behind the numbers are on the screen.

## Privacy Policy: section to add ("How we measure use of {App}")

> **How we measure use of {App}**
>
> To run {App} and decide what to improve, we record:
>
> - when you create your account, start a trial, pay for or renew a plan, and
>   which plan;
> - which parts of {App} you open each day, and how often;
> - the town or city, state and country your connection comes from, worked
>   out from your network address when a page is opened. We do not store the
>   network address itself, and we do not use your device's location (GPS).
>
> If you are not signed in, we count your visit for that day without
> knowing who you are and without setting a cookie; the next day we cannot
> connect it to the earlier visit.
>
> These records are used only by the {App} team at Bhadraavel Technologies
> LLP to run and support the service. We do not sell them, share them with
> advertisers or use them for advertising. Page-visit records are deleted
> after about 13 months; records of your account and payments are kept for
> as long as your account is open and as long as the law requires for
> payment records. You can ask to see or delete what we hold about you
> through {Help link}.

## Release-log line (when the screen ships)

Admin-only: **no release-log entry** (the screen is operator-only). The
privacy-policy change is user-visible: *Improved: the Privacy Policy now
explains how we measure use of {App}, and what we never keep.*
