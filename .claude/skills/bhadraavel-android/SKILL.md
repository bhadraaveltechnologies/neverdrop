---
name: bhadraavel-android
description: Put any Bhadraavel web app on the Google Play Store as an Android app without a second codebase - a Trusted Web Activity (TWA) that opens the live site full-screen - covering what the site needs first (web manifest, icons, privacy and account-deletion pages), the store-build switch that hides every price and pay button inside the Play app, the Digital Asset Links file that removes the address bar, building the signed app with PWABuilder (nothing to install) or Bubblewrap, the upload and Play App Signing keys and their fingerprints, the Play Console listing, reviewer access, data-safety form and testing tracks, and releasing updates. Use whenever the user asks for an Android app, a Play Store listing, a TWA, "put the app on Play Store", assetlinks, or why the Android app shows an address bar.
---

# Android app on the Play Store (Trusted Web Activity)

A **Trusted Web Activity** is a small, signed Android app that opens the live
website full-screen, with no browser bar, inside Chrome. Android trusts it to
hide the browser bar because the website publicly lists the app's signing
certificate. There is **no second codebase**: every change deployed to the
site is in the Android app the moment it goes live, with no store release.

Use it to give an app a Play Store listing (discovery, reviews, an icon that
updates itself). It stays a web app: no offline use beyond what the site's
service worker gives, no native-only APIs. If the user needs those, that is a
native build — a separate, much larger decision; say so and stop here.

Reference app: **Panchapatchi Sastra** (`bhadraaveltechnologies/panchapatchi-sastra`,
Flutter web): `twa/twa-manifest.json`, `twa/.gitignore`,
`frontend/web/.well-known/assetlinks.json`, the `/.well-known/assetlinks.json`
block in `frontend/nginx.conf`, the explicit `COPY web/.well-known` in
`frontend/Dockerfile`, `frontend/lib/services/store_build*.dart`,
`frontend/lib/widgets/store_subscription_notice.dart`, and the guide
`docs/guides/TWA_PLAY_STORE_SETUP.md`.

## 1. Ask once, before building

Use `AskUserQuestion`; these cannot be changed after the first upload, or
decide what the app must hide.

1. **Package id**, permanent once uploaded. Convention: `com.<app-id>.twa`
   (Panchapatchi: `com.panchapatchi.twa`). Never reuse the id of a native app
   the same product has or may have.
