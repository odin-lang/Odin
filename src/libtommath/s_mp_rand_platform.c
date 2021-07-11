#include "tommath_private.h"
#ifdef S_MP_RAND_PLATFORM_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* First the OS-specific special cases
 * - *BSD
 * - Windows
 */
#if defined(__FreeBSD__) || defined(__OpenBSD__) || defined(__NetBSD__) || defined(__DragonFly__)
#define S_READ_ARC4RANDOM_C
static mp_err s_read_arc4random(void *p, size_t n)
{
   arc4random_buf(p, n);
   return MP_OKAY;
}
#endif

#if defined(_WIN32)
#define S_READ_WINCSP_C

#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0501
#endif
#ifndef WINVER
#define WINVER 0x0501
#endif

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <wincrypt.h>

static mp_err s_read_wincsp(void *p, size_t n)
{
   static HCRYPTPROV hProv = 0;
   if (hProv == 0) {
      HCRYPTPROV h = 0;
      if (!CryptAcquireContextW(&h, NULL, MS_DEF_PROV_W, PROV_RSA_FULL,
                                (CRYPT_VERIFYCONTEXT | CRYPT_MACHINE_KEYSET)) &&
          !CryptAcquireContextW(&h, NULL, MS_DEF_PROV_W, PROV_RSA_FULL,
                                CRYPT_VERIFYCONTEXT | CRYPT_MACHINE_KEYSET | CRYPT_NEWKEYSET)) {
         return MP_ERR;
      }
      hProv = h;
   }
   return CryptGenRandom(hProv, (DWORD)n, (BYTE *)p) == TRUE ? MP_OKAY : MP_ERR;
}
#endif /* WIN32 */

#if !defined(S_READ_WINCSP_C) && defined(__linux__) && defined(__GLIBC_PREREQ)
#if __GLIBC_PREREQ(2, 25)
#define S_READ_GETRANDOM_C
#include <sys/random.h>
#include <errno.h>

static mp_err s_read_getrandom(void *p, size_t n)
{
   char *q = (char *)p;
   while (n > 0u) {
      ssize_t ret = getrandom(q, n, 0);
      if (ret < 0) {
         if (errno == EINTR) {
            continue;
         }
         return MP_ERR;
      }
      q += ret;
      n -= (size_t)ret;
   }
   return MP_OKAY;
}
#endif
#endif

/* We assume all platforms besides windows provide "/dev/urandom".
 * In case yours doesn't, define MP_NO_DEV_URANDOM at compile-time.
 */
#if !defined(S_READ_WINCSP_C) && !defined(MP_NO_DEV_URANDOM)
#define S_READ_URANDOM_C
#ifndef MP_DEV_URANDOM
#define MP_DEV_URANDOM "/dev/urandom"
#endif
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>

static mp_err s_read_urandom(void *p, size_t n)
{
   int fd;
   char *q = (char *)p;

   do {
      fd = open(MP_DEV_URANDOM, O_RDONLY);
   } while ((fd == -1) && (errno == EINTR));
   if (fd == -1) return MP_ERR;

   while (n > 0u) {
      ssize_t ret = read(fd, p, n);
      if (ret < 0) {
         if (errno == EINTR) {
            continue;
         }
         close(fd);
         return MP_ERR;
      }
      q += ret;
      n -= (size_t)ret;
   }

   close(fd);
   return MP_OKAY;
}
#endif

mp_err s_read_arc4random(void *p, size_t n);
mp_err s_read_wincsp(void *p, size_t n);
mp_err s_read_getrandom(void *p, size_t n);
mp_err s_read_urandom(void *p, size_t n);

/*
 * Note: libtommath relies on dead code elimination
 * for the configuration system, i.e., the MP_HAS macro.
 *
 * If you observe linking errors in this functions,
 * your compiler does not perform the dead code compilation
 * such that the unused functions are still referenced.
 *
 * This happens for example for MSVC if the /Od compilation
 * option is given. The option /Od instructs MSVC to
 * not perform any "optimizations", not even removal of
 * dead code wrapped in `if (0)` blocks.
 *
 * If you still insist on compiling with /Od, simply
 * comment out the lines which result in linking errors.
 *
 * We intentionally don't fix this issue in order
 * to have a single point of failure for misconfigured compilers.
 */
mp_err s_mp_rand_platform(void *p, size_t n)
{
   mp_err err = MP_ERR;
   if ((err != MP_OKAY) && MP_HAS(S_READ_ARC4RANDOM)) err = s_read_arc4random(p, n);
   if ((err != MP_OKAY) && MP_HAS(S_READ_WINCSP))     err = s_read_wincsp(p, n);
   if ((err != MP_OKAY) && MP_HAS(S_READ_GETRANDOM))  err = s_read_getrandom(p, n);
   if ((err != MP_OKAY) && MP_HAS(S_READ_URANDOM))    err = s_read_urandom(p, n);
   return err;
}

#endif
