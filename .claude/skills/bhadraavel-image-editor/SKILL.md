---
name: bhadraavel-image-editor
description: Add the standard Bhadraavel image editor to any of the user's apps - upload an image and edit it in the browser (zoom with a slider, wheel or pinch; drag to pan; rotate; fit or fill; crop to a square or a circle; background transparent, white or the app's colour; live preview at the sizes the app uses), then upload only the cropped, resized result, checked again on the server and stored so backups carry it. Used for the clinic or app logo and for people's photos (doctors, physios, staff). Only the Bhadraavel support team (the app's operator role) may upload or change these images. Use whenever the user asks for a logo upload, a profile or staff photo, an avatar, an image crop/zoom/pan/resize tool, or says the app's logo or someone's picture should be changeable in the app.
---

# Bhadraavel image editor

One editor for every picture an app shows as a brand mark or a face: the
app's (or client's) **logo**, square, and **people's photos** (doctors,
physios, staff), round. The browser does the editing and sends only the
finished 512 px square; the server re-checks the bytes and stores it.

| File | What it is |
|---|---|
| `reference/ImageEditor.tsx.txt` | The React client component (copy as `components/ImageEditor.tsx`). Proven in myclinicapp. |
| `reference/image-check.ts.txt` | The server check: reads PNG/WebP type and size from the file's own header and says why an image can't be stored. Pure, no framework. |
| `reference/image-check.test.ts.txt` | Its tests (real PNG bytes, WebP headers); the SkillFactory CI runs them. |

## 1. What the user asked for (5 November 2026)

- "Can we allow Bhadraavel support to configure the logo for the app using
  upload functionality for image, allow **edit/resize/zoom/pan/crop** an image."
- "Additionally let have the **doctor and physio picture uploads** handled by
  the support team in the app."
- "When I meant support can upload, **only Bhadraavel support team** can do
  this."
- "Have this image editor as a skill … and push this skill to all repos."

## 2. Decisions (do not reopen without the user)

1. **Only Bhadraavel support uploads.** In each app that is the operator role
   (myclinicapp: phones in `OPERATOR_PHONES`; others: their `OPERATOR_EMAILS`
   or equivalent). The client's own admin, staff and users never get the
   editor, and the server refuses them (403) even if they call the endpoint.
   The client admin may *see* the image, with a line saying it is set by
   Bhadraavel support and to send changes through Help (`bhadraavel-support`).
   The client must never be able to make itself an operator.
2. **Edit in the browser, upload only the result.** The original photo never
   leaves the device. Output: a square of **512 px**, PNG; WebP (quality 0.9)
   only when the PNG is over 600 KB (photos).
3. **The server trusts nothing it is told.** It reads the type and size from
   the bytes (`sniffImage`), and accepts only PNG or WebP, square, 128–1024
   px, under 600 KB (`imageProblem`). It never stores SVG (scripts) or the
   declared content type.
4. **Store in the database**, one row per image (`brand_assets`: key, mime,
   data, width, height, updated_by, updated_at). Keys: `logo`,
   `staff:<id>` (or `user:<id>`). The nightly database backup then carries the
   images; no separate file volume to forget.
5. **Serve with a version**: `/brand/logo?v=<updated_at epoch>`; versioned
   responses are `public, max-age=31536000, immutable`, so a change shows
   at once and an unchanged image is never fetched twice. Unversioned: 5 minutes.
   Brand images are public (they appear on public pages); never put a private
   picture (a patient's X-ray, an ID card) through this.
6. **Fallback is initials**, in the same badge (square for the logo, circle
   for a person), so nothing looks broken before an image exists. "Remove"
   brings the initials back.
7. **Every change is audited**: who, what (changed / removed), which image.
8. **People's photos are shown to the public** (e.g. when choosing whom to
   book with): get the person's agreement before uploading. Say so to the
   user when adding this.

## 3. The editor (behaviour to keep, in any stack)

Props in the React version: `current` (saved image URL or null), `brand`
(app colour), `fallback` (initials), `endpoint` (POST saves, DELETE removes),
`noun` ("logo" | "photo"), `shape` ("square" | "round"), `where` (for the
saved message), `previews` (two labels).

- **Load**: a file input (`accept="image/png,image/jpeg,image/webp,image/svg+xml"`)
  inside a dashed drop zone that also takes a dropped file. Refuse non-images
  and files over 20 MB. If the browser cannot decode it (iPhone **HEIC**
  usually), say so and ask for PNG/JPG. Warn (do not block) under 128 px.
- **Crop area**: a 320 px square `<canvas>` (scaled by `devicePixelRatio`,
  capped at 3), circular for `round`, `touch-action: none`, focusable, with an
  `aria-label` that says how to use it. A checkerboard shows transparency.