2. **App name and launcher name** (the launcher name is the short one under
   the icon; it may be in the app's main language).
3. **Which host**: production only (e.g. `patchi.panchapatchi.co.in`). A dev
   host never goes in a store app.
4. **Play developer account**: for Bhadraavel Technologies LLP an
   *organization* account (needs the LLP's D-U-N-S number). At the time of
   writing Google makes new *personal* accounts run a closed test with a
   minimum number of testers for some days before a first production
   release; organization accounts are not held to that. Check the Play
   Console's current rules when signing up.
5. **Is the app paid?** Then section 3 is required before any upload.
6. **Does the site send web push notifications?** Then notification
   delegation is switched on (section 5).

## 2. What the site needs first

Check each in the repository and fix what is missing before building.

- **Web manifest** (`manifest.json` / `site.webmanifest`) linked from every
  page: `name`, `short_name`, `id`, `start_url`, `scope: "/"`,
  `display: "standalone"`, `theme_color`, `background_color`, and icons
  `192x192` and `512x512` with `purpose: "any"` **plus** a `512x512`
  `purpose: "maskable"` (Android crops it to a circle or squircle; keep the
  artwork inside the middle 80%).
- **A registered service worker** and HTTPS on the production host. PWABuilder
  scores installability and flags a missing service worker.
- **Privacy Policy page**, reachable signed out, at a stable URL: the Play
  listing must link to it (the `bhadraavel-footer` skill puts it in the
  footer; the `bhadraavel-razorpay` skill has the wording).
- **Account deletion.** If the app lets people create an account, Google
  requires a way to ask for the account and its data to be deleted, **inside
  the app and on the web**, and the web link goes in the Data safety form.
  A "Delete my account" request through the help form (the
  `bhadraavel-support` skill, a *Delete my account* category) or an Account
  page button is enough, as long as it is reachable signed out from a public
  URL too. Confirm with the user what is deleted and what is kept for
  accounting (payment records), and say so on that page.
- **Sign-in works inside the wrapper.** Google sign-in and email codes run in
  Chrome as on the web; check that no sign-in or payment redirect points at a
  different host than the TWA's (it would open a separate browser tab).

## 3. The store-build switch (paid apps)

Google requires its own billing (Play Billing) for digital subscriptions sold
inside a Play app. Bhadraavel apps sell through Razorpay on the website, so
**the Play app sells nothing**: every price, plan, coupon field and pay button
is hidden when the site runs inside the wrapper. A plan bought on the website
works in the app at once (the account is the same).

Detect the wrapper once and remember it for the session:

```js
// store-build.js — true inside the Play Store wrapper.
// Signal: the wrapper opens the site at /?src=play (section 5: Start URL);
// Chrome also sends an android-app:// referrer for a TWA launch. Kept in
// sessionStorage, which is scoped to the wrapper's own web view, so it never
// leaks into the person's ordinary browser tabs.
export function isStoreBuild() {
  try {
    if (sessionStorage.getItem('store_build') === 'play') return true;
    const src = new URLSearchParams(location.search).get('src');
    if (src === 'play' || document.referrer.startsWith('android-app://')) {
      sessionStorage.setItem('store_build', 'play');
      return true;
    }
  } catch { /* storage blocked: treat as the web */ }
  return false;
}
```

Rules:

- Hide prices, plans, coupons, checkout and "renew" buttons; the
  subscription wall **still applies** (a person without a plan cannot use the
  paid parts).
- In their place one plain notice, no link that opens checkout. The
  `bhadraavel-razorpay` skill's `reference/copy.md` (*Android store build*)
  has the wording. Google's rules on mentioning other ways to pay change and
  differ by country: if a reviewer objects to naming the website, shorten the
  notice to *Plans are not available in the Android app* and nothing more.
- The server does not need to know: it is a display rule. Do not try to block
  payments by user agent.
- Test it by opening `https://<host>/?src=play` in a normal browser: plans
  must disappear for that tab only, and reappear in a new tab.

## 4. Digital Asset Links: the file that removes the address bar

Serve this at `https://<host>/.well-known/assetlinks.json`:

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.<app-id>.twa",
      "sha256_cert_fingerprints": [
        "PLAY_APP_SIGNING_KEY_SHA256",
        "UPLOAD_KEY_SHA256"
      ]
    }
  }
]
```

- **Both fingerprints.** Google re-signs the app people download (*Play App
  Signing*), so its certificate must be listed for store installs; the upload
  key's makes test APKs you install yourself work. Fingerprints are public
  (they identify a key; they cannot sign) and are safe to paste in chat.
- It must answer **200, `application/json`, no redirect, no sign-in, no
  single-page-app fallback** (a 200 with `index.html` breaks it silently),
  `Cache-Control: no-cache` so a key change propagates.
- Per stack:
  - **Next.js**: `public/.well-known/assetlinks.json`; check that no
    middleware redirects or guards `/.well-known/`.
  - **Express**: `express.static` ignores dot-directories by default — serve
    it with an explicit route, or `express.static(dir, { dotfiles: 'allow' })`
    for that folder only.
  - **Flutter web**: `flutter build web` is not guaranteed to copy hidden
    directories from `web/`: copy it explicitly into the image
    (`COPY web/.well-known /usr/share/nginx/html/.well-known`).
  - **nginx**: an exact-match block before the SPA fallback:
    ```nginx
    location = /.well-known/assetlinks.json {
      default_type application/json;
      add_header Cache-Control "no-cache, must-revalidate";
    }
    ```
- Verify after each deploy:
  `curl -sI https://<host>/.well-known/assetlinks.json` (200, JSON, no
  `Location`), then Google's *Statement List Generator and Tester*
  (developers.google.com/digital-asset-links/tools/generator) with the host,
  package id and fingerprint.

## 5. The wrapper's settings, kept in the repository

