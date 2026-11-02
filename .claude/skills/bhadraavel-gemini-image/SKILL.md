---
name: bhadraavel-gemini-image
description: Generate an image with Google's Gemini image model (Nano Banana) from Claude Code and save it into an app's web folder for use on a page. Use only when the user explicitly asks for an image to be generated, drawn or made for a page, banner, icon or illustration in one of the Bhadraavel apps.
---

# Gemini image generation for Bhadraavel apps

Claude is strong at code and reasoning but has no image generation of its
own. This skill lets Claude call Google's Gemini image model through the
Gemini API, save the result as a file, and wire it into the page. It was
requested on 1 November 2026 for building app webpages.

## When to use it

- Only when the user asks for an image: a hero picture, a banner, an
  icon, an illustration, a background, a logo draft.
- Never generate images on Claude's own initiative. Each call is paid.
- If the user asks for something Claude can draw in code (an SVG icon, a
  CSS gradient), prefer that and say so.

## What it needs

- `GEMINI_API_KEY` in the environment, from Google AI Studio. Never write
  the key into a file, a commit, or a chat message. If it is missing, tell
  the user to set it and stop.
- Python 3 with `google-genai` installed: `pip install google-genai`
  (add `--break-system-packages` if the system Python requires it).

## How to run it

The script is `scripts/gen_image.py` in this skill's folder. From the app
root (where the skill was copied to `.claude/skills/`):

```bash
python .claude/skills/bhadraavel-gemini-image/scripts/gen_image.py \
  "PROMPT" public/images/NAME.png [--model MODEL] [--aspect 16:9] [--size 2K]
```

- Output path: `public/images/` (or the app's existing static folder). Use
  a descriptive file name in lowercase with hyphens.
- File type: the script reads the MIME type Gemini returns and saves with
  the matching extension (`.png` or `.jpg`), correcting the name you gave
  if needed. Use the path it prints in the page, not the one you asked for.
- `--aspect`: set it for anything that is not square. `16:9` or `21:9` for
  a page banner, `9:16` for a phone splash, `4:3` or `3:2` for a card.
  Without it the image is 1:1.
- `--size`: `1K` (default), `2K` or `4K`; supported on the Pro model only.
- Models (stable names as of November 2026):
  - `gemini-nano-banana-2.1` (default): Google's current general image
    model, the one its docs use.
  - `gemini-3.1-flash-lite-image`: cheapest; fine for drafts and icons.
  - `gemini-3-pro-image`: highest quality, best text rendering, supports
    `--size`. Use it for a final hero image or when the user asks for
    quality.
  - Do not use `-preview` names (`gemini-3-pro-image-preview`,
    `gemini-3.1-flash-image-preview`): they were retired in June 2026.
    `gemini-2.5-flash-image` still works but is two generations old.
  - Model names change. If a call fails with a 404, check
    https://ai.google.dev/gemini-api/docs/deprecations for the current
    name, fix `DEFAULT_MODEL` in the script, and tell the user.

## Writing the prompt

Describe the subject, the style, the mood, the colours, the framing and
what must not appear (no text, no logos, no people if that is the rule).
For a page banner, pass `--aspect 16:9` (the flag, not words in the
prompt) and say in the prompt that the centre is clear for overlaid text. Ask the user what they want if the brief is vague; one
question is enough.

## Using the image

1. Generate it, then open the file (Read tool) to check it looks right.
   If it does not, regenerate with a changed prompt, once or twice, then
   ask the user.
2. Reference it from the page with a path relative to the static root,
   for example `<img src="/images/hero.png" alt="...">`. Always write a real
   `alt` text that describes the image.
3. Keep the file size reasonable: `1K` is enough for most page images, and
   a PNG banner can be large, so convert to WebP or JPEG if the app already
   has an image pipeline. Do not commit very large generated files without
   asking.

## Rules

- Each generated image is billed to the Gemini API key's account. Tell the
  user the file name and model used so they can track cost.
- Generated images are the output of a third-party model. Check that the
  picture contains no recognisable real people, public figures, trademarks
  or copied artwork before putting it on a public page.
- Do not change the script's default output folder or add other network
  calls without the user's agreement.
