---
name: bhadraavel-footer
description: Build or fix the standard Bhadraavel Technologies footer in any of the user's apps - the "Crafted by Bhadraavel Technologies LLP" line framed by the trishul (left) and the vel (right), a copyright with the current year, the app's version, and nothing else about the app. Use whenever the user asks for a footer, the maker's line, the trishul and vel marks, or says an app's footer is missing or wrong.
---

# The Bhadraavel footer

Every app the user ships ends every page with the same footer. This skill
holds the rules the user dictated and the markup for the two marks, so the
footer can be built in any stack without asking.

## What the user said (verbatim rules, 28 October 2026)

- "I need a footer in my apps, all my apps."
- "Make sure the footer contains 'Crafted by Bhadraavel Technologies'" (the
  user says it as "Padhavil" / "Bhadraavel" in dictation; the spelling is
  always **Bhadraavel**, double a; the line reads **Bhadraavel Technologies
  LLP**).
- "I need to have that spear and the trident on both ends of the text": the
  **vel** (Murugan's spear) and the **trishul** (Bhadrakali's trident) frame
  the maker's line.
- "**Trishul should be on the left and vel should be on the right.**" (The
  first Panchangam and Memorize It footers had them the other way round; the
  user asked for the swap. Left = trishul, right = vel, always.)
- "We should also have a copyright with the current year being displayed."
- "The vel's shaft has a small cloth dangling in the air, which looks very
  nice; the trishul should have a similar artifact." **Both marks carry a
  sash**: a cloth tied to the shaft just behind the head, draped along the
  shaft and trailing below it towards the butt. The trishul's sash is the
  vel's mirrored, so the two match.
- "Make sure that we do not have any other text or verbiage related to that
  application beyond the footer information. Anything we need to have should
  be just about that." No tagline, no description of the app, no notes about
  how it works, no credits for libraries or data sources. Only footer
  information: the maker's line, the links to the pages about the app, the
  copyright and the version.

## The footer, top to bottom

1. **Maker's line**: trishul, then "Crafted by [Bhadraavel Technologies LLP](https://www.bhadraaveltechnologies.com)." then vel. The link opens in a new tab. The marks are in the muted text colour, about 18 to 20 px tall, flex-centred on the same line with 12 px gaps, and hidden below about 420 px wide so the text never wraps around them.
2. **Links** to the pages about the app, if the app has them, in this order when present: What's new · Privacy · Terms · Refunds · Help (or Contact). Nothing else. Every link must work for a
   signed-out visitor too: Help must open a page that files a request
   without a sign-in, since a person who cannot sign in needs it most.
3. **Copyright and version**: `© <current year> · <App name> v<version>`, the version linking to the What's new or release log page when there is one. The year is computed at render time, never typed in.

Nothing more. If the app had a tagline, an ephemeris or data-source note, a
"built with" line or similar in its footer, remove it; such text belongs on
an About page if anywhere.

Rules on every page: the same footer on the app pages, the landing page and
the policy pages; centred, muted, small (13 px body, 12 px last line), a
short rule or thin top border above it, bottom padding that respects
`env(safe-area-inset-bottom)`; hidden when printing.

## The marks

Both are solid silhouettes in `currentColor`, 120 x 40 viewBox, drawn so
they lie flat. Each is drawn pointing one way; the `<g>` mirror below turns
it to point **in**, towards the text: the trishul on the left points right,
the vel on the right points left. Keep `aria-hidden`: they decorate the line.

Trishul (left of the text; drawn pointing left, mirrored to point right):

```html
<svg aria-hidden="true" viewBox="0 0 120 40" height="18" width="54" fill="currentColor"><g transform="translate(120 0) scale(-1 1)"><path d="M2 20c12-3.2 26-3.6 40-3.6v7.2c-14 0-28-0.4-40-3.6z"/><path d="M44 20c-2-10-8-16-18-17c-8-0.8-16 0.4-22 5c9-2.6 17-2.4 23-0.4c7 2.4 12 6 14 12.4z"/><path d="M44 20c-2 10-8 16-18 17c-8 0.8-16-0.4-22-5c9 2.6 17 2.4 23 0.4c7-2.4 12-6 14-12.4z"/><circle cx="46" cy="20" r="4.2"/><path d="M49 18.6h68a1.4 1.4 0 0 1 0 2.8H49z"/><path d="M52 21c5 7 11 12 22 13c7 0.6 12-2 15-6c-6 2.6-12 2-18-1.2c-6.6-3.4-11-6.4-15-10.4c-1 1.2-2.4 2.8-4 4.6z"/><path d="M100 16.5h2v7h-2zM104 16.5h2v7h-2z"/></g></svg>
```

