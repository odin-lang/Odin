#ifdef NDEBUG
#define	assert(e)	((void)0)
#else

#ifdef __FILE_NAME__
#define __ASSERT_FILE_NAME __FILE_NAME__
#else /* __FILE_NAME__ */
#define __ASSERT_FILE_NAME __FILE__
#endif /* __FILE_NAME__ */

void __odin_libc_assert_fail(const char *, const char *, int, const char *);

#define	assert(e) \
    (__builtin_expect(!(e), 0) ? __odin_libc_assert_fail(__func__, __ASSERT_FILE_NAME, __LINE__, #e) : (void)0)

#endif /* NDEBUG */
