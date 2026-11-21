-- bhadraavel-appusage: the tables (PostgreSQL). Append to the app's own
-- migrations in its usual idempotent style.

-- Business events: one row per thing that happened to an account. Kept as
-- long as the account (they are the record of registrations and payments);
-- deleted with the account when a person asks for erasure.
CREATE TABLE IF NOT EXISTS usage_events (
  id         uuid PRIMARY KEY,
  at         timestamptz NOT NULL,
  day        date NOT NULL,              -- the app's calendar day (USAGE_TIME_ZONE)
  kind       text NOT NULL CHECK (kind IN ('registered', 'trial_started', 'first_paid', 'renewed', 'coupon_grant', 'admin_grant', 'refunded')),
  user_id    text NOT NULL,              -- the app's users.id type
  plan_id    text,
  amount     integer,                    -- smallest unit (paise)
  currency   text,
  source     text,                       -- razorpay | coupon | admin | trial
  city       text,
  region     text,                       -- state / province
  country    text                        -- ISO 3166-1 alpha-2
);
CREATE INDEX IF NOT EXISTS usage_events_day ON usage_events (day, kind);
CREATE INDEX IF NOT EXISTS usage_events_user ON usage_events (user_id);
-- A payment is one event however often the webhook and the checkout
-- callback both report it: use the payment's id as the event id, or:
-- CREATE UNIQUE INDEX usage_events_payment ON usage_events (kind, user_id, at);

-- Visits: one row per visitor per feature per day. visitor_key is
-- 'u:<user id>' signed in, 'a:<24 hex>' signed out (a daily salted hash;
-- the IP address is never stored). Pruned after USAGE_RETENTION_DAYS.
CREATE TABLE IF NOT EXISTS usage_visits (
  day          date NOT NULL,
  feature      text NOT NULL,
  visitor_key  text NOT NULL,
  user_id      text,
  city         text,
  region       text,
  country      text,
  hits         integer NOT NULL DEFAULT 1,
  first_at     timestamptz NOT NULL,
  last_at      timestamptz NOT NULL,
  PRIMARY KEY (day, feature, visitor_key)
);
CREATE INDEX IF NOT EXISTS usage_visits_user ON usage_visits (user_id) WHERE user_id IS NOT NULL;

-- The account's last known place, for the customer list (city level only).
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_city    text;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_region  text;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_country text;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_seen_at timestamptz;

-- Who looked at or exported the customer list (personal data leaving the screen).
CREATE TABLE IF NOT EXISTS usage_access_log (
  id         bigserial PRIMARY KEY,
  at         timestamptz NOT NULL DEFAULT now(),
  actor      text NOT NULL,              -- admin email, or 'api' for the admin API key
  action     text NOT NULL CHECK (action IN ('view', 'export')),
  day_from   date NOT NULL,
  day_to     date NOT NULL,
  rows       integer NOT NULL
);

-- Backfill once, when the skill is applied to an app that already has accounts
-- and subscriptions, so the first report is not empty:
-- INSERT INTO usage_events (id, at, day, kind, user_id, source)
--   SELECT gen_random_uuid(), created_at, (created_at AT TIME ZONE 'Asia/Kolkata')::date, 'registered', id, NULL FROM users
--   ON CONFLICT DO NOTHING;
-- (payments: one 'first_paid' for each account's earliest paid subscription,
--  'renewed' for every later one, with the payment's amount and currency.)
