# Domain research

The point is to come back with things the client did not think of, each one
backed by a source, and sized so they can choose. Not a report on the
industry.

## 0. Know the domain first

If the request does not make the business clear, ask: what the business
sells or does, who its customers are, where (country, state, city or
village), how big (people, branches, customers), and how they do it today
(paper, spreadsheet, WhatsApp, another app). Do not research a guessed
domain.

## 1. Questions to answer

1. **How do the best apps in this domain do it?** Three to five products
   used by the client's kind of business, in India and abroad. What they all
   have (the table stakes), what the good ones add, what their users
   complain about in store reviews and forums.
2. **What do the client's own users expect?** Language (which Indian
   languages; is voice or large text needed), device (low-end Android,
   patchy data), payment habits (UPI first), how they are reached
   (WhatsApp more than email).
3. **Which rules apply?** See section 2. Name the rule and what it means for
   the app in one line.
4. **How do these projects fail?** Adoption (staff go back to paper), data
   entry burden, a missing integration, messaging costs, a regulator.
5. **What does it cost to run?** Hosting, SMS/WhatsApp per message, payment
   gateway fees, maps, storage for photos and documents. Compare with what
   the client expects to charge or spend.

Use web search for each; prefer primary sources (the regulator, the
platform's own docs, the standard) and recent ones. Write each finding in
one line with its link.

## 2. Rules that keep coming up (India)

Check each against the app; list only those that apply.

- **Digital Personal Data Protection Act, 2023** and its Rules: consent
  wording, a stated purpose, the right to access, correct and erase, a
  contact for grievances, breach reporting, extra care for children's data
  (verifiable parental consent).
- **IT Act 2000 and the SPDI Rules (2011)**: reasonable security for
  sensitive personal data (passwords, financial, health, biometrics).
- **Health**: the Telemedicine Practice Guidelines (2020) for consultations,
  ABDM / ABHA for health records if the client wants interoperability,
  the Clinical Establishments rules of the state; prescriptions only by a
  registered practitioner.
- **Payments**: RBI rules on card storage (tokenisation, never store card
  numbers), recurring payments and e-mandates (additional factor, pre-debit
  notice), and Razorpay's own review (`bhadraavel-razorpay`).
- **Tax**: GST registration, invoices with GSTIN, HSN/SAC codes, the place of
  supply.
- **Messaging**: TRAI's DLT registration for SMS (sender id and templates),
  WhatsApp Business policy (opt-in, approved templates, per-conversation
  charges).
- **Food**: FSSAI licence number shown, allergen and veg/non-veg marks.
- **Education and children**: parental consent, no tracking or ads aimed at
  children.
- **Finance, insurance, investments**: RBI, IRDAI or SEBI registration;
  usually means the app must not give advice without a licence.
- **Accessibility**: WCAG 2.2 AA as the target for anything public (and
  GIGW for government-facing work).
- **App stores**: Google Play's data safety form, account deletion from
  inside the app, health and finance app declarations.

Outside India, find the equivalents (GDPR in the EU and UK, HIPAA for US
health data, and so on).

## 3. Turning findings into suggestions

Each suggestion in the brief:

- **Title**: what to add or change, in a few words.
- **Why**: the finding and its source.
- **Effort**: small (hours), medium (days), large (weeks).
- **When**: launch or later.

Good suggestions are specific to this client: "Send the appointment reminder
on WhatsApp in Tamil the evening before; clinics in the research cut no-shows
this way" beats "Add notifications". Prefer suggestions that remove work for
the client's staff or their customers.

Sort them: anything a rule requires first (these are not optional; say so),
then the ones that most help adoption, then the rest.