- **Geometry** (the part to copy exactly): `fit = BOX / max(w, h)` of the
  image as rotated (swap w and h on odd quarter turns); `zoom` multiplies
  it (1 = whole image visible, "Fit"); "Fill" sets
  `zoom = max(w, h) / min(w, h)` and centres. Draw with
  `translate(px/2 + pan.x·k, px/2 + pan.y·k) → rotate(quarter·π/2) → scale(fit·zoom·k) → drawImage(img, −w/2, −h/2)`
  where `k = px / BOX`, so the same function draws the on-screen box, the
  previews and the 512 px output identically.
- **Pan**: pointer events with `setPointerCapture`; one pointer drags.
  **Pinch**: with two pointers, zoom = start zoom × current distance ÷ start
  distance. **Wheel**: `zoom *= exp(−deltaY × 0.0015)`, on a listener added
  with `{ passive: false }` so the page does not scroll. Clamp zoom to 0.2–8.
- **Rotate** in quarter turns, rotating the pan vector with the image
  (clockwise: `(x, y) → (−y, x)`).
- **Keyboard**: arrows pan (Shift = bigger steps), `+`/`=` and `−` zoom.
- **Background**: transparent (logo default), white (photo default) or the
  app colour, baked into the output.
- **Preview**: the result at the real sizes the app uses (e.g. 34 px header,
  56 px on the app's coloured header), in the real shape.
- **Save** → render to a 512 px canvas → `toBlob('image/png')` → WebP if
  too large → `POST endpoint` with the blob as the body → show "Saved. The
  {noun} now shows {where}." and reload.
- **Remove** asks first, then `DELETE endpoint`.

## 4. Server side

```ts
// POST /api/brand/logo   (and /api/brand/staff/:id)  — operators only
const me = await currentUser();
if (!me || !hasRole(me, "operator")) return fail("Only Bhadraavel support can change this.", 403);
if (Number(req.headers.get("content-length") ?? 0) > IMAGE_MAX_BYTES * 2) return fail("Too large.", 413);
const buf = new Uint8Array(await req.arrayBuffer());
const problem = imageProblem(buf);            // reference/image-check
if (problem) return fail(problem);
const { mime, width, height } = sniffImage(buf)!;
// UPSERT INTO brand_assets (key, mime, data, width, height, updated_by, updated_at) …
await audit(me, "changed the logo");          // or "changed a staff photo", with the name
```

For a person's photo also check the target exists and has a role that shows a
photo (myclinicapp: doctor or physio; 400 otherwise).

```sql
CREATE TABLE IF NOT EXISTS brand_assets (
  key text PRIMARY KEY, mime text NOT NULL, data bytea NOT NULL,
  width int NOT NULL, height int NOT NULL, updated_by text,
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

`GET /brand/logo` (public) returns the bytes with the stored `mime`,
`x-content-type-options: nosniff` and the cache header from decision 5; 404
with `no-store` when there is none. A `logoSrc()` helper returns the
versioned URL or null (null too when the table does not exist yet), and a
`Logo` / `Avatar` component renders the image or the initials.

## 5. Where the images go

- **Logo**: everywhere the app showed its initials or name badge: the app
  header, landing page, sign-in, help, public pages (booking), patient or
  customer links, any TV/kiosk screen, and printed documents' header.
- **People's photos**: wherever a customer chooses or meets that person
  (booking choices, appointment links), staff lists, and the person's own
  header.
- Not in the footer (`bhadraavel-footer` stays as it is).

## 6. Pitfalls found while building it

- Next.js standalone behind Traefik: do not build redirects from `req.url`
  (it is the container's `0.0.0.0` address). The editor uses `fetch` and
  `location.reload()`, so it is not affected; keep it that way.
- Store the badge size on the element (width, height, flex-basis) and give
  the image `object-fit: contain`; a logo with a transparent background on a
  coloured header needs its own background (the white/brand option).
- `naturalWidth` is 0 for an SVG without width/height: tell the person to
  export it as PNG.
- Run the app's own checks after wiring it (`tsc`, build), and a browser
  check: as an operator load a wide image and a tall one, fill, drag, zoom,
  rotate, save; the served image is 512×512; it shows in every place in
  section 5; a non-operator gets 403.

## 7. Done when

- Only operators see the editor and the endpoint refuses everyone else.
- Logo (square) and, where the app has people the public sees, photos
  (round) can be set, changed and removed; initials show otherwise.
- The server check from `reference/image-check` is in place and tested.
- Images are in the database, versioned when served, and audited.
- The README says who can change them and where they appear.
