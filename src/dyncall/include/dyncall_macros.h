/*

 Package: dyncall
 Library: dyncall
 File: dyncall/dyncall_macros.h
 Description: Platform detection macros
 License:

   Copyright (c) 2007-2015 Daniel Adler <dadler@uni-goettingen.de>, 
                           Tassilo Philipp <tphilipp@potion-studios.com>

   Permission to use, copy, modify, and distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

*/



/*

  dyncall macros

  Platform detection, specific defines and configuration.
  The purpose of this file is to provide coherent platform and compiler
  specific defines. So instead of defines like WIN32, _OpenBSD_ or
  __GNUC__, one should use DC__OS_Win32, DC__OS_OpenBSD or DC__C_GNU,
  respectively.

  REVISION
  2007/12/11 initial

*/


#ifndef DYNCALL_MACROS_H
#define DYNCALL_MACROS_H


/* Platform specific defines. */

/* MS Windows XP x64/Vista64 or later. */
#if defined(WIN64) || defined(_WIN64) || defined(__WIN64__)
#define DC__OS_Win64

/* MS Windows NT/95/98/ME/2000/XP/Vista32. */
#elif defined(WIN32) || defined(_WIN32) || defined(__WIN32__) || defined(__NT__) || defined(__WINDOWS__) || defined(_WINDOWS)
#define DC__OS_Win32

/* All the OS' based on Darwin OS (MacOS X, OpenDarwin). Note that '__APPLE__' may be defined for classic MacOS, too. */
/* __MACOSX__ is not defined in gcc assembler mode (switch: -S) */
/* @@@ TODO: Check for Classic OS */

#elif defined(__APPLE__) || defined(__Darwin__)
#  define DC__OS_Darwin
#  if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__)
#    define DC__OS_IPhone
#  else /* defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) */
#    define DC__OS_MacOSX
#  endif

/* The most popular open source Unix-like OS - Linux. */
#elif defined(__linux__) || defined(__linux) || defined(__gnu_linux__)
#define DC__OS_Linux

/* The most powerful open source Unix-like OS - FreeBSD. */
#elif defined(__FreeBSD__) || defined(__FreeBSD_kernel__)
#define DC__OS_FreeBSD

/* The most secure open source Unix-like OS - OpenBSD. */
#elif defined(__OpenBSD__)
#define DC__OS_OpenBSD

/* The most portable open source Unix-like OS - NetBSD. */
#elif defined(__NetBSD__)
#define DC__OS_NetBSD

/* The FreeBSD fork having heavy clusterization in mind - DragonFlyBSD. */
#elif defined(__DragonFly__)
#define DC__OS_DragonFlyBSD

/* Sun's Unix-like OS - SunOS / Solaris. */
#elif defined(__sun__) || defined(__sun) || defined(sun)
#define DC__OS_SunOS

/* The "Linux-like environment for Windows" - Cygwin. */
#elif defined(__CYGWIN__)
#define DC__OS_Cygwin

/* The "Minimalist GNU for Windows" - MinGW. */
#elif defined(__MINGW__)/*@@@*/
#define DC__OS_MinGW

/* The Nintendo DS (homebrew) using devkitpro. */
#elif defined(__nds__)
#define DC__OS_NDS

/* The PlayStation Portable (homebrew) SDK. */
#elif defined(__psp__) || defined(PSP)
#define DC__OS_PSP

/* Haiku (BeOS alike). */
#elif defined(__HAIKU__)
#define DC__OS_BeOS

/* The Unix successor - Plan9 from Bell Labs */
#elif defined(Plan9) || defined(__Plan9__)
#define DC__OS_Plan9

/* Digital's Unix-like OS - VMS */
#elif defined(__vms)
#define DC__OS_VMS

#elif defined(__minix)
#define DC__OS_Minix

#else
	#error Unsupported OS.
#endif



/* Compiler specific defines. Do not change the order, because  */
/* some of the compilers define flags for compatible ones, too. */

/* Intel's C/C++ compiler. */
#if defined(__INTEL_COMPILER)
#define DC__C_Intel

/* MS C/C++ compiler. */
#elif defined(_MSC_VER)
#define DC__C_MSVC

/* LLVM clang. */
#elif defined(__clang__)
#define DC__C_CLANG

/* The GNU Compiler Collection - GCC. */
#elif defined(__GNUC__)
#define DC__C_GNU

/* Watcom compiler. */
#elif defined(__WATCOMC__)
#define DC__C_WATCOM

/* Portable C Compiler. */
#elif defined(__PCC__)
#define DC__C_PCC

/* Sun Pro C. */
#elif defined(__SUNPRO_C)
#define DC__C_SUNPRO

/* Undetected C Compiler. */
#else
#define DC__C_UNKNOWN
#endif



/* Architecture. */

