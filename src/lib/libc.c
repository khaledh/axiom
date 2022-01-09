#include <stddef.h>
#include <stdint.h>

void *memcpy(void * restrict dst,  const void * restrict src,  size_t size) {
    uint64_t *d = dst;
    const uint64_t *s = src;

    for (int i = 0; i < size / sizeof(uint64_t); i++) {
        d[i] = s[i];
    }

    uint64_t rem = size & (sizeof(uint64_t) - 1);
    if (rem) {
        uint8_t *d = dst;
        const uint8_t *s = src;

        for (int i = size - rem; i < size; i++) {
            d[i] = s[i];
        }
    }

    return dst;
}
