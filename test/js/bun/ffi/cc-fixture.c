// Ensure we can include builtin headers.
#include <stdalign.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdnoreturn.h>
#if __has_include(<stdio.h>)
#include <stdio.h>
#endif

#include <stdint.h>
#include <string.h>

#if __has_include(<node/node_api.h>)

#include <node/node_api.h>

napi_value napi_main(napi_env env) {
  napi_value result;
  napi_create_string_utf8(env, "Hello, Napi!", NAPI_AUTO_LENGTH, &result);
  return result;
}

#endif

uint8_t lastByte(uint8_t *arr, size_t len) { return arr[len - 1]; }

int main() {

#if __has_include(<stdio.h>)
  // Check fprint stdout and stderr.
  fprintf(stdout, "Hello, World!\n");
  fprintf(stderr, "Hello, World!\n");

  // Verify printf doesn't crash.
  printf("Hello, World!\n");
  printf("Hi!, 123 == %d\n", 123);
#endif

  // Verify stdbool.h works.
  bool g = true;
  bool h = false;
#if __has_include(<stdio.h>)
  printf("bool true = %d, bool false = %d\n", (int)g, (int)h);
#endif

#ifdef HAS_MY_DEFINE
#if (__has_include(<stdio.h>))
  printf("HAS_MY_DEFINE is defined as %s\n", HAS_MY_DEFINE);
#endif
#endif

  return 42;
}

bool memset_and_memcpy_work(void) {
  char dst[10] = {0};
  char src[10] = {0};

  if (memset(src, 5, 9) != src) {
    return false;
  }
  for (int i = 0; i < 9; i++) {
    if (src[i] != 5) {
      return false;
    }
  }
  if (src[9] != 0) {
    return false;
  }

  for (int i = 0; i < 10; i++) {
    src[i] = i + 1;
  }

  if (memcpy(dst, src, 9) != dst) {
    return false;
  }
  for (int i = 0; i < 9; i++) {
    if (dst[i] != src[i]) {
      return false;
    }
  }
  if (dst[9] != 0) {
    return false;
  }

  return true;
}
