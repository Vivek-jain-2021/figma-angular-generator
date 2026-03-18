#!/usr/bin/env bash
# process-assets.sh — Optimize downloaded Figma assets.
#
# Usage (called automatically after download-assets.sh, or manually):
#   bash .claude/scripts/process-assets.sh [project-root]
#
# What it does:
#   SVG icons  → strips Figma metadata, removes fixed w/h, sets viewBox (uses svgo if available)
#   PNG images → compresses losslessly (uses optipng if available, falls back to no-op)
#   Skips files that have already been processed (checks .claude/assets-processed.txt)

set -euo pipefail

PROJECT_ROOT="${1:-$(pwd)}"
IMAGES_DIR="$PROJECT_ROOT/src/assets/images"
ICONS_DIR="$PROJECT_ROOT/src/assets/icons"
PROCESSED_LOG="$PROJECT_ROOT/.claude/assets-processed.txt"

touch "$PROCESSED_LOG"

already_processed() {
  grep -qxF "$1" "$PROCESSED_LOG" 2>/dev/null
}

mark_processed() {
  echo "$1" >> "$PROCESSED_LOG"
}

svg_count=0
png_count=0
skipped=0

# ── SVG icons ────────────────────────────────────────────────────────────────
if [[ -d "$ICONS_DIR" ]]; then
  for svg in "$ICONS_DIR"/*.svg; do
    [[ -f "$svg" ]] || continue
    rel="${svg#$PROJECT_ROOT/}"

    if already_processed "$rel"; then
      ((skipped++)) || true
      continue
    fi

    if command -v svgo &>/dev/null; then
      # svgo: remove Figma metadata, keep viewBox, strip fixed dimensions
      svgo "$svg" \
        --config='{"plugins":["preset-default",{"name":"removeViewBox","active":false},{"name":"removeDimensions","active":true}]}' \
        -o "$svg" --quiet 2>/dev/null \
        && echo "  SVG   $rel (svgo)" \
        || echo "  SVG   $rel (svgo failed — kept original)"
    else
      # Fallback: basic sed to strip width/height attributes that Figma hard-codes
      if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' 's/ width="[^"]*"//g; s/ height="[^"]*"//g' "$svg"
      else
        sed -i 's/ width="[^"]*"//g; s/ height="[^"]*"//g' "$svg"
      fi
      echo "  SVG   $rel (stripped fixed dimensions)"
    fi

    mark_processed "$rel"
    ((svg_count++)) || true
  done
fi

# ── PNG images ────────────────────────────────────────────────────────────────
if [[ -d "$IMAGES_DIR" ]]; then
  for png in "$IMAGES_DIR"/*.png; do
    [[ -f "$png" ]] || continue
    rel="${png#$PROJECT_ROOT/}"

    if already_processed "$rel"; then
      ((skipped++)) || true
      continue
    fi

    if command -v optipng &>/dev/null; then
      optipng -quiet -o2 "$png" \
        && echo "  PNG   $rel (optipng)" \
        || echo "  PNG   $rel (optipng failed — kept original)"
    else
      echo "  PNG   $rel (no optimizer — install optipng for compression)"
    fi

    mark_processed "$rel"
    ((png_count++)) || true
  done
fi

echo ""
echo "Processed: ${svg_count} SVGs, ${png_count} PNGs, ${skipped} skipped."
echo ""
echo "Tip: install 'svgo' (npm i -g svgo) and 'optipng' for better optimization."
