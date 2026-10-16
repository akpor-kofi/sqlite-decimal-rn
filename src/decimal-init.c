#include <sqlite3.h>
int sqlite3_decimal_init(sqlite3 *, char **, const sqlite3_api_routines *);
int decimal_init_static(void) {
  return sqlite3_auto_extension((void (*)(void))sqlite3_decimal_init);
}
