/* syscalls.c - Minimal system calls for RISC-V bare metal */

#include <stdarg.h>
#include <stddef.h>

// UART base address (you may need to adjust this)
#define UART_BASE 0x10000000

// Simple UART output
static void uart_putc(char c) {
    // For simulation, just write to a fixed address
    // The testbench can monitor this
    volatile char *uart = (volatile char *)UART_BASE;
    *uart = c;
}

// Basic printf implementation
static void print_string(const char *s) {
    while (*s) {
        uart_putc(*s++);
    }
}

static void print_int(int val) {
    char buffer[12];
    int i = 0;
    int is_negative = 0;
    
    if (val < 0) {
        is_negative = 1;
        val = -val;
    }
    
    if (val == 0) {
        uart_putc('0');
        return;
    }
    
    while (val > 0) {
        buffer[i++] = '0' + (val % 10);
        val /= 10;
    }
    
    if (is_negative) {
        uart_putc('-');
    }
    
    while (i > 0) {
        uart_putc(buffer[--i]);
    }
}

static void print_hex(unsigned int val) {
    const char hex[] = "0123456789abcdef";
    uart_putc('0');
    uart_putc('x');
    for (int i = 28; i >= 0; i -= 4) {
        uart_putc(hex[(val >> i) & 0xF]);
    }
}

// Simple printf supporting %d, %s, %c, %x
int printf(const char *format, ...) {
    va_list args;
    va_start(args, format);
    
    while (*format) {
        if (*format == '%') {
            format++;
            switch (*format) {
                case 'd':
                    print_int(va_arg(args, int));
                    break;
                case 's':
                    print_string(va_arg(args, char*));
                    break;
                case 'c':
                    uart_putc((char)va_arg(args, int));
                    break;
                case 'x':
                    print_hex(va_arg(args, unsigned int));
                    break;
                case '%':
                    uart_putc('%');
                    break;
                default:
                    uart_putc('%');
                    uart_putc(*format);
                    break;
            }
        } else {
            uart_putc(*format);
        }
        format++;
    }
    
    va_end(args);
    return 0;
}

// Scanf stub - returns fixed value for Dhrystone
int scanf(const char *format, ...) {
    // For Dhrystone, just return success
    return 1;
}

// Other system call stubs
void _exit(int status) {
    while (1);
}

int close(int file) {
    return -1;
}

int fstat(int file, void *st) {
    return -1;
}

int isatty(int file) {
    return 1;
}

int lseek(int file, int ptr, int dir) {
    return 0;
}

int read(int file, char *ptr, int len) {
    return 0;
}

int write(int file, char *ptr, int len) {
    int i;
    for (i = 0; i < len; i++) {
        uart_putc(ptr[i]);
    }
    return len;
}

void *sbrk(int incr) {
    extern char _end;
    static char *heap_end = 0;
    char *prev_heap_end;
    
    if (heap_end == 0) {
        heap_end = &_end;
    }
    
    prev_heap_end = heap_end;
    heap_end += incr;
    
    return (void *)prev_heap_end;
}