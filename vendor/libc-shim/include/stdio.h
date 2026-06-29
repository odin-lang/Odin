#ifdef __cplusplus
extern "C" {
#endif

#pragma once

#include <alloca.h>
#include <assert.h>
#include <stdarg.h>
#include <stddef.h>

typedef struct {} FILE;

#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2

#define stdout ((FILE *)2)
#define stderr ((FILE *)3)

#define EOF -1

FILE *fopen(const char *, char *);
int fclose(FILE *);
int fseek(FILE *, long, int);
long ftell(FILE *);
size_t fread(void *, size_t, size_t, FILE *);
size_t fwrite(const void *, size_t, size_t, FILE *);

int vfprintf(FILE *, const char *, va_list);
int vsnprintf(char *, size_t, const char *, va_list);
int vsprintf(char *, const char *, va_list);

int putchar(int ch);
int getchar();

static inline int snprintf(char *buf, size_t size, const char *fmt, ...) {
	va_list args;
	va_start(args, fmt);
	int result = vsnprintf(buf, size, fmt, args);
	va_end(args);
	return result;
}

static inline int sprintf(char *buf, const char *fmt, ...) {
	va_list args;
	va_start(args, fmt);
	int result = vsprintf(buf, fmt, args);
	va_end(args);
	return result;
}

static inline int fprintf(FILE *f, const char *fmt, ...) {
	va_list args;
	va_start(args, fmt);
	int result = vfprintf(f, fmt, args);
	va_end(args);
	return result;
}

static inline int printf(const char *fmt, ...) {
	va_list args;
	va_start(args, fmt);
	int result = vfprintf(stdout, fmt, args);
	va_end(args);
	return result;
}

int __sscanf(const char *str, const char *format, void *ptrs);

static inline int vsscanf(const char *str, const char *format, va_list ap) {
	int count = 0;
	for (int i = 0; format[i]; i++) {
		if (format[i] == '%') {
			if (format[i+1] == '%') {
				i++;
				continue;
			}
			count++;
		}
	}

	void **ptrs = (void **)(alloca(count*sizeof(void *)));
	for (int i = 0; i < count; i++) {
		ptrs[i] = va_arg(ap, void *);
	}

	return __sscanf(str, format, ptrs);
}

static inline int sscanf(const char *str, const char *format, ...) {
	va_list args;
	va_start(args, format);
	int res = vsscanf(str, format, args);
	va_end(args);
	return res;
}

#ifdef __cplusplus
}
#endif
