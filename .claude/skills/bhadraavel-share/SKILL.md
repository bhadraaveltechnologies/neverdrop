---
name: bhadraavel-share
description: Add the standard Bhadraavel "Share" button to any of the user's apps - a screen, a day or a result turned whole into a picture (not just the part scrolled into view) with the site's address and version under it, then sent on through the phone's share sheet (WhatsApp or any app, any contact), to a typed WhatsApp number with the key facts as text, or saved. Use whenever the user asks to share a page, a screenshot, a picture of a result, "send it by WhatsApp", or a Share button on a tab.
---

# The Bhadraavel share button

Every app the user ships can send what is on a screen as a picture. This
skill holds what the user asked for, the behaviour, and the parts that took
debugging, so it can be built in any stack without asking. Reference
implementation: Panchangam (`public/share-day.js`, the share dialog in
`public/index.html`, the day share and `SHARE_TABS` in `public/app.js`, the
`.share-*` rules in `public/style.css`), release 1.2.0.

## What the user said (29 to 30 October 2026)

- "On viewing the calendar and clicking on viewing panchangam details for a
  day, user should be able to take screenshot the entire page and share by
  whatsapp to any number." The **entire** content, not the visible part, and
  WhatsApp to **any number**.
- "Can we have this share option for each of the tabs of panchangam app?"
  Every tab with something worth sending gets one.

## What the person sees

1. A **Share** button (share icon + "Share") next to the screen's main action
   (after "Show", "Compute", "Search", "Today", "Print"), or in the header of
   a detail panel. It says "Making…" and is disabled while the picture is
   drawn. Hidden in print.
2. Pressed before there is anything to show: an alert, *"There is nothing to
   share yet. Please show the results first."* Not shown on Help, Admin,
   Account or forms.
3. A **share dialog** with the picture as a preview and:
   - **Share picture** (only where the browser can share files, i.e. phones):
     the system share sheet gets the PNG, so WhatsApp or any app, and any
     contact or group, can be chosen. Note under it: *"Opens WhatsApp or any
     other app on your phone; choose any contact or group."*
   - **Send on WhatsApp to a number**: a phone field (placeholder
     `+91 98400 12345`) and a WhatsApp-green **Open WhatsApp** button. Empty
     number lets WhatsApp pick the chat.
   - **Save picture**.
   - A status line (`role="status"`).

## The facts that shape the design

- **A link cannot carry a picture to WhatsApp.** `wa.me/<number>?text=` takes
  text only. So:
  - On a phone, the picture goes through the share sheet (Web Share API with
    files); the number path sends text, and its note says to use Share
    picture to send the picture too.
  - On a computer, Open WhatsApp first **copies the picture to the
    clipboard** (`ClipboardItem` with `image/png`) and says *"paste it into
    the chat (Ctrl+V, or ⌘V on a Mac)"*; if copying is refused it downloads
    the picture and says to attach it.
- **The WhatsApp text** stands on its own: a bold title (`*…*`), the few
  facts a person would read out (for a day: the date, the place, the main
  timings), and the site's address last. For a whole tab: `*title*` plus
  "From <App>: <site URL>".
- **Every picture says where it came from**: the site's host and the app
  version (`panchangam.example.com · Panchangam v1.2.0`) under the content,
  either inside the card or as a strip added on a canvas (`withFooter`).
- **Nothing is uploaded.** The picture is made in the browser.
- **The number**: strip everything but digits and a leading `+`; `+` keeps
  the country code as typed; a leading `00` or a trunk `0` before ten digits
  is dropped; ten digits get the app's default country (`91`). Refuse fewer
  than 8 digits with *"That number looks short. Please include the country
  code, for example +91 98400 12345."*
- **File name**: `<app>-<what>-<date>-<place>.png`, lowercased and
  hyphenated, e.g. `panchangam-2026-10-29-chennai.png`.
- **Site URL** comes from the app's configured public address (`PUBLIC_URL`
  or the app's equivalent, rendered into the page, e.g. `data-site` on the
  dialog), never `location.origin` alone: behind a proxy or in the store
  build that may be wrong.

