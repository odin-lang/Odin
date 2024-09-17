#include <stddef.h>

void *memcpy(void *, const void *, size_t);
void *memset(void *, int, size_t);
void *memmove(void *, void *, size_t);
int memcmp(const void *, const void *, size_t);

unsigned long strlen(const char *str);

char *strchr(const char *, int);
char *strrchr(const char *, int);

char *strncpy(char *, const char *, size_t);
char *strcpy(char *, const char *);

size_t strcspn(const char *, const char *);

int strcmp(const char *, const char *);
int strncmp(const char *, const char *, size_t);

char *strstr(const char *, const char *);
