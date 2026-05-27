#!/usr/bin/env bash
set -euo pipefail

PRESET=$1

docker run --privileged --rm tonistiigi/binfmt --install arm64 >/dev/null

docker buildx build \
  -t toasteros-builder \
  --load .

docker run --rm -it \
    --privileged \
    -v "$PWD/out:/builder/out" \
    -v "$PWD/work:/builder/work" \
    toasteros-builder \
    --preset "$PRESET"
