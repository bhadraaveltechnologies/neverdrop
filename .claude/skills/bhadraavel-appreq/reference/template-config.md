# Making a template app configurable

Only for apps the interview marked **template**. A one-time build uses none
of this.

## The rule

One codebase. A new client is a config file plus its secrets, and nothing
else: no code change, no branch, no copied repository. If onboarding a client
needs a code change, the change is made once for everyone (behind a module
switch) or the client is a one-time build.

## The client config

One file per client, `clients/<client-id>.json` (or a row in a `clients`
table when one deployment serves everyone), validated at start-up against a
schema; the app refuses to start with an invalid one and says which field.

```json
{
  "id": "acme",
  "name": "Acme Clinic",
  "domain": "acme.example.com",
  "brand": { "logo": "clients/acme/logo.svg", "primary": "#0B6E4F", "accent": "#F2A541" },
  "languages": ["en", "ta"],
  "defaultLanguage": "en",
  "timezone": "Asia/Kolkata",
  "contact": { "email": "help@acme.example.com", "phone": "+91 ...", "address": "..." },
  "legal": { "entity": "Acme Health Pvt Ltd", "gstin": "33ABCDE1234F1Z5", "state": "Tamil Nadu" },
  "modules": { "appointments": true, "billing": true, "share": false },
  "admins": ["owner@acme.example.com"],
  "support": { "appId": "acme", "prefix": "ACM" }
}
```

Keep it **minimal**: only what really differs between clients. Defaults live
in code; a client file states only what it changes. If a setting has been
the same for every client for months, remove it from the config.

## Never in the config file

Secrets (payment keys, API keys, database passwords, the support hub key).
They go in the deployment's environment, named per client when one
deployment serves several (`ACME_RAZORPAY_KEY_SECRET`), and are listed by
name only in `.env.example`.

## Tenancy

- **One deployment per client**: the deployment reads `CLIENT_ID` and loads
  that one file. Data is apart by construction. Simplest; recommended until
  there are many clients.
- **One deployment for all**: the client is chosen from the request's domain;
  every table has `client_id`, every query is scoped by it in one place (a
  repository layer or row-level security), and a test proves one client
  cannot read another's rows. Operators get a client switcher.

## What to write in the README

How to add a client (copy `clients/example.json`, fill it, add the secrets,
point the domain, register on the support hub), the list of settings with
their defaults, and the list of modules.
