# Proposed clarification: decimal extension initialization

Status: prepared for SQLite's forum; not submitted.

Could the decimal extension documentation link to the existing static-extension
and custom WASM initialization examples? A short example could show
`sqlite3_auto_extension((void (*)(void))sqlite3_decimal_init)` after initializing
SQLite, with `decimal.c` compiled using `SQLITE_CORE`. This would help embedders
who need exact decimal TEXT queries without including decimal in every amalgamation.

For an embedding library that already defines `SQLITE_EXTRA_INIT` (such as
SQLCipher), registering on each newly opened connection also preserves that
existing hook. For WASM, generated JavaScript and WASM artifacts must be deployed
together after a rebuild, with the SQLite and Emscripten versions pinned.

This proposal requests documentation guidance, not a change to SQLite's default
footprint. The working examples and pinned build recipe are in this repository.
