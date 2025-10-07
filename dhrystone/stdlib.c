/* stdlib.c - Minimal C library implementation for RISC-V Dhrystone */

#include <stddef.h>

// Memory allocation - Simple bump allocator
static char heap[16384];
static char *heap_ptr = heap;

void *malloc(size_t size) {
    // Align to 4 bytes
    size = (size + 3) & ~3;
    
    char *ptr = heap_ptr;
    heap_ptr += size;
    
    // Check for overflow
    if (heap_ptr > heap + sizeof(heap)) {
        return NULL;
    }
    
    return ptr;
}

void free(void *ptr) {
    // Simple allocator doesn't support free
}

// String functions
char *strcpy(char *dest, const char *src) {
    char *ret = dest;
    while ((*dest++ = *src++));
    return ret;
}

int strcmp(const char *s1, const char *s2) {
    while (*s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return *(unsigned char *)s1 - *(unsigned char *)s2;
}

size_t strlen(const char *s) {
    const char *p = s;
    while (*p) p++;
    return p - s;
}

void *memcpy(void *dest, const void *src, size_t n) {
    char *d = dest;
    const char *s = src;
    while (n--) *d++ = *s++;
    return dest;
}

void *memset(void *s, int c, size_t n) {
    unsigned char *p = s;
    while (n--) *p++ = (unsigned char)c;
    return s;
}

// Time functions for RISC-V
// Read cycle counter using rdcycle instruction
static inline long read_cycles(void) {
    long cycles;
    asm volatile ("rdcycle %0" : "=r" (cycles));
    return cycles;
}

// Read instruction counter using rdinstret instruction
static inline long read_instret(void) {
    long instret;
    asm volatile ("rdinstret %0" : "=r" (instret));
    return instret;
}

// Time function returns cycle count
long time(long *tloc) {
    long t = read_cycles();
    if (tloc) *tloc = t;
    return t;
}

// Instruction count function
long insn(long *iloc) {
    long i = read_instret();
    if (iloc) *iloc = i;
    return i;
}