## Web (vanilla JS or any framework)

Library: **html-to-image 1.11.11** (MIT, ~19 KB), vendored as
`public/vendor/html-to-image.js` and loaded on first press, not on page
load.

```js
export async function renderPng(node) {
  const lib = await loadLib();                       // lazy <script> tag, memoised
  if (document.fonts?.ready) await document.fonts.ready;
  const opts = {
    pixelRatio: 2,
    backgroundColor: '<page background>',
    width: node.offsetWidth,
    height: node.offsetHeight,
    // REQUIRED: the off-screen card's position is copied into the clone;
    // without this the picture comes out blank.
    style: { position: 'static', left: '0', top: '0', zIndex: 'auto', margin: '0' },
    filter: (el) => !(el.nodeType === 1 &&
      (el.classList.contains('share-btn') || el.hasAttribute('data-share-skip'))),
  };
  await lib.toBlob(node, opts).catch(() => null);    // Safari paints an empty first frame
  const blob = await lib.toBlob(node, opts);
  if (!blob) throw new Error('The picture could not be made.');
  return blob;
}
```

- **The whole thing, not the viewport**: for content inside a scrolling
  panel, clone it into an off-screen card (`position: fixed; left: -10000px;
  width: 520px`), lift the clone's `max-height`/`overflow`, remove buttons
  and panel footers, add a head (title, subtitle, place) and the address
  line, draw, then remove the card in `finally`. For a tab whose content is
  already laid out in full, draw the content node itself and add the strip
  with `withFooter`.
- **Leave controls out** with `data-share-skip` on month arrows, "Change"
  links, filters and the like.
- **Ready check** before drawing: not empty, not `aria-busy="true"`, and not
  a lone `.placeholder` or `.error` child.
- **Fonts**: the Google Fonts `<link>` needs `crossorigin="anonymous"` so the
  library can embed the faces (Tamil and other scripts otherwise fall back).
  Font fetch errors in a sandbox are logged and harmless.
- **One table of tabs** rather than code per tab:
  `{ pane, after: '<selector of the main action>', node: () => <element>,
  title: () => '<what · when · where>' }`; a loop injects the button after
  each anchor and wires the same handler.
- **Dialog** is a native `<dialog>`; revoke the object URL on close; hide
  **Share picture** unless `navigator.canShare({ files: [file] })`; an
  `AbortError` from `navigator.share` means the person closed the sheet, say
  nothing.

Next.js / React: the same module as a client component (`"use client"`),
the library as a dynamic `import('html-to-image')` inside the click
handler, the dialog as a component; the site URL from the server config
passed as a prop.

## Flutter

Wrap the content in a `RepaintBoundary` (for long content, render an
off-screen copy without scroll constraints), `toImage(pixelRatio: 2)` to
PNG bytes, add the address strip with a `Canvas`, then `share_plus`
(`Share.shareXFiles`) for the share sheet, `url_launcher` for
`https://wa.me/<number>?text=`, and save via the platform's file saver. On
the web build use the web path above.

## Words

Buttons: **Share**, **Making…**, **Share picture**, **Open WhatsApp**,
**Save picture**. Statuses: *Shared.*, *Picture copied: paste it into the
chat.*, *Picture saved: attach it in the chat.*, *Picture saved.*,
*Sharing did not work here. Save the picture instead, then send it from
WhatsApp.* Apps with translations carry every one of these strings in each
of their languages, in the app's usual register.

## Checklist before pushing

- Every tab or panel with results has the button; Help, Admin and forms do
  not; it is hidden in print.
- The picture holds the whole content (check a long one: a birth chart, a
  year of festivals), with controls left out and the address and version
  under it; not blank, Tamil (or other script) drawn in its own face.
- Pressed early: "nothing to share yet".
- Phone profile (e.g. Chromium's Pixel 7): Share picture opens the sheet
  with the PNG. Desktop: Open WhatsApp copies the picture (clipboard holds
  `image/png`) and opens `wa.me/<number>?text=…` with the number normalised.
- Release log line written for users (a new feature: a minor step), README
  section on sharing.
