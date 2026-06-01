#!/usr/bin/env bash
set -euo pipefail

DIR="${1:-.}"

mkdir -p "$DIR/part0" "$DIR/part1" "$DIR/part2"

copy_frames() {
    PREFIX="$1"
    TARGET="$2"

    find "$DIR" -maxdepth 1 -type f -name "${PREFIX}_*.png" | sort | while read -r f; do
        new="$(basename "$f" | sed "s/^${PREFIX}_//")"
        cp "$f" "$DIR/$TARGET/$new"
    done
}

copy_frames start part0
copy_frames during part1
copy_frames stop part2

echo "Prepared:"
echo "  start  -> part0"
echo "  during -> part1"
echo "  stop   -> part2"
