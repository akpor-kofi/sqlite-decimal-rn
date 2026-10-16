#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="${1:-$root/build/wa-sqlite}"
if ! emcc --version | head -1 | grep -q '4.0.9'; then
  echo 'Use Emscripten 4.0.9 (emsdk install 4.0.9 && emsdk activate 4.0.9).' >&2
  exit 1
fi
if [ -e "$build_dir" ]; then
  echo "Build destination already exists: $build_dir" >&2
  exit 1
fi
git clone https://github.com/powersync-ja/wa-sqlite.git "$build_dir"
git -C "$build_dir" checkout d33fcd38a5b5a5e5539c4a3398346d030d4d3ed0
cp "$root/src/decimal.c" "$root/src/decimal-init.c" "$build_dir/src/"
cd "$build_dir"
node scripts/download-core-build.js
# Use the same explicit initialization path as the PowerSync core extension.
node --input-type=module <<'JS'
import { readFileSync, writeFileSync } from 'node:fs';
const file = 'powersync_exported_functions.json';
const functions = JSON.parse(readFileSync(file, 'utf8'));
functions.push('_decimal_init_static');
writeFileSync(file, JSON.stringify(functions, null, 2) + '\n');
JS
make dist/wa-sqlite.mjs dist/wa-sqlite-async.mjs \
  CFILES_EXTRA='decimal.c decimal-init.c' \
  WASQLITE_EXTRA_DEFINES='-DSQLITE_CORE'
mkdir -p "$root/dist"
cp dist/wa-sqlite.mjs dist/wa-sqlite.wasm dist/wa-sqlite-async.mjs dist/wa-sqlite-async.wasm "$root/dist/"
(cd "$root/dist" && shasum -a 256 *.mjs *.wasm > SHA256SUMS)
