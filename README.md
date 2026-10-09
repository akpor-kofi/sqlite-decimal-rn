# SQLite decimal for React Native and PowerSync

Temporary, reproducible packaging for SQLite's public-domain `decimal.c` extension
while the changes are reviewed upstream. This repository is a holding area, not a
replacement SQLite implementation or a new PowerSync adapter.

## Native

`patches/op-sqlite-15.2.7.patch` adds the official extension source and registers it
on every SQLite/SQLCipher connection. Apply with pnpm's patchedDependencies and
set `op-sqlite.sqliteFlags` to `-DOP_SQLITE_ENABLE_DECIMAL=1` in the application's
package.json. Rebuild iOS/Android; an OTA JavaScript update cannot add native code.
The patch preserves SQLCipher's `SQLITE_EXTRA_INIT` and existing encryption setup.

Source: SQLite `version-3.50.4`, `ext/misc/decimal.c` and `src/sqlite3ext.h`.
The original public-domain notices are retained. Build glue authored here is MIT.

## Web

Install Emscripten **4.0.9** and source its `emsdk_env.sh`. On a machine with git,
make, a C compiler, Tcl, Node, curl, OpenSSL and jq, run:

```sh
./scripts/build-wasm.sh
```

The recipe pins JourneyApps/PowerSync wa-sqlite 1.7.2 at
`d33fcd38a5b5a5e5539c4a3398346d030d4d3ed0`, SQLite 3.53.0 and PowerSync core
v0.4.13. `dist/` contains the synchronous and Asyncify JavaScript/WASM pairs and
SHA256SUMS. The release assets were built on macOS ARM64 with that recipe/toolchain.
CI rebuilds on Linux; byte identity across hosts is not assumed. Release consumers
must verify the published checksums and keep each `.mjs` with its matching `.wasm`.

PowerSync's shipped browser workers already embed wa-sqlite JavaScript. Rebuild
the worker against these paired artifacts; replacing the WASM file alone can
break the generated ABI. Keep content-versioned worker and asset URLs to prevent
service workers mixing old workers and new modules. The Nukodes integration pins
PowerSync Web 1.39.1, verifies downloaded artifacts and rebuilds the stock worker
with esbuild. No adapter rewrite is required.

Native and web retain their SDK-supported SQLite versions (3.50.4 and 3.53.0).
They compile the same decimal source. Downgrading the web engine solely to match
the native version would change the supported PowerSync runtime.

## Semantics

`decimal_sum`, `decimal_cmp`, and `decimal_sub` operate on decimal TEXT. They do
not change ordinary SQL arithmetic. Normalize NULL/empty inputs to `'0'`, clamp
negative outstanding balances to zero when that is the application contract, and
normalize trailing fractional zeros for canonical output. The SQLite extension
does not expose `decimal_valid`; validate inputs at the existing application boundary.
Probe scalar, aggregate and window functions on the actual PowerSync connection
before enabling extension SQL. Retain exact fallback queries for older binaries.

## Evidence

Scratch tests were run outside the repositories and are not committed:

- 10,007 comparisons and zero-clamped subtractions matched the existing CTE path.
- 10,000-row mixed-sign/high-precision aggregates and scoped expense/invoice
  summaries matched the CTE/Decimal baseline, including empty aggregates.
- The iOS simulator executed the extension compiled with op-sqlite's SQLite 3.50.4.
- Android ARM64 NDK compilation and scalar/aggregate harness passed on an API 36
  emulator; the standalone NDK 25 harness used 16 KB linker page alignment.
- SQLCipher 3.50.4 compilation and decimal query harness passed.
- Chrome PowerSync worker: IndexedDB and OPFS, 10,000 exact rows, window sums,
  database close/reopen and offline reads passed on SQLite 3.53.0.
- WebKit IndexedDB PowerSync passed exact sums, reopen/offline reads and widget
  parity. OPFS timed out with both stock and patched workers; it is not validated.
- The pinned Linux artifact-build workflow passed.
- Full app login/live sync and physical-device acceptance remain rollout checks.

## Upstream Work

Open upstream contributions:

- [op-sqlite #468](https://github.com/OP-Engineering/op-sqlite/pull/468)
- [wa-sqlite #376](https://github.com/rhashimoto/wa-sqlite/pull/376)
- [PowerSync wa-sqlite #96](https://github.com/powersync-ja/wa-sqlite/pull/96)
- [PowerSync docs #688](https://github.com/powersync-ja/powersync-docs/pull/688)

The generic `SQLITE_WASM_EXTRA_INIT` hook makes other statically linked extensions
possible with existing `CFILES_EXTRA` and `WASQLITE_EXTRA_DEFINES` build options.
SQLite's own custom WASM-init documentation is the reference pattern. A forum
proposal is included under `docs/`; SQLite uses Fossil/forum review rather than
GitHub pull requests. No SQLite acceptance is required for this integration.
