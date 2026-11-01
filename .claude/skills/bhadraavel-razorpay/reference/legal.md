# Policy pages for paid plans

Razorpay reviews the website before it activates live payments, and the
review generally looks for these pages, linked from every page's footer and
reachable signed out: **Terms and Conditions, Privacy Policy, Cancellation
and Refunds, Shipping and Delivery, Contact Us**, plus visible prices.
Templates for each follow: the billing parts to add to the app's existing
Privacy and Terms, and the whole of the other three.

Fill every `{…}`. **Never invent business details**: the registered address,
phone number, GSTIN, refund window and jurisdiction come from the user; ask
for them and leave the placeholder visible until they answer. Defaults
offered below (a 7-day refund window, 90 days of data kept after a plan ends)
are suggestions for the user to confirm. These are templates, not legal
advice: suggest a review by the user's advisor before going live.

Constants: legal entity **Bhadraavel Technologies LLP**, support address
**support@bhadraaveltechnologies.com**, website of the company
**https://www.bhadraaveltechnologies.com**. Dates: an "Effective {date}" line
at the top of each page, changed whenever the text changes. Other languages:
the polite register (see copy.md), with a note that the English version
prevails on any conflict.

---

## Privacy Policy: sections to add

**Payments.** When you buy a plan, the payment is processed by Razorpay
Software Private Limited ("Razorpay") under its own privacy policy
(https://razorpay.com/privacy/). You enter your card, UPI or bank details in
Razorpay's window, not ours; we never receive or store them. From Razorpay
we receive and keep: the payment and order references, the amount, the
currency, the payment method type (for example "UPI" or "card"), the status,
and the email or phone you gave Razorpay. We keep these to show your plan and
payment history, to answer questions and refunds, and for our accounts.

**Coupons.** If you use a coupon code, we record which code, the discount
and when, against your account.

**How long payment records are kept.** Payment and invoice records are kept
for as long as tax and accounting law requires (in India, generally eight
years), even if you delete your account; everything else is deleted as
described above.

**Sharing.** We share with Razorpay only what a payment needs: the amount,
your email{ and phone}, and a reference to your account. We never sell
personal information.

## Terms and Conditions: sections to add

**{n}. Plans and prices.** {App} is offered on prepaid plans, each giving
access for a fixed number of days ({the plans, e.g. Monthly, 30 days;
Quarterly, 90 days; Yearly, 365 days}). Prices are shown on the Plans page
in Indian rupees{ and include all applicable taxes | ; GST is added at
checkout where it applies}. We may change prices for the future; a change
never affects a plan already paid for.

**{n}. No automatic renewal.** A plan is paid once and ends on its last day.
Nothing is charged again unless you choose to buy another plan. A new plan
starts when the current one ends, so no paid days are lost.

**{n}. Free trial.** {If the app has one:} A new account may use {App} free
for {14} days. Only one trial is given per person. {Else delete this
section.}

**{n}. Access.** While a plan or trial is active you may use {App} as these
terms allow. When it ends, {App} is paused until a new plan is bought; your
data is kept for {90} days after that, then it may be deleted.

**{n}. Payment.** Payments are processed by Razorpay. A payment counts once
Razorpay confirms it. If a payment fails but money is debited, it is
normally returned to you by your bank or Razorpay; write to us if it is not.

**{n}. Coupons.** Coupon codes are offered at our discretion, have no cash
value, cannot be exchanged or transferred unless we say so, may be limited
to certain plans, dates, accounts or numbers of uses, and may be withdrawn
at any time before they are used. A coupon used on a purchase that is
refunded is not reissued.

**{n}. Refunds.** As set out on the Cancellation and Refunds page.

**{n}. Fair use.** {App} is for personal use by the account holder. Sharing
an account or reselling access is not allowed; we may suspend an account
that does so, after telling you why.

**{n}. Governing law.** These terms are governed by the laws of India, and
the courts at {city, state} have jurisdiction.

## Cancellation and Refunds (whole page)

Title: **Cancellation and Refunds** · Effective {date}

**1. Cancelling.** Plans do not renew, so there is nothing to cancel: your
plan simply ends on its last day and nothing more is charged. If you would
like your account and data deleted, write to us at
support@bhadraaveltechnologies.com from your account's email address.

**2. Refunds of a first purchase.** If {App} is not right for you, you may
ask for a full refund within {7} days of your first payment.

**3. Later purchases.** A renewal or an additional plan can be refunded in
full within {7} days of payment if you have not yet started using the days
it bought (it is still queued after your current plan).

**4. After that.** After {7} days, plans are not refundable, except where we
were unable to provide {App} for a substantial part of your plan; then we
refund the unused part.

**5. Payments made in error.** A duplicate payment, or a payment taken when
no plan was given, is refunded in full whenever you tell us.

**6. Failed payments.** If a payment failed but money left your account,
your bank or Razorpay normally returns it on its own, usually within 5–7
working days. If it has not arrived after that, write to us with the
payment reference and we will follow it up.

**7. Coupons and free plans.** A plan given free (through a full-value
coupon or by us) is not refundable. For a discounted plan, the refund is the
amount you actually paid.

**8. How refunds are made.** To the payment method you used, through
Razorpay. Once we confirm a refund it usually reaches you within 5–7
working days, depending on your bank. When a plan is refunded, its access
ends.

**9. How to ask.** Write to support@bhadraaveltechnologies.com, or use the
Help page, with your account's email and the payment reference (it starts
with `pay_`). We reply within two working days.

## Shipping and Delivery (whole page)

Title: **Shipping and Delivery** · Effective {date}

{App} is an online service; nothing is shipped. A plan is delivered at once:
as soon as Razorpay confirms your payment (usually within seconds), the plan
is active on your account and {App} is ready to use on any device where you
sign in. You will see the confirmation on screen, and the plan and its end
date on your Account page.

If your plan does not show within a few minutes of a successful payment,
please write to us at support@bhadraaveltechnologies.com or through the
Help page with the payment reference, and we will activate it.

## Contact Us (whole page, or the app's Contact/Help page)

Title: **Contact us**

- **Business:** Bhadraavel Technologies LLP
- **Registered address:** {full postal address, from the user}
- **Email:** support@bhadraaveltechnologies.com
- **Phone:** {phone, from the user, with hours, e.g. Monday to Friday, 10 am to 6 pm IST}
- **Help form:** {site}/help (or /contact): we usually reply within two working days.
{- **GSTIN:** {GSTIN} (only if registered)}

Keep the help form (the `bhadraavel-support` skill) on this page: it is the
way most people will reach us.
