# Wording for subscriptions and payments

Every line a person sees around plans, coupons and payment. The register is
the house one: gentle, warm and humble; these screens meet people at the
moment money is involved, and sometimes when something has gone wrong. In
any language other than English use the respectful forms (Tamil நீங்கள்,
Hindi आप, Telugu మీరు, Kannada ನೀವು, Malayalam നിങ്ങൾ, Malay *anda*) and
follow the app's own CLAUDE.md on translations.

Placeholders: `{App}` the app's name, `{plan}` a plan's name, `{days}`,
`{price}` / `{total}` / `{discount}` already formatted (`₹799`, `₹719.10`),
`{date}` a long date (`1 December 2026`), `{ref}` a Razorpay payment id,
`{code}` a coupon code, `{email}` the support address
(support@bhadraaveltechnologies.com).

## Pricing page (`/pricing`, public)

- Title: **Plans**
- Lead, billing on: *Pick the plan that suits you. Each plan is paid once for
  a fixed number of days and does not renew by itself; you choose when to
  continue.*
- Lead, with a trial: *A new account has {days} days free first. After that,
  pick the plan that suits you.*
- Lead, billing off: *{App} is free to use at the moment. When plans open,
  these are the ones, and you will see everything here before anything is
  charged.*
- Plan card: **{plan}** · **{price}** · *{days} days* · the plan's one-line
  description · button **Choose {plan}**. The longest plan may carry a quiet
  tag *Best value* (only when it really is the cheapest per day).
- Price note under the cards: *Prices are in rupees and include all taxes.*
  (or *Prices are in rupees; GST is added at checkout where it applies.* when
  the business charges GST on top: say whichever is true, never both).
- Methods line: *Pay securely with UPI, cards, net banking or wallets,
  through Razorpay.*
- Trust line: *We never see or keep your card or bank details.*
- Signed out: button **Sign in to subscribe** (to sign-in, then back here).
- Questions line: *Questions? See the FAQ below, or reach us through Help.*

## Coupon field

- Link under the plans: **Have a coupon code?** (opens the field; never shown
  open by default, so people without one don't feel they are missing out).
- Field placeholder: *Coupon code* · button **Apply**.
- Applied: *Coupon {code} applied: {discount} off. You pay {total}.*
- Applied, free: *Coupon {code} covers the whole price. Press Start {plan} to
  begin; no payment is needed.* Button becomes **Start {plan}**.
- Remove link: **Remove coupon**.
- Refusals (the server's `COUPON_MESSAGES`, word for word):
  - format: *That doesn't look like a coupon code. Check it and try again.*
  - unknown: *We couldn't find that coupon code. Check the spelling and try again.*
  - inactive: *This coupon is no longer available.*
  - not_yet: *This coupon isn't open yet. Please try again from its start date.*
  - expired: *This coupon has expired.*
  - plan: *This coupon doesn't apply to the plan you picked. Try another plan.*
  - account: *This coupon was issued for a different account.*
  - used: *You've already used this coupon.*
  - exhausted: *This coupon has been fully used.*
  - first_purchase: *This coupon is for a first subscription only.*
  - currency: *This coupon can't be used with this plan's currency.*

## Checkout (Razorpay's window)

- `name`: the app's name. `description`: *{plan} plan · {days} days*.
- `prefill.email`: the account's email (and `contact` if the app has a phone).
- `theme.color`: the app's accent colour.
- While the order is being made: button text *Opening payment…* (disabled).
- Order could not be made: *We couldn't start the payment just now. Please try
  again in a minute; nothing has been charged.*

## After checkout

- Verifying: *Confirming your payment…*
- Success: *Thank you! Your {plan} plan is active until {date}.* Button
  **Continue to {App}**.
- Success, stacked: *Thank you! Your {plan} plan starts when the current one
  ends; you're covered until {date}.*
- Closed the window (`modal.ondismiss`): *Payment cancelled. Nothing was
  charged. You can pick a plan again whenever you're ready.*
- Failed (`payment.failed` from Checkout): *The payment didn't go through:
  {Razorpay's error.description}. Nothing was charged. Please try again, or
  use another method.*
- Couldn't confirm (verify call failed or timed out, money may have moved):
  *We received your payment but couldn't confirm it just yet. It usually
  sorts itself out in a few minutes; please refresh this page. If your plan
  still doesn't show, write to us through Help with the payment reference
  {ref} and we'll put it right.*
- Already counted (a retry): *This payment is already counted. Your plan is
  active until {date}.*

## The wall (billing on, no current subscription)

Shown in place of the app, on `/pricing`, after sign-in:

- Never subscribed (no trial): **Welcome to {App}.** *To start using {App},
  please pick a plan below.*
- Trial ended: **Your free trial has ended.** *Nothing is lost: everything you
  added is here, waiting. Pick a plan to carry on.*
- Plan ended: **Your {plan} plan ended on {date}.** *Your data is safe. Pick a
  plan to carry on where you left off.*
- Always under it: *Signed in as {email}. Not you? Sign out.* and *Questions,
  or paid but locked out? Reach us through Help.*

## Reminders inside the app

- 7 days left: *Your plan ends on {date}. Renew any time; the new days are
  added on after the current ones, so nothing is lost by renewing early.*
  (dismissible, shown once a day)
- Last day: *Your plan ends today. Renew to keep using {App} without a break.*
- Trial, 3 days left: *Your free trial ends on {date}. Pick a plan to keep
  going.*

## Account page, Plan section

- Heading: **Plan**
- Active: *{plan}, active until {date} ({days} days left).*
- Trial: *Free trial, until {date}.*
- None: *No active plan.* Link **See plans**.
- Payment history rows: *{date} · {plan} · {total}{ · coupon {code}} ·
  {Paid | Failed | Refunded | Free with coupon}* with the Razorpay reference
  in small text.
- Under the history: *Need a receipt or a refund? Write to us through Help
  with the payment reference.*

## Android store build

When the app runs as the Play Store wrapper, every price, plan and button is
hidden (Google's policy on digital goods). In their place:

- *Plans are managed on our website. Visit {site} from a browser to see
  them; a plan taken there works here at once.* (No link that opens checkout
  inside the app.)

## Admin screens

- Coupon created: *Coupon {code} is ready: {25% | ₹100} off{ on {plans}}{,
  for {email} only}{, until {date}}. Share the code with the person.*
- Coupon switched off: *Coupon {code} is switched off. Codes already used
  stay counted.*
- Days granted: *Added {days} days to {email}. Their plan now runs until
  {date}.*
- Period ended early: *Ended that period for {email}. Their access now runs
  until {date | today}.*
- Refund issued: *Refund of {total} sent to Razorpay for {ref}. It reaches
  the customer in 5–7 working days. Decide separately whether to end their
  period.*
- Payments not configured: *Online payment is off: RAZORPAY_KEY_ID and
  RAZORPAY_KEY_SECRET are not set on the server.*
- Webhook not configured: *The webhook secret is not set: payments still
  count through the browser, but a closed tab could miss one. Set
  RAZORPAY_WEBHOOK_SECRET.*

## Release-log lines (for the app's What's new)

- added: *Plans: subscribe monthly, quarterly or yearly, paying securely
  with UPI, cards or net banking through Razorpay.*
- added: *Coupon codes: enter one on the Plans page for a discount.*
- improved: *The Account page shows your plan, when it ends, and every
  payment.*
