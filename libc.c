#include <stddef.h>

void *memcpy(void * restrict dst,  const void * restrict src,  size_t size) {
    char *d = dst;
    const char *s = src;

    for (int i = 0; i < size; i++) {
        d[i] = s[i];
    }

    return dst;
}
