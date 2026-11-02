# Payments FAQ

Two parts: the questions customers ask (shown under the plans on `/pricing`
and linked from the Account page's Plan section), and the questions whoever
runs the business will ask. Replace `{App}`, `{email}`, the refund window and
the tax line with the app's own; keep the answers short and kind. Timings
for banks and Razorpay are the usual ones, so say "usually" and never promise
a day.

## For customers (on the Pricing page)

**How do I pay?**
Through Razorpay, a payment service licensed in India: UPI (GPay, PhonePe,
Paytm and others), debit and credit cards, net banking and popular wallets.
The payment opens in Razorpay's own secure window.

**Do you see or keep my card or bank details?**
No. Razorpay handles them on its side. We only receive a payment reference,
the amount and whether it succeeded.

**Will my plan renew automatically?**
No. Each plan is paid once for a fixed number of days. We remind you inside
the app a week before it ends, and you decide whether to continue.

**I paid early. Do I lose the days I had left?**
No. A new plan starts when your current one ends, so the days add up.

**Can I switch plans?**
Yes: pick the new plan at any time; it starts when your current plan ends. If
you need it sooner, write to us and we'll help.

**The money left my account but my plan doesn't show. What now?**
Please refresh the page first; confirmation can take a minute. If it still
doesn't show, write to us through Help with the payment reference (it begins
with `pay_`, in Razorpay's email or your UPI app), and we'll put it right.
If a payment failed but money was debited, your bank usually returns it by
itself within 5–7 working days.

**I was charged twice.**
Write to us with both references. The extra payment is refunded in full.

**Can I get a refund?**
Yes, within {7} days of a first purchase, in full. The Cancellation and
Refunds page has the details. Refunds go back to the method you paid with and
usually reach you within 5–7 working days after we send them.

**How do I cancel?**
There is nothing to cancel: a plan simply ends on its last day and nothing
more is charged. If you want your account and data deleted as well, write to
us.

**What happens when my plan ends?**
{App} pauses and shows the Plans page. Your data stays safe for {90} days,
so you can carry on exactly where you left off when you renew.

**How do coupon codes work?**
Tap *Have a coupon code?* under the plans, type it and press Apply; the new
price shows before you pay. A code may be for certain plans, for a limited
time, or for one account only, and usually works once per account. Some codes
cover the whole price; then no payment is needed at all.

**Do prices include tax?**
{Prices include all taxes. | Prices are shown before GST; GST is added at
checkout where it applies.} If you need a GST invoice for your business,
write to us with your GSTIN and the payment reference.

**Can I pay from outside India?**
{Cards issued outside India are accepted. | At the moment we accept payments
made in India only.}

**I use {App} on my phone from the Play Store. Where are the plans?**
Plans are taken on our website ({site}) from any browser. A plan taken there
works in the app at once, with the same account.

**Something else?**
Reach us through Help. We usually reply within two working days.

## For the business (operator FAQ)

**Where does the money go, and when?**
Into the bank account linked to the Razorpay account. Settlements are
typically made a couple of working days after each payment (Razorpay shows the
schedule under Settlements). Razorpay's fee and GST on that fee are deducted
from each settlement.

**A customer says they paid but are locked out.**
Look the person up on the admin screen (or `GET /api/admin/accounts?email=`).
If the payment shows as `created` or `failed` but Razorpay's dashboard shows
it *captured*, the webhook was missed: re-send it from the dashboard
(Webhooks → the delivery → Retry) or grant the days by hand with a note
naming the payment id. Then tell the person it's fixed.

**How do I refund?**
From Razorpay's dashboard (Transactions → Payments → the payment → Issue
Refund), full or partial, or through the admin refund action if the app has
one. The `refund.processed` webhook marks the payment refunded. The person's
access is *not* cut automatically: decide, then use *End period* on the admin
screen if their plan should stop.

**How do I give someone a free month?**
Either grant days on the admin screen (fastest, for one person you are
talking to), or make a 100% coupon for that person's email and one plan, and
send them the code (they start it themselves).

**How do I run a sale?**
Make a percent coupon with an end date (and a total limit if you like), and
share the code. Switch it off early from the admin screen if needed; codes
already used stay counted.

**A coupon brought a price under ₹1.**
Razorpay can't take less than ₹1, so the price is rounded up to ₹1. A coupon
that covers the whole price skips payment altogether.

**What is a dispute or chargeback?**
A customer asked their bank to reverse a payment. Razorpay emails you and
shows it under Disputes with a deadline. Answer with the evidence it asks for
(the account's email, the payment, when the plan was used). Losing one
returns the money to the customer; end their period if appropriate.

**Test mode vs live mode?**
Test keys (`rzp_test_…`) move no real money; use them on a staging site with
Razorpay's test cards and test UPI ids (listed in Razorpay's docs). Live keys
(`rzp_live_…`) only after the account is activated. Test and live have
separate keys *and* separate webhooks and secrets.

**Can the key secret be rotated?**
Yes: regenerate it in Razorpay (Settings → API Keys), put the new one in the
server's `.env`, restart. Do it at once if it was ever pasted anywhere
public.
