#include <sqlite3.h>
int sqlite3_decimal_init(sqlite3 *, char **, const sqlite3_api_routines *);
int sqlite3_decimal_auto_init(void) {
  return sqlite3_auto_extension((void (*)(void))sqlite3_decimal_init);
}
