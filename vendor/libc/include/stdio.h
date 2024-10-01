#include <stddef.h>
#include <stdarg.h>

#pragma once

typedef struct {} FILE;

#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2

#define stdout ((FILE *)2)
#define stderr ((FILE *)3)

FILE *fopen(const char *, char *);
int fclose(FILE *);
int fseek(FILE *, long, int);
long ftell(FILE *);
size_t fread(void *, size_t, size_t, FILE *);
size_t fwrite(const void *, size_t, size_t, FILE *);

int vfprintf(FILE *, const char *, va_list);
int vsnprintf(char *, size_t, const char *, va_list);

static inline int snprintf(char *buf, size_t size, const char *fmt, ...) {
	va_list args;
	va_start(args, fmt);
	int result = vsnprintf(buf, size, fmt, args);
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
