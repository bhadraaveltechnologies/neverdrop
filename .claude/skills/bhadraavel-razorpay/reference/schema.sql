-- Billing tables for a Bhadraavel app (PostgreSQL). Port the names and the
-- constraints to the app's ORM (Drizzle, Prisma) or database as they are: the
-- constraints are what keep money counted once. `users(id)` is the app's own
-- account table; change the reference if it is called something else.
-- Amounts are integers in the smallest unit (paise / cents). Plan prices are
-- before GST; GST_PERCENT is added at checkout (0 = prices are final).

-- The plans on sale. Admin-managed (seeded once, then changed from the admin
-- screen or API); a plan is retired with active = false, never deleted, so
-- old payments still name it.
CREATE TABLE billing_plans (
  id          text PRIMARY KEY,                -- 'monthly', 'quarterly', 'yearly', 'family-yearly'
  name        text NOT NULL,                   -- 'Monthly'
  description text,                            -- one line under the price
  days        integer NOT NULL CHECK (days > 0),
  amount      integer NOT NULL CHECK (amount >= 100), -- before GST
  currency    text NOT NULL DEFAULT 'INR',
  active      boolean NOT NULL DEFAULT true,
  sort        integer NOT NULL DEFAULT 0
);

-- A period of access. The ONLY thing that opens the app when billing is on:
-- no row covering today = no access. source: razorpay (paid), coupon (a 100%
-- coupon), admin (granted by hand), trial (the free trial, once per account).
CREATE TABLE subscriptions (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan_id     text NOT NULL,                   -- a billing_plans id, or 'trial' / 'admin'
  days        integer NOT NULL CHECK (days > 0),
  starts_at   timestamptz NOT NULL,
  ends_at     timestamptz NOT NULL,
  source      text NOT NULL CHECK (source IN ('razorpay', 'coupon', 'admin', 'trial')),
  amount      integer NOT NULL DEFAULT 0,
  currency    text NOT NULL DEFAULT 'INR',
  payment_ref text,                            -- Razorpay payment id
  coupon_code text,
  note        text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  CHECK (ends_at > starts_at)
);
CREATE INDEX subscriptions_user_idx ON subscriptions (user_id, ends_at DESC);
-- One free trial per account, however many times the gate asks.
CREATE UNIQUE INDEX subscriptions_one_trial ON subscriptions (user_id) WHERE source = 'trial';

-- One Razorpay order (or a free_<uuid> row when a coupon covered the price).
-- status: created → paid (once) | failed (a failed attempt; a later success
-- on the same order still turns it paid) ; paid → refunded.
CREATE TABLE payments (
  id              uuid PRIMARY KEY,
  user_id         text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan_id         text NOT NULL,
  order_id        text NOT NULL UNIQUE,
  payment_id      text,
  list_amount     integer NOT NULL,
  discount        integer NOT NULL DEFAULT 0,
  tax             integer NOT NULL DEFAULT 0,  -- GST on (list_amount - discount)
  amount          integer NOT NULL,            -- what was charged: list - discount + tax
  currency        text NOT NULL DEFAULT 'INR',
  coupon_code     text,
  status          text NOT NULL DEFAULT 'created' CHECK (status IN ('created', 'paid', 'failed', 'refunded')),
  method          text,                        -- upi, card, netbanking, wallet, coupon
  error           text,
  subscription_id uuid REFERENCES subscriptions(id) ON DELETE SET NULL,
  created_at      timestamptz NOT NULL DEFAULT now(),
  paid_at         timestamptz
);
CREATE INDEX payments_user_idx ON payments (user_id, created_at DESC);

-- Coupons, made by an admin. kind percent: value 1–100. kind amount: value in
-- the smallest unit of `currency` (₹100 off = 10000 with currency 'INR').
CREATE TABLE coupons (
  code                text PRIMARY KEY CHECK (code = upper(code)),
  kind                text NOT NULL CHECK (kind IN ('percent', 'amount')),
  value               integer NOT NULL CHECK (value > 0),
  currency            text,
  plan_ids            text[],                  -- NULL = every plan
  max_redemptions     integer,                 -- NULL = unlimited
  per_user_limit      integer NOT NULL DEFAULT 1,
  valid_from          timestamptz,
  valid_until         timestamptz,
  email               text,                    -- NULL = anyone; else only this account (lower-case)
  first_purchase_only boolean NOT NULL DEFAULT false,
  active              boolean NOT NULL DEFAULT true,
  note                text,                    -- why it exists ("Diwali 2026", "apology for outage")
  created_at          timestamptz NOT NULL DEFAULT now(),
  CHECK (kind <> 'percent' OR value <= 100),
  CHECK (kind <> 'amount' OR currency IS NOT NULL)
);

-- A coupon used, written when the money moved (or the free plan started).
CREATE TABLE coupon_redemptions (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coupon_code text NOT NULL REFERENCES coupons(code),
  user_id     text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  payment_id  uuid NOT NULL UNIQUE REFERENCES payments(id),
  discount    integer NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX coupon_redemptions_code_idx ON coupon_redemptions (coupon_code, user_id);

-- Every admin action on billing (plans, coupons, grants, ended periods,
-- refunds): who, what, when. Written by the admin API and the admin screen.
CREATE TABLE billing_admin_log (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor      text NOT NULL,                    -- the admin's email, or 'admin-api'
  action     text NOT NULL,                    -- plan | coupon-create | coupon-change | grant | end-period | refund
  detail     jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Seed: the plans to start with, before GST (ask the user for theirs).
INSERT INTO billing_plans (id, name, description, days, amount, currency, sort) VALUES
  ('monthly',   'Monthly',   'Pay as you go.',                 30,  9900, 'INR', 1),
  ('quarterly', 'Quarterly', 'Three months, a little less.',   90, 24900, 'INR', 2),
  ('yearly',    'Yearly',    'A whole year, the best value.', 365, 79900, 'INR', 3)
ON CONFLICT (id) DO NOTHING;