`twa/twa-manifest.json` is the source of truth for the wrapper (Bubblewrap
reads it; PWABuilder's form is filled from it). Everything else in `twa/` is
generated or secret:

```gitignore
# twa/.gitignore — only twa-manifest.json is source; the rest is generated
# or a secret (the keystore).
*
!.gitignore
!twa-manifest.json
```

Key fields (Panchapatchi's file is a complete example):

| Field | Value |
|---|---|
| `packageId` | `com.<app-id>.twa` (section 1) |
| `host` | the production host, no scheme |
| `name` / `launcherName` | section 1 |
| `startUrl` | **`/?src=play`** — what turns the store build on (section 3) |
| `display` | `standalone` |
| `themeColor`, `backgroundColor`, `navigationColor` | the app's brand colour |
| `iconUrl` / `maskableIconUrl` | the 512 px icons from the web manifest, full URLs |
| `webManifestUrl`, `fullScopeUrl` | `https://<host>/manifest.json`, `https://<host>/` |
| `enableNotifications` | `true` when the site sends web push (notifications then appear under the app and ask Android's permission) |
| `fallbackType` | `customtabs` |
| `appVersionName` / `appVersionCode` | `1.0.0` / `1`; raise both for every upload (section 8) |
| `signingKey` | `{ "path": "./android.keystore", "alias": "android" }` (Bubblewrap only) |

## 6. Build the signed app

**PWABuilder, nothing to install (recommended for the owner).** At
pwabuilder.com enter `https://<host>` → **Package for stores → Android →
Generate package → All settings**, and copy the values from the table in
section 5 (Package ID, App name, Launcher name, version and version code,
Host, **Start URL `/?src=play`**, colours, Display standalone, Notification
delegation). Signing key: **Create new** the first time, **Use mine** with the
saved keystore ever after. The download contains:

- `app-release-bundle.aab` — what is uploaded to the Play Console;
- `app-release-signed.apk` — install on a phone to test first;
- `signing.keystore` and `signing-key-info.txt` — **the upload key and its
  passwords**;
- `assetlinks.json` — its fingerprint is the upload key's (section 4).

**Bubblewrap, from the repository (for a developer):**

```bash
npm install -g @bubblewrap/cli          # Node 18+; offers to fetch a JDK and Android SDK
cd twa
bubblewrap update                       # regenerate the project from twa-manifest.json
bubblewrap build                        # app-release-bundle.aab + app-release-signed.apk
keytool -list -v -keystore android.keystore -alias android | grep SHA256
```

**The upload key.** Back up the keystore and its passwords in two places
(a password manager plus one offline copy). Never commit it, never paste it in
chat, never put it in a pull request. Every future upload must be signed with
it; if it is lost, Google can reset the upload key on request (Play App
Signing keeps the app itself safe), but it takes days. In CI, it would live
only as an encrypted secret.

## 7. Play Console

1. **Create the app**: name, default language, *App*, *Free* (the app is free
   to install; subscriptions are on the website), the declarations.
2. **App access**: the app needs a sign-in, so give the reviewers a test
   account **with an active plan** (grant one from the app's admin screen)
   and the steps to sign in. Without it the review is refused.
3. **Ads**: say whether the app shows ads (Bhadraavel apps normally do not).
4. **Content rating**: fill the questionnaire honestly.
5. **Target audience**: adults (18+) unless the app is meant for children,
   which brings extra rules.
6. **Data safety**: list what the app collects and why, from the Privacy
   Policy: name, email, phone, account data, purchase history (paid apps),
   app activity if usage is tracked (the `bhadraavel-appusage` skill), crash
   logs if errors are reported (the `bhadraavel-error-reporting` skill).
   Encrypted in transit: yes. Deletion: yes, with the web link (section 2).
7. **Privacy policy URL**: the public page (section 2).
8. **Store listing**: short description (up to 80 characters), full
   description (up to 4,000; no prices), app icon 512 × 512 PNG, feature
   graphic 1024 × 500, at least two phone screenshots, category, contact
   email. Screenshots of the real app; the `bhadraavel-testenablement`
   skill's screenshots or a phone capture of the TWA both do.
9. **Release**: upload the `.aab` to **Internal testing** first, add the
   testers' emails, install from the opt-in link on a real phone. Then
   (closed testing if the account requires it) **Production**.
10. **Play App Signing fingerprint**: Setup → App signing → *App signing key
    certificate* → SHA-256. Add it to `assetlinks.json` (section 4) and
    deploy **before** the production rollout.

## 8. Releasing updates

- **Website changes** reach the Android app as soon as they are deployed:
  no store release, no version change.
- **Wrapper changes** (icon, name, colours, start URL, notification setting,
  a Bubblewrap or Android target upgrade Google asks for): raise
  `appVersionCode` by one and `appVersionName`, rebuild with the **same
  package id and the same upload key**, upload, roll out. Keep
  `twa/twa-manifest.json` in step and commit it.
- Google raises the required Android target level about once a year; the
  Play Console warns months ahead. A rebuild with the current Bubblewrap or
  PWABuilder is the whole fix.

## 9. When something is wrong

| Symptom | Cause and fix |
|---|---|
| An address bar shows at the top | `assetlinks.json` not served exactly as section 4 says, or the fingerprint does not match the key that signed the installed copy (store installs need the Play App Signing one). Re-run the curl and the Google tester; clear the app's data and reopen. |
| Prices or a pay button show in the Play app | Start URL is not `/?src=play`, or the page reads the flag somewhere the switch was not applied. Rebuild with the right Start URL; check every price surface. |
| "App not installed" when side-loading the APK | A copy signed with another key is installed: uninstall it first. |
| No notifications | Notification delegation off, or Android 13+ permission not granted; the site's own web push must work in Chrome first. |
| Sign-in opens a separate browser tab | A redirect goes to another host than the TWA's; keep sign-in and its callbacks on the same host. |
| Review refused: cannot sign in | App access (section 7.2): a working test account with an active plan. |
| Review refused: payments | Section 3: hide more; shorten the notice. |
| Review refused: account deletion | Section 2: the in-app and web deletion request. |

## 10. Checklist

- [ ] Section 1 answered; package id written into `twa/twa-manifest.json`.
- [ ] Web manifest with 192/512 icons and a 512 maskable icon; service worker; HTTPS.
- [ ] Privacy Policy and account-deletion request reachable signed out.
- [ ] Paid app: store build hides every price and pay button at `/?src=play`; the wall still applies.
- [ ] `/.well-known/assetlinks.json` answers 200 JSON with no redirect and no SPA fallback.
- [ ] `twa/twa-manifest.json` and `twa/.gitignore` committed; keystore not.
- [ ] Signed `.aab` built; upload key and passwords backed up in two places.
- [ ] Play Console: app access test account, data safety, content rating, target audience, listing, privacy URL.
- [ ] Both fingerprints in `assetlinks.json`, deployed, verified with curl and Google's tester.
- [ ] Internal test on a real phone: no address bar, sign-in works, no prices in a paid app, notifications if used.
- [ ] README: a short *Android app* section (package id, where the guide is, that the keystore is kept outside the repository).
