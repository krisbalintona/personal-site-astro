#!/usr/bin/env bash

# Reduce gif image resolution when it exceeds Sharp's pixel limit
# (used by Astro's image processing pipeline).  This script addresses
# the bug reported in https://github.com/lovell/sharp/issues/2373.
# See also https://sharp.pixelplumbing.com/api-constructor/.
#
# When an image exceeds this limit, Astro will not process the file
# with its Image and Picture components (which is used internally when
# processing Markdown images), leaving the file omitted from the
# build.
#
# Sharp's pixel limit is the product of all frames in images and gifs:
# width * height * frames <= options.limitInputPixels (default
# 268402689).
#
# Usage:
#   pixel-limit-fix.sh [--overwrite] input.gif [output.gif]
#
# If no output path is given, writes to <input>_fixed.gif.  If
# --overwrite is given, overwrites the input file in place.  If the
# GIF is already within the pixel limit, it is left untouched.
#
# Requires the following additional executable files:
#   ffprobe - Extract gif information
#   awk - To compute downscale factor
#   gifsicle - Does the gif resizing (with efficient compression)

set -euo pipefail

# If any of the dependencies aren't installed then fail early
for cmd in ffprobe awk gifsicle; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Dependency error: $cmd is not installed." >&2
        exit 1
    fi
done

# The default pixel limit.  See
# https://sharp.pixelplumbing.com/api-constructor/
SHARP_LIMIT=268402689
OVERWRITE=0

# Parse flags
while [[ "${1:-}" == --* ]]; do
    case "$1" in
        --overwrite) OVERWRITE=1; shift ;;
        *) echo "Unknown flag: $1" >&2; exit 1 ;;
    esac
done

if [ $# -lt 1 ]; then
    echo "Usage: $0 [--overwrite] input.gif [output.gif]" >&2
    exit 1
fi

INPUT="$1"

if [ "$OVERWRITE" -eq 1 ]; then
    OUTPUT="$INPUT"
else
    OUTPUT="${2:-${INPUT%.*}_fixed.gif}"
fi

if [ ! -f "$INPUT" ]; then
    echo "Error: file not found: $INPUT" >&2
    exit 1
fi

WIDTH=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$INPUT")
HEIGHT=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$INPUT")
FRAMES=$(ffprobe -v error -select_streams v:0 -count_packets -show_entries stream=nb_read_packets -of csv=p=0 "$INPUT")
TOTAL=$((WIDTH * HEIGHT * FRAMES))

if [ "$TOTAL" -le "$SHARP_LIMIT" ]; then
    echo "✓ $INPUT is within limit ($TOTAL px total), no action needed."
    exit 0
fi

SCALE=$(awk "BEGIN { printf \"%.6f\", sqrt($SHARP_LIMIT / $TOTAL) }")
echo "⚠ $INPUT exceeds limit ($TOTAL px total), scaling by $SCALE..."

gifsicle --scale "$SCALE" "$INPUT" -o "$OUTPUT"

echo "✓ Written to $OUTPUT"
