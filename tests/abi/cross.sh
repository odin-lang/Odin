#!/usr/bin/env bash
set -eu

# LOCAL ONLY: not wired into CI.
#
# This covers what is not in CI: the targets with no CI job and no cross libc,
# i386 and arm32, for checking manually.
#
# `abi_main.odin` is the corpus without core:testing, exiting with the number of
# failing types, so this needs no threads, no libc and no cross sysroot, only
# clang (which targets everything) and qemu-user.
#
#   ./cross.sh linux_arm64  aarch64-linux-gnu  qemu-aarch64
#   ./cross.sh linux_i386   i386-linux-gnu     qemu-i386
#   ./cross.sh linux_arm32  arm-linux-gnueabihf qemu-arm
#   ./cross.sh linux_riscv64 riscv64-linux-gnu qemu-riscv64

TARGET=${1:?odin target, e.g. linux_arm64}
TRIPLE=${2:?clang triple, e.g. aarch64-linux-gnu}
QEMU=${3:?qemu binary, e.g. qemu-aarch64}
: "${ODIN:=../../odin}"
: "${CLANG:=clang}"

case "$TARGET" in
*i386*)    START='.text
	.globl _start
_start:
	call probe_main
	movl %eax, %ebx
	movl $1, %eax
	int $0x80' ;;
*arm64*)   START='.text
	.globl _start
_start:
	bl probe_main
	mov x8, #93
	svc #0' ;;
*arm32*)   START='.text
	.globl _start
_start:
	bl probe_main
	mov r7, #1
	svc #0' ;;
*riscv64*) START='.text
	.globl _start
_start:
	call probe_main
	mv a0, a0
	li a7, 93
	ecall' ;;
*) echo "no start stub for $TARGET" >&2; exit 2 ;;
esac


rm -rf build-cross
mkdir -p build-cross/p
python3 gen.py build-cross

# Ask the C compiler which tiers it has, by preprocessing the generated `build-cross/tiers.c`. 
# The Odin side must use the same tiers or it references symbols C never emitted.
have() { $CLANG --target="$TRIPLE" -E build-cross/tiers.c 2>/dev/null | grep -q "ABI_YES_$1" && echo true || echo false; }
TIERS="-define:ABI_TIER_GNU=$(have GNU) -define:ABI_TIER_F16=$(have F16) -define:ABI_TIER_I128=$(have I128)"
mv build-cross/abi_main.odin build-cross/p/
printf '%s\n' "$START" > build-cross/start.s

# A freestanding shim: the runtime reaches for a few libc symbols even with
# -no-crt, and 64-bit division on a 32-bit target is a compiler-rt call.
cat > build-cross/shim.c <<'EOF'
typedef unsigned long usz;
static char heap[1<<20];
static usz hoff;
void *malloc(usz n){ usz a=(hoff+15)&~(usz)15; if(a+n>sizeof heap) return 0; hoff=a+n; return heap+a; }
void free(void *p){ (void)p; }
void *calloc(usz n, usz m){ char*p=malloc(n*m); if(p) for(usz i=0;i<n*m;i++)p[i]=0; return p; }
void *realloc(void *p, usz n){ char*q=malloc(n); if(q&&p) for(usz i=0;i<n;i++)q[i]=((char*)p)[i]; return q; }
void *memcpy(void *d, const void *s, usz n){ char*a=d; const char*b=s; for(usz i=0;i<n;i++)a[i]=b[i]; return d; }
void *memmove(void *d, const void *s, usz n){ char*a=d; const char*b=s;
  if(a<b){for(usz i=0;i<n;i++)a[i]=b[i];} else {for(usz i=n;i>0;i--)a[i-1]=b[i-1];} return d; }
void *memset(void *d, int c, usz n){ char*a=d; for(usz i=0;i<n;i++)a[i]=(char)c; return d; }
int memcmp(const void *x, const void *y, usz n){ const unsigned char*a=x,*b=y;
  for(usz i=0;i<n;i++) if(a[i]!=b[i]) return a[i]<b[i]?-1:1; return 0; }
void abort(void){ __builtin_trap(); }
unsigned long __stack_chk_guard = 0x2b2b2b2b;
void __stack_chk_fail(void){ __builtin_trap(); }
typedef unsigned long long u64; typedef long long i64;
static u64 udivmod(u64 a, u64 b, u64 *rem){ u64 q=0,r=0;
  if(b==0){ if(rem)*rem=0; return 0; }
  for(int i=63;i>=0;i--){ r=(r<<1)|((a>>i)&1); if(r>=b){ r-=b; q|=(u64)1<<i; } }
  if(rem)*rem=r; return q; }
u64 __udivdi3(u64 a, u64 b){ return udivmod(a,b,0); }
u64 __umoddi3(u64 a, u64 b){ u64 r; udivmod(a,b,&r); return r; }
i64 __divdi3(i64 a, i64 b){ int n=0; u64 ua=a<0?(n^=1,(u64)-a):(u64)a, ub=b<0?(n^=1,(u64)-b):(u64)b;
  u64 q=udivmod(ua,ub,0); return n?-(i64)q:(i64)q; }
i64 __moddi3(i64 a, i64 b){ int n=a<0; u64 ua=a<0?(u64)-a:(u64)a, ub=b<0?(u64)-b:(u64)b;
  u64 r; udivmod(ua,ub,&r); return n?-(i64)r:(i64)r; }
EOF

set -x
$ODIN build build-cross/p -target:"$TARGET" -build-mode:obj -no-entry-point \
	-no-thread-local -reloc-mode:static $TIERS -out:build-cross/o
$CLANG --target="$TRIPLE" -c build-cross/abi_corpus.c -o build-cross/abi_corpus_c.o -w -fno-stack-protector
$CLANG --target="$TRIPLE" -c build-cross/start.s -o build-cross/start.o
$CLANG --target="$TRIPLE" -ffreestanding -fno-builtin -O1 -w -c build-cross/shim.c -o build-cross/shim.o
$CLANG --target="$TRIPLE" -nostdlib -static -fuse-ld=lld \
	build-cross/*.o -o build-cross/bin
set +x

set +e
"$QEMU" build-cross/bin
rc=$?
set -e

if [ "$rc" -eq 0 ]; then
	echo "$TARGET: every type agrees with clang"
else
	# the driver returns the INDEX of the first disagreement, and the generator
	# emits the index -> name map, so the failure names a type rather than a count
	name=$(grep -m1 "^// $rc	" build-cross/p/abi_main.odin | cut -f2)
	echo "$TARGET: DISAGREES with clang, first at type '${name:-#$rc}'" >&2
	echo "  re-run with -define:ABI_SKIP=$rc to find the next one" >&2
fi
rm -rf build-cross
exit $rc
