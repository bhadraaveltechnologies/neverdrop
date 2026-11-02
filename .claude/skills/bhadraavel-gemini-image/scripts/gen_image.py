#!/usr/bin/env python3
"""Generate one image with the Gemini API and save it to a file.

Usage:
    python gen_image.py "PROMPT" OUTPUT_PATH [--model MODEL] [--aspect 16:9] [--size 2K]

Requires the GEMINI_API_KEY environment variable and the google-genai package.
The file extension is chosen from the MIME type Gemini returns (png or jpg);
if OUTPUT_PATH has a different extension it is corrected and reported.
"""
import argparse
import os
import pathlib
import sys

from google import genai
from google.genai import errors, types

# Stable models as of November 2026 (see https://ai.google.dev/gemini-api/docs/deprecations).
# Preview names such as gemini-3-pro-image-preview were retired in June 2026.
DEFAULT_MODEL = "gemini-nano-banana-2.1"   # what Google's current docs use
MODELS_NOTE = (
    "Known models: gemini-nano-banana-2.1 (default), gemini-3.1-flash-image, "
    "gemini-3.1-flash-lite-image (cheapest), gemini-3-pro-image (highest quality, supports --size)."
)

ASPECT_RATIOS = ["1:1", "2:3", "3:2", "3:4", "4:3", "4:5", "5:4", "9:16", "16:9", "21:9"]
SIZES = ["1K", "2K", "4K"]
EXT_FOR_MIME = {"image/png": ".png", "image/jpeg": ".jpg", "image/webp": ".webp"}


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate an image with Gemini.", epilog=MODELS_NOTE)
    parser.add_argument("prompt", help="Text description of the image")
    parser.add_argument("output", help="Where to save the image, e.g. public/images/hero.png")
    parser.add_argument("--model", default=DEFAULT_MODEL, help=f"Gemini model (default: {DEFAULT_MODEL})")
    parser.add_argument("--aspect", choices=ASPECT_RATIOS, help="Aspect ratio, e.g. 16:9 for a banner (default 1:1)")
    parser.add_argument("--size", choices=SIZES, help="Output size; supported on the Pro model only")
    args = parser.parse_args()

    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("GEMINI_API_KEY is not set. Ask the user to set it; never write the key to a file.", file=sys.stderr)
        return 2

    image_config = None
    if args.aspect or args.size:
        kwargs = {}
        if args.aspect:
            kwargs["aspect_ratio"] = args.aspect
        if args.size:
            kwargs["image_size"] = args.size
        image_config = types.ImageConfig(**kwargs)

    client = genai.Client(api_key=api_key)
    try:
        response = client.models.generate_content(
            model=args.model,
            contents=[args.prompt],
            config=types.GenerateContentConfig(
                response_modalities=["TEXT", "IMAGE"],
                image_config=image_config,
            ),
        )
    except errors.APIError as e:
        print(f"Gemini API error {e.code}: {e.message}", file=sys.stderr)
        if e.code == 404:
            print(f"The model name may be retired. {MODELS_NOTE}", file=sys.stderr)
        return 1

    feedback = getattr(response, "prompt_feedback", None)
    if feedback and getattr(feedback, "block_reason", None):
        print(f"Prompt was blocked: {feedback.block_reason}. Rephrase and try again.", file=sys.stderr)
        return 1

    parts = []
    if response.candidates and response.candidates[0].content:
        parts = response.candidates[0].content.parts or []

    for part in parts:
        data = getattr(part.inline_data, "data", None) if part.inline_data else None
        if not data:
            continue
        mime = part.inline_data.mime_type or "image/png"
        ext = EXT_FOR_MIME.get(mime, ".bin")
        out = pathlib.Path(args.output)
        if out.suffix.lower() != ext:
            print(f"note: Gemini returned {mime}; saving with {ext} instead of {out.suffix or '(none)'}", file=sys.stderr)
            out = out.with_suffix(ext)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_bytes(data)
        print(f"saved {out} ({mime}, model: {args.model}, aspect: {args.aspect or '1:1'})")
        return 0

    text = " ".join(p.text for p in parts if getattr(p, "text", None))
    print("no image returned." + (f" Model said: {text}" if text else ""), file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