/* Check architecture. */
#if defined(_M_X64_) || defined(_M_AMD64) || defined(__amd64__) || defined(__amd64) || defined(__x86_64__) || defined(__x86_64) 
# define DC__Arch_AMD64
#elif defined(_M_IX86) || defined(__i386__) || defined(__i486__) || defined(__i586__) || defined(__i686__) || defined(__386__) || defined(__i386)
# define DC__Arch_Intel_x86
#elif defined(_M_IA64) || defined(__ia64__)
# define DC__Arch_Itanium
#elif defined(_M_PPC) || defined(__powerpc__) || defined(__powerpc) || defined(__POWERPC__) || defined(__ppc__) || defined(__power__)
# if defined(__ppc64__) || defined(_ARCH_PPC64) || defined(__power64__) || defined(__powerpc64__)
#   define DC__Arch_PPC64
# else
#   define DC__Arch_PPC32
# endif
#elif defined(__mips64__) || defined(__mips64)
# define DC__Arch_MIPS64
#elif defined(_M_MRX000) || defined(__mips__) || defined(__mips) || defined(_mips)
# define DC__Arch_MIPS
#elif defined(__arm__)
# define DC__Arch_ARM
#elif defined(__aarch64__)
# define DC__Arch_ARM64
#elif defined(__sh__)
# define DC__Arch_SuperH
#elif defined(__sparcv9) || defined(__sparc64__) || ( defined(__sparc) && defined(__arch64__) ) 
/* this could be needed on Linux/GNU sparc64 in the future: || ( defined(__sparc) && defined(__arch64__) ) */
# define DC__Arch_Sparcv9
#elif defined(__sparc)
# define DC__Arch_Sparc
#endif



/* Rough OS classification. */

#if defined(DC__OS_Win32) || defined(DC__OS_Win64)
# define DC_WINDOWS
#elif defined(DC__OS_Plan9)
# define DC_PLAN9
#elif defined(DC__OS_NDS) || defined(DC__OS_PSP)
# define DC_OTHER
#else
# define DC_UNIX
#endif



/* Misc machine-dependent modes, ABIs, etc.. */

#if defined(__arm__) && !defined(__thumb__)
# define DC__Arch_ARM_ARM
#elif defined(__arm__) && defined(__thumb__)
# define DC__Arch_ARM_THUMB
#endif

#if defined(DC__Arch_ARM_ARM) || defined(DC__Arch_ARM_THUMB)
# if defined(__ARM_EABI__) || defined(DC__OS_NDS)
#  if defined (__ARM_PCS_VFP) && (__ARM_PCS_VFP == 1)
#    define DC__ABI_ARM_HF
#  else
#    define DC__ABI_ARM_EABI
#  endif
# elif defined(__APCS_32__)
#  define DC__ABI_ARM_OABI
# endif
#endif /* ARM */

#if defined(DC__Arch_MIPS) || defined(DC__Arch_MIPS64)
# if defined(_ABIO32) || defined(_MIPS_ARCH_MIPS1) || defined(_MIPS_ARCH_MIPS2)
#  define DC__ABI_MIPS_O32
# elif defined(_ABIN32)
#  define DC__ABI_MIPS_N32
# elif defined(_ABI64)
#  define DC__ABI_MIPS_N64
# else
#  define DC__ABI_MIPS_EABI
# endif
#endif /* MIPS */

#if defined(DC__Arch_PPC64)
# if defined(_CALL_ELF)
#  define DC__ABI_PPC64_ELF_V _CALL_ELF
# else
#  define DC__ABI_PPC64_ELF_V 0 /* 0 means not explicitly set, otherwise this is 1 (big endian) and 2 (little endian) */
# endif
#endif /* MIPS */


/* Endian detection. */
#if defined(DC__Arch_Intel_x86) || defined(DC__Arch_AMD64) /* always little */
# define DC__Endian_LITTLE
#elif defined(DC__Arch_Sparc)                              /*always big until v9*/
# define DC__Endian_BIG
#else                                                      /* all others are bi-endian */
/* @@@check flags used on following bi-endianness archs:
DC__Arch_ARM
DC__Arch_ARM64
DC__Arch_Itanium
DC__Arch_MIPS
DC__Arch_MIPS64
DC__Arch_PPC32
DC__Arch_PPC64
DC__Arch_Sparcv9
DC__Arch_SuperH
*/
# if (defined(DC__Arch_PPC64) && (DC__ABI_PPC64_ELF_V == 1)) || defined(_BIG_ENDIAN) || defined(MIPSEB)
#  define DC__Endian_BIG
# elif (defined(DC__Arch_PPC64) && (DC__ABI_PPC64_ELF_V == 2)) || defined(_LITTLE_ENDIAN) || defined(MIPSEL)
#  define DC__Endian_LITTLE
# endif /* no else, leave unset if not sure */
#endif


/* Internal macro/tag. */
#if !defined(DC_API)
#define DC_API
#endif

#endif /* DYNCALL_MACROS_H */