Vel (right of the text; drawn pointing right, mirrored to point left):

```html
<svg aria-hidden="true" viewBox="0 0 120 40" height="18" width="54" fill="currentColor"><g transform="translate(120 0) scale(-1 1)"><circle cx="3.5" cy="20" r="2.6"/><path d="M5 18.6h63v2.8H5z"/><path d="M48 21c-5 7-11 12-22 13c-7 0.6-12-2-15-6c6 2.6 12 2 18-1.2c6.6-3.4 11-6.4 15-10.4c1 1.2 2.4 2.8 4 4.6z"/><path d="M66 14.5h5a1.5 1.5 0 0 1 1.5 1.5v8a1.5 1.5 0 0 1-1.5 1.5h-5a1.5 1.5 0 0 1-1.5-1.5v-8a1.5 1.5 0 0 1 1.5-1.5z"/><path d="M72.5 18c0-5 3-9 8-12c-2 4-2.5 7.5-1 11c-2.5-0.4-4.8-0.2-7 1z"/><path d="M72.5 22c0 5 3 9 8 12c-2-4-2.5-7.5-1-11c-2.5 0.4-4.8 0.2-7-1z"/><path d="M79 20c-1.5-9 5.5-16 15-16c10 0 18 8 24 16c-6 8-14 16-24 16c-9.5 0-16.5-7-15-16z"/></g></svg>
```

In a React app keep the two as components (`Trishul`, `Vel`) with
`className` and `height` props and width `height * 3`; the path data is the
same.

## Reference markup (plain HTML)

```html
<footer class="site-footer">
  <p class="footer-maker">TRISHUL_SVG<span>Crafted by <a href="https://www.bhadraaveltechnologies.com" target="_blank" rel="noopener noreferrer">Bhadraavel Technologies LLP</a>.</span>VEL_SVG</p>
  <nav class="footer-nav" aria-label="About this app"><a href="/whats-new">What’s new</a><a href="/privacy">Privacy</a><a href="/terms">Terms</a><a href="/refund">Refunds</a><a href="/help">Help</a></nav>
  <p class="footer-version">© YEAR · <a href="/whats-new">App name vX.Y.Z</a></p>
</footer>
```

```css
.site-footer { max-width: 640px; margin: 24px auto 0; padding: 22px 16px calc(28px + env(safe-area-inset-bottom)); text-align: center; color: var(--muted); font-size: 13px; line-height: 1.6; }
.site-footer::before { content: ''; display: block; width: 72px; height: 1px; margin: 0 auto 18px; background: var(--border); }
.site-footer p { margin: 0; }
.footer-maker { display: flex; align-items: center; justify-content: center; gap: 12px; color: var(--ink); }
.footer-maker svg { flex-shrink: 0; color: var(--muted); }
.footer-maker a { color: var(--accent); text-decoration: underline; text-decoration-color: var(--border); text-underline-offset: 4px; }
.footer-nav { display: flex; flex-wrap: wrap; justify-content: center; gap: 4px 20px; margin-top: 14px; }
.footer-nav a { color: var(--muted); text-decoration: none; }
.footer-version { margin-top: 14px !important; font-size: 12px; }
.footer-version a { color: inherit; text-decoration: none; }
@media (max-width: 420px) { .footer-maker svg { display: none; } }
@media print { .site-footer { display: none !important; } }
```

Use the app's own colour tokens for ink, muted, border and accent.

## How to apply it

1. Find every page template or layout that renders a footer (app shell,
   landing page, policy pages, release log page). Write the footer once
   (a server helper, a component, or a template include) and use it from
   all of them; never copy the markup into several pages.
2. Pull the version from the app's release log or package version, and the
   year from the clock.
3. Remove any app-specific sentence from the footer (see the rules above).
4. Check the order: trishul, text, vel. Check the spelling: Bhadraavel.
5. Open the page at desktop and phone widths and look at the footer; add or
   update a test that the maker's line and the version appear on every page.

Known implementations, both matching this skill as of 28 October 2026:
Panchangam (`src/site.js`, `footerHtml`) and Memorize It
(`components/footer.tsx` with `components/crest.tsx`).
