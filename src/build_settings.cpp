#if defined(GB_SYSTEM_FREEBSD) || defined(GB_SYSTEM_OPENBSD)
#include <sys/types.h>
#include <sys/sysctl.h>
#endif

// #if defined(GB_SYSTEM_WINDOWS)
// #define DEFAULT_TO_THREADED_CHECKER
// #endif

#define DEFAULT_MAX_ERROR_COLLECTOR_COUNT (36)

enum TargetOsKind : u16 {
	TargetOs_Invalid,

	TargetOs_windows,
	TargetOs_darwin,
	TargetOs_linux,
	TargetOs_essence,
	TargetOs_freebsd,
	TargetOs_openbsd,
	TargetOs_netbsd,
	TargetOs_haiku,
	
	TargetOs_wasi,
	TargetOs_js,

	TargetOs_freestanding,

	TargetOs_COUNT,
};

enum TargetArchKind : u16 {
	TargetArch_Invalid,

	TargetArch_amd64,
	TargetArch_i386,
	TargetArch_arm32,
	TargetArch_arm64,
	TargetArch_wasm32,
	TargetArch_wasm64p32,

	TargetArch_COUNT,
};

enum TargetEndianKind : u8 {
	TargetEndian_Little,
	TargetEndian_Big,

	TargetEndian_COUNT,
};

enum TargetABIKind : u16 {
	TargetABI_Default,

	TargetABI_Win64,
	TargetABI_SysV,

	TargetABI_COUNT,
};

enum Windows_Subsystem : u8 {
 	Windows_Subsystem_BOOT_APPLICATION,
	Windows_Subsystem_CONSOLE,                 // Default,
	Windows_Subsystem_EFI_APPLICATION,
	Windows_Subsystem_EFI_BOOT_SERVICE_DRIVER,
	Windows_Subsystem_EFI_ROM,
	Windows_Subsystem_EFI_RUNTIME_DRIVER,
	Windows_Subsystem_NATIVE,
	Windows_Subsystem_POSIX,
	Windows_Subsystem_WINDOWS,
	Windows_Subsystem_WINDOWSCE,
	Windows_Subsystem_COUNT,
};

struct MicroarchFeatureList {
	String microarch;
	String features;
};

gb_global String target_os_names[TargetOs_COUNT] = {
	str_lit(""),
	str_lit("windows"),
	str_lit("darwin"),
	str_lit("linux"),
	str_lit("essence"),
	str_lit("freebsd"),
	str_lit("openbsd"),
	str_lit("netbsd"),
	str_lit("haiku"),
	
	str_lit("wasi"),
	str_lit("js"),

	str_lit("freestanding"),
};

gb_global String target_arch_names[TargetArch_COUNT] = {
	str_lit(""),
	str_lit("amd64"),
	str_lit("i386"),
	str_lit("arm32"),
	str_lit("arm64"),
	str_lit("wasm32"),
	str_lit("wasm64p32"),
};

// Generated with the featuregen script in `misc/featuregen`
gb_global String target_microarch_list[TargetArch_COUNT] = {
	// TargetArch_Invalid:
	str_lit(""),
	// TargetArch_amd64:
	str_lit("alderlake,amdfam10,athlon,athlon-4,athlon-fx,athlon-mp,athlon-tbird,athlon-xp,athlon64,athlon64-sse3,atom,atom_sse4_2,atom_sse4_2_movbe,barcelona,bdver1,bdver2,bdver3,bdver4,bonnell,broadwell,btver1,btver2,c3,c3-2,cannonlake,cascadelake,cooperlake,core-avx-i,core-avx2,core2,core_2_duo_sse4_1,core_2_duo_ssse3,core_2nd_gen_avx,core_3rd_gen_avx,core_4th_gen_avx,core_4th_gen_avx_tsx,core_5th_gen_avx,core_5th_gen_avx_tsx,core_aes_pclmulqdq,core_i7_sse4_2,corei7,corei7-avx,emeraldrapids,generic,geode,goldmont,goldmont-plus,goldmont_plus,grandridge,graniterapids,graniterapids-d,graniterapids_d,haswell,i386,i486,i586,i686,icelake-client,icelake-server,icelake_client,icelake_server,ivybridge,k6,k6-2,k6-3,k8,k8-sse3,knl,knm,lakemont,meteorlake,mic_avx512,nehalem,nocona,opteron,opteron-sse3,penryn,pentium,pentium-m,pentium-mmx,pentium2,pentium3,pentium3m,pentium4,pentium4m,pentium_4,pentium_4_sse3,pentium_ii,pentium_iii,pentium_iii_no_xmm_regs,pentium_m,pentium_mmx,pentium_pro,pentiumpro,prescott,raptorlake,rocketlake,sandybridge,sapphirerapids,sierraforest,silvermont,skx,skylake,skylake-avx512,skylake_avx512,slm,tigerlake,tremont,westmere,winchip-c6,winchip2,x86-64,x86-64-v2,x86-64-v3,x86-64-v4,yonah,znver1,znver2,znver3,znver4"),
	// TargetArch_i386:
	str_lit("alderlake,amdfam10,athlon,athlon-4,athlon-fx,athlon-mp,athlon-tbird,athlon-xp,athlon64,athlon64-sse3,atom,atom_sse4_2,atom_sse4_2_movbe,barcelona,bdver1,bdver2,bdver3,bdver4,bonnell,broadwell,btver1,btver2,c3,c3-2,cannonlake,cascadelake,cooperlake,core-avx-i,core-avx2,core2,core_2_duo_sse4_1,core_2_duo_ssse3,core_2nd_gen_avx,core_3rd_gen_avx,core_4th_gen_avx,core_4th_gen_avx_tsx,core_5th_gen_avx,core_5th_gen_avx_tsx,core_aes_pclmulqdq,core_i7_sse4_2,corei7,corei7-avx,emeraldrapids,generic,geode,goldmont,goldmont-plus,goldmont_plus,grandridge,graniterapids,graniterapids-d,graniterapids_d,haswell,i386,i486,i586,i686,icelake-client,icelake-server,icelake_client,icelake_server,ivybridge,k6,k6-2,k6-3,k8,k8-sse3,knl,knm,lakemont,meteorlake,mic_avx512,nehalem,nocona,opteron,opteron-sse3,penryn,pentium,pentium-m,pentium-mmx,pentium2,pentium3,pentium3m,pentium4,pentium4m,pentium_4,pentium_4_sse3,pentium_ii,pentium_iii,pentium_iii_no_xmm_regs,pentium_m,pentium_mmx,pentium_pro,pentiumpro,prescott,raptorlake,rocketlake,sandybridge,sapphirerapids,sierraforest,silvermont,skx,skylake,skylake-avx512,skylake_avx512,slm,tigerlake,tremont,westmere,winchip-c6,winchip2,x86-64,x86-64-v2,x86-64-v3,x86-64-v4,yonah,znver1,znver2,znver3,znver4"),
	// TargetArch_arm32:
	str_lit("arm1020e,arm1020t,arm1022e,arm10e,arm10tdmi,arm1136j-s,arm1136jf-s,arm1156t2-s,arm1156t2f-s,arm1176jz-s,arm1176jzf-s,arm710t,arm720t,arm7tdmi,arm7tdmi-s,arm8,arm810,arm9,arm920,arm920t,arm922t,arm926ej-s,arm940t,arm946e-s,arm966e-s,arm968e-s,arm9e,arm9tdmi,cortex-a12,cortex-a15,cortex-a17,cortex-a32,cortex-a35,cortex-a5,cortex-a53,cortex-a55,cortex-a57,cortex-a7,cortex-a710,cortex-a72,cortex-a73,cortex-a75,cortex-a76,cortex-a76ae,cortex-a77,cortex-a78,cortex-a78c,cortex-a8,cortex-a9,cortex-m0,cortex-m0plus,cortex-m1,cortex-m23,cortex-m3,cortex-m33,cortex-m35p,cortex-m4,cortex-m55,cortex-m7,cortex-m85,cortex-r4,cortex-r4f,cortex-r5,cortex-r52,cortex-r7,cortex-r8,cortex-x1,cortex-x1c,cyclone,ep9312,exynos-m3,exynos-m4,exynos-m5,generic,iwmmxt,krait,kryo,mpcore,mpcorenovfp,neoverse-n1,neoverse-n2,neoverse-v1,sc000,sc300,strongarm,strongarm110,strongarm1100,strongarm1110,swift,xscale"),
	// TargetArch_arm64:
	str_lit("a64fx,ampere1,ampere1a,apple-a10,apple-a11,apple-a12,apple-a13,apple-a14,apple-a15,apple-a16,apple-a7,apple-a8,apple-a9,apple-latest,apple-m1,apple-m2,apple-s4,apple-s5,carmel,cortex-a34,cortex-a35,cortex-a510,cortex-a53,cortex-a55,cortex-a57,cortex-a65,cortex-a65ae,cortex-a710,cortex-a715,cortex-a72,cortex-a73,cortex-a75,cortex-a76,cortex-a76ae,cortex-a77,cortex-a78,cortex-a78c,cortex-r82,cortex-x1,cortex-x1c,cortex-x2,cortex-x3,cyclone,exynos-m3,exynos-m4,exynos-m5,falkor,generic,kryo,neoverse-512tvb,neoverse-e1,neoverse-n1,neoverse-n2,neoverse-v1,neoverse-v2,saphira,thunderx,thunderx2t99,thunderx3t110,thunderxt81,thunderxt83,thunderxt88,tsv110"),
	// TargetArch_wasm32:
	str_lit("bleeding-edge,generic,mvp"),
	// TargetArch_wasm64p32:
	str_lit("bleeding-edge,generic,mvp"),
};

// Generated with the featuregen script in `misc/featuregen`
gb_global String target_features_list[TargetArch_COUNT] = {
	// TargetArch_Invalid:
	str_lit(""),
	// TargetArch_amd64:
	str_lit("16bit-mode,32bit-mode,3dnow,3dnowa,64bit,64bit-mode,adx,aes,allow-light-256-bit,amx-bf16,amx-complex,amx-fp16,amx-int8,amx-tile,avx,avx2,avx512bf16,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512er,avx512f,avx512fp16,avx512ifma,avx512pf,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vp2intersect,avx512vpopcntdq,avxifma,avxneconvert,avxvnni,avxvnniint16,avxvnniint8,bmi,bmi2,branchfusion,cldemote,clflushopt,clwb,clzero,cmov,cmpccxadd,crc32,cx16,cx8,enqcmd,ermsb,f16c,false-deps-getmant,false-deps-lzcnt-tzcnt,false-deps-mulc,false-deps-mullq,false-deps-perm,false-deps-popcnt,false-deps-range,fast-11bytenop,fast-15bytenop,fast-7bytenop,fast-bextr,fast-gather,fast-hops,fast-lzcnt,fast-movbe,fast-scalar-fsqrt,fast-scalar-shift-masks,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fast-vector-shift-masks,faster-shift-than-shuffle,fma,fma4,fsgsbase,fsrm,fxsr,gfni,harden-sls-ijmp,harden-sls-ret,hreset,idivl-to-divb,idivq-to-divl,invpcid,kl,lea-sp,lea-uses-ag,lvi-cfi,lvi-load-hardening,lwp,lzcnt,macrofusion,mmx,movbe,movdir64b,movdiri,mwaitx,no-bypass-delay,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pad-short-functions,pclmul,pconfig,pku,popcnt,prefer-128-bit,prefer-256-bit,prefer-mask-registers,prefer-movmsk-over-vtest,prefer-no-gather,prefer-no-scatter,prefetchi,prefetchwt1,prfchw,ptwrite,raoint,rdpid,rdpru,rdrnd,rdseed,retpoline,retpoline-external-thunk,retpoline-indirect-branches,retpoline-indirect-calls,rtm,sahf,sbb-dep-breaking,serialize,seses,sgx,sha,sha512,shstk,slow-3ops-lea,slow-incdec,slow-lea,slow-pmaddwd,slow-pmulld,slow-shld,slow-two-mem-ops,slow-unaligned-mem-16,slow-unaligned-mem-32,sm3,sm4,soft-float,sse,sse-unaligned-mem,sse2,sse3,sse4.1,sse4.2,sse4a,ssse3,tagged-globals,tbm,tsxldtrk,tuning-fast-imm-vector-shift,uintr,use-glm-div-sqrt-costs,use-slm-arith-costs,vaes,vpclmulqdq,vzeroupper,waitpkg,wbnoinvd,widekl,x87,xop,xsave,xsavec,xsaveopt,xsaves"),
	// TargetArch_i386:
	str_lit("16bit-mode,32bit-mode,3dnow,3dnowa,64bit,64bit-mode,adx,aes,allow-light-256-bit,amx-bf16,amx-complex,amx-fp16,amx-int8,amx-tile,avx,avx2,avx512bf16,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512er,avx512f,avx512fp16,avx512ifma,avx512pf,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vp2intersect,avx512vpopcntdq,avxifma,avxneconvert,avxvnni,avxvnniint16,avxvnniint8,bmi,bmi2,branchfusion,cldemote,clflushopt,clwb,clzero,cmov,cmpccxadd,crc32,cx16,cx8,enqcmd,ermsb,f16c,false-deps-getmant,false-deps-lzcnt-tzcnt,false-deps-mulc,false-deps-mullq,false-deps-perm,false-deps-popcnt,false-deps-range,fast-11bytenop,fast-15bytenop,fast-7bytenop,fast-bextr,fast-gather,fast-hops,fast-lzcnt,fast-movbe,fast-scalar-fsqrt,fast-scalar-shift-masks,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fast-vector-shift-masks,faster-shift-than-shuffle,fma,fma4,fsgsbase,fsrm,fxsr,gfni,harden-sls-ijmp,harden-sls-ret,hreset,idivl-to-divb,idivq-to-divl,invpcid,kl,lea-sp,lea-uses-ag,lvi-cfi,lvi-load-hardening,lwp,lzcnt,macrofusion,mmx,movbe,movdir64b,movdiri,mwaitx,no-bypass-delay,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pad-short-functions,pclmul,pconfig,pku,popcnt,prefer-128-bit,prefer-256-bit,prefer-mask-registers,prefer-movmsk-over-vtest,prefer-no-gather,prefer-no-scatter,prefetchi,prefetchwt1,prfchw,ptwrite,raoint,rdpid,rdpru,rdrnd,rdseed,retpoline,retpoline-external-thunk,retpoline-indirect-branches,retpoline-indirect-calls,rtm,sahf,sbb-dep-breaking,serialize,seses,sgx,sha,sha512,shstk,slow-3ops-lea,slow-incdec,slow-lea,slow-pmaddwd,slow-pmulld,slow-shld,slow-two-mem-ops,slow-unaligned-mem-16,slow-unaligned-mem-32,sm3,sm4,soft-float,sse,sse-unaligned-mem,sse2,sse3,sse4.1,sse4.2,sse4a,ssse3,tagged-globals,tbm,tsxldtrk,tuning-fast-imm-vector-shift,uintr,use-glm-div-sqrt-costs,use-slm-arith-costs,vaes,vpclmulqdq,vzeroupper,waitpkg,wbnoinvd,widekl,x87,xop,xsave,xsavec,xsaveopt,xsaves"),
	// TargetArch_arm32:
	str_lit("32bit,8msecext,a12,a15,a17,a32,a35,a5,a53,a55,a57,a7,a72,a73,a75,a76,a77,a78c,a8,a9,aapcs-frame-chain,aapcs-frame-chain-leaf,aclass,acquire-release,aes,armv4,armv4t,armv5t,armv5te,armv5tej,armv6,armv6-m,armv6j,armv6k,armv6kz,armv6s-m,armv6t2,armv7-a,armv7-m,armv7-r,armv7e-m,armv7k,armv7s,armv7ve,armv8-a,armv8-m.base,armv8-m.main,armv8-r,armv8.1-a,armv8.1-m.main,armv8.2-a,armv8.3-a,armv8.4-a,armv8.5-a,armv8.6-a,armv8.7-a,armv8.8-a,armv8.9-a,armv9-a,armv9.1-a,armv9.2-a,armv9.3-a,armv9.4-a,atomics-32,avoid-movs-shop,avoid-partial-cpsr,bf16,big-endian-instructions,cde,cdecp0,cdecp1,cdecp2,cdecp3,cdecp4,cdecp5,cdecp6,cdecp7,cheap-predicable-cpsr,clrbhb,cortex-a710,cortex-a78,cortex-x1,cortex-x1c,crc,crypto,d32,db,dfb,disable-postra-scheduler,dont-widen-vmovs,dotprod,dsp,execute-only,expand-fp-mlx,exynos,fix-cmse-cve-2021-35465,fix-cortex-a57-aes-1742098,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp16fml,fp64,fpao,fpregs,fpregs16,fpregs64,fullfp16,fuse-aes,fuse-literals,harden-sls-blr,harden-sls-nocomdat,harden-sls-retbr,hwdiv,hwdiv-arm,i8mm,iwmmxt,iwmmxt2,krait,kryo,lob,long-calls,loop-align,m3,m7,mclass,mp,muxed-units,mve,mve.fp,mve1beat,mve2beat,mve4beat,nacl-trap,neon,neon-fpmovs,neonfp,neoverse-v1,no-branch-predictor,no-bti-at-return-twice,no-movt,no-neg-immediates,noarm,nonpipelined-vfp,pacbti,perfmon,prefer-ishst,prefer-vmovsr,prof-unpr,r4,r5,r52,r7,ras,rclass,read-tp-tpidrprw,read-tp-tpidruro,read-tp-tpidrurw,reserve-r9,ret-addr-stack,sb,sha2,slow-fp-brcc,slow-load-D-subreg,slow-odd-reg,slow-vdup32,slow-vgetlni32,slowfpvfmx,slowfpvmlx,soft-float,splat-vfp-neon,strict-align,swift,thumb-mode,thumb2,trustzone,use-mipipeliner,use-misched,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8.1a,v8.1m.main,v8.2a,v8.3a,v8.4a,v8.5a,v8.6a,v8.7a,v8.8a,v8.9a,v8m,v8m.main,v9.1a,v9.2a,v9.3a,v9.4a,v9a,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization,vldn-align,vmlx-forwarding,vmlx-hazards,wide-stride-vfp,xscale,zcz"),
	// TargetArch_arm64:
	str_lit("CONTEXTIDREL2,a35,a510,a53,a55,a57,a64fx,a65,a710,a715,a72,a73,a75,a76,a77,a78,a78c,aes,aggressive-fma,all,alternate-sextload-cvt-f32-pattern,altnzcv,am,ampere1,ampere1a,amvs,apple-a10,apple-a11,apple-a12,apple-a13,apple-a14,apple-a15,apple-a16,apple-a7,apple-a7-sysreg,arith-bcc-fusion,arith-cbz-fusion,ascend-store-address,b16b16,balance-fp-ops,bf16,brbe,bti,call-saved-x10,call-saved-x11,call-saved-x12,call-saved-x13,call-saved-x14,call-saved-x15,call-saved-x18,call-saved-x8,call-saved-x9,carmel,ccdp,ccidx,ccpp,chk,clrbhb,cmp-bcc-fusion,complxnum,cortex-r82,cortex-x1,cortex-x2,cortex-x3,crc,crypto,cssc,custom-cheap-as-move,d128,disable-latency-sched-heuristic,dit,dotprod,ecv,el2vmsa,el3,enable-select-opt,ete,exynos-cheap-as-move,exynosm3,exynosm4,f32mm,f64mm,falkor,fgt,fix-cortex-a53-835769,flagm,fmv,force-32bit-jump-tables,fp-armv8,fp16fml,fptoint,fullfp16,fuse-address,fuse-addsub-2reg-const1,fuse-adrp-add,fuse-aes,fuse-arith-logic,fuse-crypto-eor,fuse-csel,fuse-literals,gcs,harden-sls-blr,harden-sls-nocomdat,harden-sls-retbr,hbc,hcx,i8mm,ite,jsconv,kryo,lor,ls64,lse,lse128,lse2,lsl-fast,mec,mops,mpam,mte,neon,neoverse512tvb,neoversee1,neoversen1,neoversen2,neoversev1,neoversev2,nmi,no-bti-at-return-twice,no-neg-immediates,no-sve-fp-ld1r,no-zcz-fp,nv,outline-atomics,pan,pan-rwv,pauth,perfmon,predictable-select-expensive,predres,prfm-slc-target,rand,ras,rasv2,rcpc,rcpc-immo,rcpc3,rdm,reserve-x1,reserve-x10,reserve-x11,reserve-x12,reserve-x13,reserve-x14,reserve-x15,reserve-x18,reserve-x2,reserve-x20,reserve-x21,reserve-x22,reserve-x23,reserve-x24,reserve-x25,reserve-x26,reserve-x27,reserve-x28,reserve-x3,reserve-x30,reserve-x4,reserve-x5,reserve-x6,reserve-x7,reserve-x9,rme,saphira,sb,sel2,sha2,sha3,slow-misaligned-128store,slow-paired-128,slow-strqro-store,sm4,sme,sme-f16f16,sme-f64f64,sme-i16i64,sme2,sme2p1,spe,spe-eef,specres2,specrestrict,ssbs,strict-align,sve,sve2,sve2-aes,sve2-bitperm,sve2-sha3,sve2-sm4,sve2p1,tagged-globals,the,thunderx,thunderx2t99,thunderx3t110,thunderxt81,thunderxt83,thunderxt88,tlb-rmi,tme,tpidr-el1,tpidr-el2,tpidr-el3,tpidrro-el0,tracev8.4,trbe,tsv110,uaops,use-experimental-zeroing-pseudos,use-postra-scheduler,use-reciprocal-square-root,use-scalar-inc-vl,v8.1a,v8.2a,v8.3a,v8.4a,v8.5a,v8.6a,v8.7a,v8.8a,v8.9a,v8a,v8r,v9.1a,v9.2a,v9.3a,v9.4a,v9a,vh,wfxt,xs,zcm,zcz,zcz-fp-workaround,zcz-gp"),
	// TargetArch_wasm32:
	str_lit("atomics,bulk-memory,exception-handling,extended-const,multivalue,mutable-globals,nontrapping-fptoint,reference-types,relaxed-simd,sign-ext,simd128,tail-call"),
	// TargetArch_wasm64p32:
	str_lit("atomics,bulk-memory,exception-handling,extended-const,multivalue,mutable-globals,nontrapping-fptoint,reference-types,relaxed-simd,sign-ext,simd128,tail-call"),
};

// Generated with the featuregen script in `misc/featuregen`
gb_global int target_microarch_counts[TargetArch_COUNT] = {
	// TargetArch_Invalid:
	0,
	// TargetArch_amd64:
	120,
	// TargetArch_i386:
	120,
	// TargetArch_arm32:
	90,
	// TargetArch_arm64:
	63,
	// TargetArch_wasm32:
	3,
	// TargetArch_wasm64p32:
	3,
};

// Generated with the featuregen script in `misc/featuregen`
gb_global MicroarchFeatureList microarch_features_list[] = {
	// TargetArch_amd64:
	{ str_lit("alderlake"), str_lit("64bit,64bit-mode,adx,aes,allow-light-256-bit,avx,avx2,avxvnni,bmi,bmi2,cldemote,clflushopt,clwb,cmov,crc32,cx16,cx8,f16c,false-deps-perm,false-deps-popcnt,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fxsr,gfni,hreset,idivq-to-divl,invpcid,kl,lzcnt,macrofusion,mmx,movbe,movdir64b,movdiri,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pconfig,pku,popcnt,prefer-movmsk-over-vtest,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,serialize,sha,shstk,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vaes,vpclmulqdq,vzeroupper,waitpkg,widekl,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("amdfam10"), str_lit("3dnow,3dnowa,64bit,64bit-mode,cmov,cx16,cx8,fast-scalar-shift-masks,fxsr,lzcnt,mmx,nopl,popcnt,prfchw,sahf,sbb-dep-breaking,slow-shld,sse,sse2,sse3,sse4a,vzeroupper,x87") },
	{ str_lit("athlon"), str_lit("3dnow,3dnowa,64bit-mode,cmov,cx8,mmx,nopl,slow-shld,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("athlon-4"), str_lit("3dnow,3dnowa,64bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-shld,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("athlon-fx"), str_lit("3dnow,3dnowa,64bit,64bit-mode,cmov,cx8,fast-scalar-shift-masks,fxsr,mmx,nopl,sbb-dep-breaking,slow-shld,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("athlon-mp"), str_lit("3dnow,3dnowa,64bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-shld,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("athlon-tbird"), str_lit("3dnow,3dnowa,64bit-mode,cmov,cx8,mmx,nopl,slow-shld,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("athlon-xp"), str_lit("3dnow,3dnowa,64bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-shld,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("athlon64"), str_lit("3dnow,3dnowa,64bit,64bit-mode,cmov,cx8,fast-scalar-shift-masks,fxsr,mmx,nopl,sbb-dep-breaking,slow-shld,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("athlon64-sse3"), str_lit("3dnow,3dnowa,64bit,64bit-mode,cmov,cx16,cx8,fast-scalar-shift-masks,fxsr,mmx,nopl,sbb-dep-breaking,slow-shld,slow-unaligned-mem-16,sse,sse2,sse3,vzeroupper,x87") },
	{ str_lit("atom"), str_lit("64bit,64bit-mode,cmov,cx16,cx8,fxsr,idivl-to-divb,idivq-to-divl,lea-sp,lea-uses-ag,mmx,movbe,no-bypass-delay,nopl,pad-short-functions,sahf,slow-two-mem-ops,slow-unaligned-mem-16,sse,sse2,sse3,ssse3,vzeroupper,x87") },
	{ str_lit("atom_sse4_2"), str_lit("64bit,64bit-mode,cmov,crc32,cx16,cx8,false-deps-popcnt,fast-7bytenop,fast-movbe,fxsr,idivq-to-divl,mmx,movbe,no-bypass-delay,nopl,pclmul,popcnt,prfchw,rdrnd,sahf,slow-incdec,slow-lea,slow-pmulld,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,use-slm-arith-costs,vzeroupper,x87") },
	{ str_lit("atom_sse4_2_movbe"), str_lit("64bit,64bit-mode,aes,clflushopt,cmov,crc32,cx16,cx8,false-deps-popcnt,fast-7bytenop,fast-movbe,fsgsbase,fxsr,idivq-to-divl,mmx,movbe,no-bypass-delay,nopl,pclmul,popcnt,prfchw,rdrnd,rdseed,sahf,sha,slow-incdec,slow-lea,slow-pmulld,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,use-slm-arith-costs,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("barcelona"), str_lit("3dnow,3dnowa,64bit,64bit-mode,cmov,cx16,cx8,fast-scalar-shift-masks,fxsr,lzcnt,mmx,nopl,popcnt,prfchw,sahf,sbb-dep-breaking,slow-shld,sse,sse2,sse3,sse4a,vzeroupper,x87") },
	{ str_lit("bdver1"), str_lit("64bit,64bit-mode,aes,avx,branchfusion,cmov,crc32,cx16,cx8,fast-11bytenop,fast-scalar-shift-masks,fma4,fxsr,lwp,lzcnt,mmx,nopl,pclmul,popcnt,prfchw,sahf,sbb-dep-breaking,slow-shld,sse,sse2,sse3,sse4.1,sse4.2,sse4a,ssse3,vzeroupper,x87,xop,xsave") },
	{ str_lit("bdver2"), str_lit("64bit,64bit-mode,aes,avx,bmi,branchfusion,cmov,crc32,cx16,cx8,f16c,fast-11bytenop,fast-bextr,fast-movbe,fast-scalar-shift-masks,fma,fma4,fxsr,lwp,lzcnt,mmx,nopl,pclmul,popcnt,prfchw,sahf,sbb-dep-breaking,slow-shld,sse,sse2,sse3,sse4.1,sse4.2,sse4a,ssse3,tbm,vzeroupper,x87,xop,xsave") },
	{ str_lit("bdver3"), str_lit("64bit,64bit-mode,aes,avx,bmi,branchfusion,cmov,crc32,cx16,cx8,f16c,fast-11bytenop,fast-bextr,fast-movbe,fast-scalar-shift-masks,fma,fma4,fsgsbase,fxsr,lwp,lzcnt,mmx,nopl,pclmul,popcnt,prfchw,sahf,sbb-dep-breaking,slow-shld,sse,sse2,sse3,sse4.1,sse4.2,sse4a,ssse3,tbm,vzeroupper,x87,xop,xsave,xsaveopt") },
	{ str_lit("bdver4"), str_lit("64bit,64bit-mode,aes,avx,avx2,bmi,bmi2,branchfusion,cmov,crc32,cx16,cx8,f16c,fast-11bytenop,fast-bextr,fast-movbe,fast-scalar-shift-masks,fma,fma4,fsgsbase,fxsr,lwp,lzcnt,mmx,movbe,mwaitx,nopl,pclmul,popcnt,prfchw,rdrnd,sahf,sbb-dep-breaking,slow-shld,sse,sse2,sse3,sse4.1,sse4.2,sse4a,ssse3,tbm,vzeroupper,x87,xop,xsave,xsaveopt") },
	{ str_lit("bonnell"), str_lit("64bit,64bit-mode,cmov,cx16,cx8,fxsr,idivl-to-divb,idivq-to-divl,lea-sp,lea-uses-ag,mmx,movbe,no-bypass-delay,nopl,pad-short-functions,sahf,slow-two-mem-ops,slow-unaligned-mem-16,sse,sse2,sse3,ssse3,vzeroupper,x87") },
	{ str_lit("broadwell"), str_lit("64bit,64bit-mode,adx,allow-light-256-bit,avx,avx2,bmi,bmi2,cmov,crc32,cx16,cx8,ermsb,f16c,false-deps-lzcnt-tzcnt,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,popcnt,prfchw,rdrnd,rdseed,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("btver1"), str_lit("64bit,64bit-mode,cmov,cx16,cx8,fast-15bytenop,fast-scalar-shift-masks,fast-vector-shift-masks,fxsr,lzcnt,mmx,nopl,popcnt,prfchw,sahf,sbb-dep-breaking,slow-shld,sse,sse2,sse3,sse4a,ssse3,vzeroupper,x87") },
	{ str_lit("btver2"), str_lit("64bit,64bit-mode,aes,avx,bmi,cmov,crc32,cx16,cx8,f16c,fast-15bytenop,fast-bextr,fast-hops,fast-lzcnt,fast-movbe,fast-scalar-shift-masks,fast-vector-shift-masks,fxsr,lzcnt,mmx,movbe,nopl,pclmul,popcnt,prfchw,sahf,sbb-dep-breaking,slow-shld,sse,sse2,sse3,sse4.1,sse4.2,sse4a,ssse3,x87,xsave,xsaveopt") },
	{ str_lit("c3"), str_lit("3dnow,64bit-mode,mmx,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("c3-2"), str_lit("64bit-mode,cmov,cx8,fxsr,mmx,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("cannonlake"), str_lit("64bit,64bit-mode,adx,aes,allow-light-256-bit,avx,avx2,avx512bw,avx512cd,avx512dq,avx512f,avx512ifma,avx512vbmi,avx512vl,bmi,bmi2,clflushopt,cmov,crc32,cx16,cx8,ermsb,evex512,f16c,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pku,popcnt,prefer-256-bit,prfchw,rdrnd,rdseed,sahf,sha,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("cascadelake"), str_lit("64bit,64bit-mode,adx,aes,allow-light-256-bit,avx,avx2,avx512bw,avx512cd,avx512dq,avx512f,avx512vl,avx512vnni,bmi,bmi2,clflushopt,clwb,cmov,crc32,cx16,cx8,ermsb,evex512,f16c,false-deps-popcnt,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,faster-shift-than-shuffle,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pku,popcnt,prefer-256-bit,prfchw,rdrnd,rdseed,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("cooperlake"), str_lit("64bit,64bit-mode,adx,aes,allow-light-256-bit,avx,avx2,avx512bf16,avx512bw,avx512cd,avx512dq,avx512f,avx512vl,avx512vnni,bmi,bmi2,clflushopt,clwb,cmov,crc32,cx16,cx8,ermsb,evex512,f16c,false-deps-popcnt,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,faster-shift-than-shuffle,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pku,popcnt,prefer-256-bit,prfchw,rdrnd,rdseed,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("core-avx-i"), str_lit("64bit,64bit-mode,avx,cmov,crc32,cx16,cx8,f16c,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fsgsbase,fxsr,idivq-to-divl,macrofusion,mmx,no-bypass-delay-mov,nopl,pclmul,popcnt,rdrnd,sahf,slow-3ops-lea,slow-unaligned-mem-32,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("core-avx2"), str_lit("64bit,64bit-mode,allow-light-256-bit,avx,avx2,bmi,bmi2,cmov,crc32,cx16,cx8,ermsb,f16c,false-deps-lzcnt-tzcnt,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,popcnt,rdrnd,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("core2"), str_lit("64bit,64bit-mode,cmov,cx16,cx8,fxsr,macrofusion,mmx,nopl,sahf,slow-unaligned-mem-16,sse,sse2,sse3,ssse3,vzeroupper,x87") },
	{ str_lit("core_2_duo_sse4_1"), str_lit("64bit,64bit-mode,cmov,cx16,cx8,fxsr,macrofusion,mmx,nopl,sahf,slow-unaligned-mem-16,sse,sse2,sse3,sse4.1,ssse3,vzeroupper,x87") },
	{ str_lit("core_2_duo_ssse3"), str_lit("64bit,64bit-mode,cmov,cx16,cx8,fxsr,macrofusion,mmx,nopl,sahf,slow-unaligned-mem-16,sse,sse2,sse3,ssse3,vzeroupper,x87") },
	{ str_lit("core_2nd_gen_avx"), str_lit("64bit,64bit-mode,avx,cmov,crc32,cx16,cx8,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fxsr,idivq-to-divl,macrofusion,mmx,no-bypass-delay-mov,nopl,pclmul,popcnt,sahf,slow-3ops-lea,slow-unaligned-mem-32,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("core_3rd_gen_avx"), str_lit("64bit,64bit-mode,avx,cmov,crc32,cx16,cx8,f16c,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fsgsbase,fxsr,idivq-to-divl,macrofusion,mmx,no-bypass-delay-mov,nopl,pclmul,popcnt,rdrnd,sahf,slow-3ops-lea,slow-unaligned-mem-32,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("core_4th_gen_avx"), str_lit("64bit,64bit-mode,allow-light-256-bit,avx,avx2,bmi,bmi2,cmov,crc32,cx16,cx8,ermsb,f16c,false-deps-lzcnt-tzcnt,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,popcnt,rdrnd,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("core_4th_gen_avx_tsx"), str_lit("64bit,64bit-mode,allow-light-256-bit,avx,avx2,bmi,bmi2,cmov,crc32,cx16,cx8,ermsb,f16c,false-deps-lzcnt-tzcnt,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,popcnt,rdrnd,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("core_5th_gen_avx"), str_lit("64bit,64bit-mode,adx,allow-light-256-bit,avx,avx2,bmi,bmi2,cmov,crc32,cx16,cx8,ermsb,f16c,false-deps-lzcnt-tzcnt,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,popcnt,prfchw,rdrnd,rdseed,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("core_5th_gen_avx_tsx"), str_lit("64bit,64bit-mode,adx,allow-light-256-bit,avx,avx2,bmi,bmi2,cmov,crc32,cx16,cx8,ermsb,f16c,false-deps-lzcnt-tzcnt,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,popcnt,prfchw,rdrnd,rdseed,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("core_aes_pclmulqdq"), str_lit("64bit,64bit-mode,cmov,crc32,cx16,cx8,fxsr,macrofusion,mmx,no-bypass-delay-mov,nopl,pclmul,popcnt,sahf,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87") },
	{ str_lit("core_i7_sse4_2"), str_lit("64bit,64bit-mode,cmov,crc32,cx16,cx8,fxsr,macrofusion,mmx,no-bypass-delay-mov,nopl,popcnt,sahf,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87") },
	{ str_lit("corei7"), str_lit("64bit,64bit-mode,cmov,crc32,cx16,cx8,fxsr,macrofusion,mmx,no-bypass-delay-mov,nopl,popcnt,sahf,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87") },
	{ str_lit("corei7-avx"), str_lit("64bit,64bit-mode,avx,cmov,crc32,cx16,cx8,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fxsr,idivq-to-divl,macrofusion,mmx,no-bypass-delay-mov,nopl,pclmul,popcnt,sahf,slow-3ops-lea,slow-unaligned-mem-32,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("emeraldrapids"), str_lit("64bit,64bit-mode,adx,aes,allow-light-256-bit,amx-bf16,amx-int8,amx-tile,avx,avx2,avx512bf16,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512f,avx512fp16,avx512ifma,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vpopcntdq,avxvnni,bmi,bmi2,cldemote,clflushopt,clwb,cmov,crc32,cx16,cx8,enqcmd,ermsb,evex512,f16c,false-deps-getmant,false-deps-mulc,false-deps-mullq,false-deps-perm,false-deps-range,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,gfni,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,movdir64b,movdiri,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pconfig,pku,popcnt,prefer-256-bit,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,serialize,sha,shstk,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tsxldtrk,tuning-fast-imm-vector-shift,uintr,vaes,vpclmulqdq,vzeroupper,waitpkg,wbnoinvd,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("generic"), str_lit("64bit,64bit-mode,cx8,fast-15bytenop,fast-scalar-fsqrt,idivq-to-divl,macrofusion,slow-3ops-lea,sse,sse2,vzeroupper,x87") },
	{ str_lit("geode"), str_lit("3dnow,3dnowa,64bit-mode,cx8,mmx,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("goldmont"), str_lit("64bit,64bit-mode,aes,clflushopt,cmov,crc32,cx16,cx8,false-deps-popcnt,fast-movbe,fsgsbase,fxsr,mmx,movbe,no-bypass-delay,nopl,pclmul,popcnt,prfchw,rdrnd,rdseed,sahf,sha,slow-incdec,slow-lea,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,use-glm-div-sqrt-costs,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("goldmont-plus"), str_lit("64bit,64bit-mode,aes,clflushopt,cmov,crc32,cx16,cx8,fast-movbe,fsgsbase,fxsr,mmx,movbe,no-bypass-delay,nopl,pclmul,popcnt,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,sha,slow-incdec,slow-lea,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,use-glm-div-sqrt-costs,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("goldmont_plus"), str_lit("64bit,64bit-mode,aes,clflushopt,cmov,crc32,cx16,cx8,fast-movbe,fsgsbase,fxsr,mmx,movbe,no-bypass-delay,nopl,pclmul,popcnt,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,sha,slow-incdec,slow-lea,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,use-glm-div-sqrt-costs,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("grandridge"), str_lit("64bit,64bit-mode,adx,aes,avx,avx2,avxifma,avxneconvert,avxvnni,avxvnniint8,bmi,bmi2,cldemote,clflushopt,clwb,cmov,cmpccxadd,crc32,cx16,cx8,enqcmd,f16c,fast-movbe,fma,fsgsbase,fxsr,gfni,hreset,invpcid,kl,lzcnt,mmx,movbe,movdir64b,movdiri,no-bypass-delay,nopl,pclmul,pconfig,pku,popcnt,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,serialize,sha,shstk,slow-incdec,slow-lea,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,uintr,use-glm-div-sqrt-costs,vaes,vpclmulqdq,vzeroupper,waitpkg,widekl,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("graniterapids"), str_lit("64bit,64bit-mode,adx,aes,allow-light-256-bit,amx-bf16,amx-fp16,amx-int8,amx-tile,avx,avx2,avx512bf16,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512f,avx512fp16,avx512ifma,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vpopcntdq,avxvnni,bmi,bmi2,cldemote,clflushopt,clwb,cmov,crc32,cx16,cx8,enqcmd,ermsb,evex512,f16c,false-deps-getmant,false-deps-mulc,false-deps-mullq,false-deps-perm,false-deps-range,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,gfni,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,movdir64b,movdiri,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pconfig,pku,popcnt,prefer-256-bit,prefetchi,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,serialize,sha,shstk,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tsxldtrk,tuning-fast-imm-vector-shift,uintr,vaes,vpclmulqdq,vzeroupper,waitpkg,wbnoinvd,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("graniterapids-d"), str_lit("64bit,64bit-mode,adx,aes,allow-light-256-bit,amx-bf16,amx-complex,amx-fp16,amx-int8,amx-tile,avx,avx2,avx512bf16,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512f,avx512fp16,avx512ifma,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vpopcntdq,avxvnni,bmi,bmi2,cldemote,clflushopt,clwb,cmov,crc32,cx16,cx8,enqcmd,ermsb,evex512,f16c,false-deps-getmant,false-deps-mulc,false-deps-mullq,false-deps-perm,false-deps-range,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,gfni,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,movdir64b,movdiri,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pconfig,pku,popcnt,prefer-256-bit,prefetchi,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,serialize,sha,shstk,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tsxldtrk,tuning-fast-imm-vector-shift,uintr,vaes,vpclmulqdq,vzeroupper,waitpkg,wbnoinvd,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("graniterapids_d"), str_lit("64bit,64bit-mode,adx,aes,allow-light-256-bit,amx-bf16,amx-complex,amx-fp16,amx-int8,amx-tile,avx,avx2,avx512bf16,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512f,avx512fp16,avx512ifma,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vpopcntdq,avxvnni,bmi,bmi2,cldemote,clflushopt,clwb,cmov,crc32,cx16,cx8,enqcmd,ermsb,evex512,f16c,false-deps-getmant,false-deps-mulc,false-deps-mullq,false-deps-perm,false-deps-range,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,gfni,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,movdir64b,movdiri,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pconfig,pku,popcnt,prefer-256-bit,prefetchi,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,serialize,sha,shstk,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tsxldtrk,tuning-fast-imm-vector-shift,uintr,vaes,vpclmulqdq,vzeroupper,waitpkg,wbnoinvd,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("haswell"), str_lit("64bit,64bit-mode,allow-light-256-bit,avx,avx2,bmi,bmi2,cmov,crc32,cx16,cx8,ermsb,f16c,false-deps-lzcnt-tzcnt,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,popcnt,rdrnd,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("i386"), str_lit("64bit-mode,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("i486"), str_lit("64bit-mode,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("i586"), str_lit("64bit-mode,cx8,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("i686"), str_lit("64bit-mode,cmov,cx8,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("icelake-client"), str_lit("64bit,64bit-mode,adx,aes,allow-light-256-bit,avx,avx2,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512f,avx512ifma,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vpopcntdq,bmi,bmi2,clflushopt,cmov,crc32,cx16,cx8,ermsb,evex512,f16c,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,gfni,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pku,popcnt,prefer-256-bit,prfchw,rdpid,rdrnd,rdseed,sahf,sha,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vaes,vpclmulqdq,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("icelake-server"), str_lit("64bit,64bit-mode,adx,aes,allow-light-256-bit,avx,avx2,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512f,avx512ifma,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vpopcntdq,bmi,bmi2,clflushopt,clwb,cmov,crc32,cx16,cx8,ermsb,evex512,f16c,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,gfni,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pconfig,pku,popcnt,prefer-256-bit,prfchw,rdpid,rdrnd,rdseed,sahf,sha,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vaes,vpclmulqdq,vzeroupper,wbnoinvd,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("icelake_client"), str_lit("64bit,64bit-mode,adx,aes,allow-light-256-bit,avx,avx2,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512f,avx512ifma,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vpopcntdq,bmi,bmi2,clflushopt,cmov,crc32,cx16,cx8,ermsb,evex512,f16c,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,gfni,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pku,popcnt,prefer-256-bit,prfchw,rdpid,rdrnd,rdseed,sahf,sha,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vaes,vpclmulqdq,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("icelake_server"), str_lit("64bit,64bit-mode,adx,aes,allow-light-256-bit,avx,avx2,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512f,avx512ifma,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vpopcntdq,bmi,bmi2,clflushopt,clwb,cmov,crc32,cx16,cx8,ermsb,evex512,f16c,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,gfni,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pconfig,pku,popcnt,prefer-256-bit,prfchw,rdpid,rdrnd,rdseed,sahf,sha,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vaes,vpclmulqdq,vzeroupper,wbnoinvd,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("ivybridge"), str_lit("64bit,64bit-mode,avx,cmov,crc32,cx16,cx8,f16c,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fsgsbase,fxsr,idivq-to-divl,macrofusion,mmx,no-bypass-delay-mov,nopl,pclmul,popcnt,rdrnd,sahf,slow-3ops-lea,slow-unaligned-mem-32,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("k6"), str_lit("64bit-mode,cx8,mmx,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("k6-2"), str_lit("3dnow,64bit-mode,cx8,mmx,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("k6-3"), str_lit("3dnow,64bit-mode,cx8,mmx,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("k8"), str_lit("3dnow,3dnowa,64bit,64bit-mode,cmov,cx8,fast-scalar-shift-masks,fxsr,mmx,nopl,sbb-dep-breaking,slow-shld,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("k8-sse3"), str_lit("3dnow,3dnowa,64bit,64bit-mode,cmov,cx16,cx8,fast-scalar-shift-masks,fxsr,mmx,nopl,sbb-dep-breaking,slow-shld,slow-unaligned-mem-16,sse,sse2,sse3,vzeroupper,x87") },
	{ str_lit("knl"), str_lit("64bit,64bit-mode,adx,aes,avx,avx2,avx512cd,avx512er,avx512f,avx512pf,bmi,bmi2,cmov,crc32,cx16,cx8,evex512,f16c,fast-gather,fast-movbe,fma,fsgsbase,fxsr,idivq-to-divl,lzcnt,mmx,movbe,nopl,pclmul,popcnt,prefer-mask-registers,prefetchwt1,prfchw,rdrnd,rdseed,sahf,slow-3ops-lea,slow-incdec,slow-pmaddwd,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,x87,xsave,xsaveopt") },
	{ str_lit("knm"), str_lit("64bit,64bit-mode,adx,aes,avx,avx2,avx512cd,avx512er,avx512f,avx512pf,avx512vpopcntdq,bmi,bmi2,cmov,crc32,cx16,cx8,evex512,f16c,fast-gather,fast-movbe,fma,fsgsbase,fxsr,idivq-to-divl,lzcnt,mmx,movbe,nopl,pclmul,popcnt,prefer-mask-registers,prefetchwt1,prfchw,rdrnd,rdseed,sahf,slow-3ops-lea,slow-incdec,slow-pmaddwd,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,x87,xsave,xsaveopt") },
	{ str_lit("lakemont"), str_lit("64bit-mode,cx8,slow-unaligned-mem-16,sse,sse2,vzeroupper") },
	{ str_lit("meteorlake"), str_lit("64bit,64bit-mode,adx,aes,allow-light-256-bit,avx,avx2,avxvnni,bmi,bmi2,cldemote,clflushopt,clwb,cmov,crc32,cx16,cx8,f16c,false-deps-perm,false-deps-popcnt,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fxsr,gfni,hreset,idivq-to-divl,invpcid,kl,lzcnt,macrofusion,mmx,movbe,movdir64b,movdiri,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pconfig,pku,popcnt,prefer-movmsk-over-vtest,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,serialize,sha,shstk,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vaes,vpclmulqdq,vzeroupper,waitpkg,widekl,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("mic_avx512"), str_lit("64bit,64bit-mode,adx,aes,avx,avx2,avx512cd,avx512er,avx512f,avx512pf,bmi,bmi2,cmov,crc32,cx16,cx8,evex512,f16c,fast-gather,fast-movbe,fma,fsgsbase,fxsr,idivq-to-divl,lzcnt,mmx,movbe,nopl,pclmul,popcnt,prefer-mask-registers,prefetchwt1,prfchw,rdrnd,rdseed,sahf,slow-3ops-lea,slow-incdec,slow-pmaddwd,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,x87,xsave,xsaveopt") },
	{ str_lit("nehalem"), str_lit("64bit,64bit-mode,cmov,crc32,cx16,cx8,fxsr,macrofusion,mmx,no-bypass-delay-mov,nopl,popcnt,sahf,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87") },
	{ str_lit("nocona"), str_lit("64bit,64bit-mode,cmov,cx16,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,sse2,sse3,vzeroupper,x87") },
	{ str_lit("opteron"), str_lit("3dnow,3dnowa,64bit,64bit-mode,cmov,cx8,fast-scalar-shift-masks,fxsr,mmx,nopl,sbb-dep-breaking,slow-shld,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("opteron-sse3"), str_lit("3dnow,3dnowa,64bit,64bit-mode,cmov,cx16,cx8,fast-scalar-shift-masks,fxsr,mmx,nopl,sbb-dep-breaking,slow-shld,slow-unaligned-mem-16,sse,sse2,sse3,vzeroupper,x87") },
	{ str_lit("penryn"), str_lit("64bit,64bit-mode,cmov,cx16,cx8,fxsr,macrofusion,mmx,nopl,sahf,slow-unaligned-mem-16,sse,sse2,sse3,sse4.1,ssse3,vzeroupper,x87") },
	{ str_lit("pentium"), str_lit("64bit-mode,cx8,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("pentium-m"), str_lit("64bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("pentium-mmx"), str_lit("64bit-mode,cx8,mmx,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("pentium2"), str_lit("64bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("pentium3"), str_lit("64bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("pentium3m"), str_lit("64bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("pentium4"), str_lit("64bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("pentium4m"), str_lit("64bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("pentium_4"), str_lit("64bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("pentium_4_sse3"), str_lit("64bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,sse2,sse3,vzeroupper,x87") },
	{ str_lit("pentium_ii"), str_lit("64bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("pentium_iii"), str_lit("64bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("pentium_iii_no_xmm_regs"), str_lit("64bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("pentium_m"), str_lit("64bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("pentium_mmx"), str_lit("64bit-mode,cx8,mmx,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("pentium_pro"), str_lit("64bit-mode,cmov,cx8,nopl,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("pentiumpro"), str_lit("64bit-mode,cmov,cx8,nopl,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("prescott"), str_lit("64bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,sse2,sse3,vzeroupper,x87") },
	{ str_lit("raptorlake"), str_lit("64bit,64bit-mode,adx,aes,allow-light-256-bit,avx,avx2,avxvnni,bmi,bmi2,cldemote,clflushopt,clwb,cmov,crc32,cx16,cx8,f16c,false-deps-perm,false-deps-popcnt,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fxsr,gfni,hreset,idivq-to-divl,invpcid,kl,lzcnt,macrofusion,mmx,movbe,movdir64b,movdiri,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pconfig,pku,popcnt,prefer-movmsk-over-vtest,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,serialize,sha,shstk,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vaes,vpclmulqdq,vzeroupper,waitpkg,widekl,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("rocketlake"), str_lit("64bit,64bit-mode,adx,aes,allow-light-256-bit,avx,avx2,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512f,avx512ifma,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vpopcntdq,bmi,bmi2,clflushopt,cmov,crc32,cx16,cx8,ermsb,evex512,f16c,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,gfni,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pku,popcnt,prefer-256-bit,prfchw,rdpid,rdrnd,rdseed,sahf,sha,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vaes,vpclmulqdq,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("sandybridge"), str_lit("64bit,64bit-mode,avx,cmov,crc32,cx16,cx8,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fxsr,idivq-to-divl,macrofusion,mmx,no-bypass-delay-mov,nopl,pclmul,popcnt,sahf,slow-3ops-lea,slow-unaligned-mem-32,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("sapphirerapids"), str_lit("64bit,64bit-mode,adx,aes,allow-light-256-bit,amx-bf16,amx-int8,amx-tile,avx,avx2,avx512bf16,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512f,avx512fp16,avx512ifma,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vpopcntdq,avxvnni,bmi,bmi2,cldemote,clflushopt,clwb,cmov,crc32,cx16,cx8,enqcmd,ermsb,evex512,f16c,false-deps-getmant,false-deps-mulc,false-deps-mullq,false-deps-perm,false-deps-range,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,gfni,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,movdir64b,movdiri,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pconfig,pku,popcnt,prefer-256-bit,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,serialize,sha,shstk,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tsxldtrk,tuning-fast-imm-vector-shift,uintr,vaes,vpclmulqdq,vzeroupper,waitpkg,wbnoinvd,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("sierraforest"), str_lit("64bit,64bit-mode,adx,aes,avx,avx2,avxifma,avxneconvert,avxvnni,avxvnniint8,bmi,bmi2,cldemote,clflushopt,clwb,cmov,cmpccxadd,crc32,cx16,cx8,enqcmd,f16c,fast-movbe,fma,fsgsbase,fxsr,gfni,hreset,invpcid,kl,lzcnt,mmx,movbe,movdir64b,movdiri,no-bypass-delay,nopl,pclmul,pconfig,pku,popcnt,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,serialize,sha,shstk,slow-incdec,slow-lea,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,uintr,use-glm-div-sqrt-costs,vaes,vpclmulqdq,vzeroupper,waitpkg,widekl,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("silvermont"), str_lit("64bit,64bit-mode,cmov,crc32,cx16,cx8,false-deps-popcnt,fast-7bytenop,fast-movbe,fxsr,idivq-to-divl,mmx,movbe,no-bypass-delay,nopl,pclmul,popcnt,prfchw,rdrnd,sahf,slow-incdec,slow-lea,slow-pmulld,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,use-slm-arith-costs,vzeroupper,x87") },
	{ str_lit("skx"), str_lit("64bit,64bit-mode,adx,aes,allow-light-256-bit,avx,avx2,avx512bw,avx512cd,avx512dq,avx512f,avx512vl,bmi,bmi2,clflushopt,clwb,cmov,crc32,cx16,cx8,ermsb,evex512,f16c,false-deps-popcnt,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,faster-shift-than-shuffle,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pku,popcnt,prefer-256-bit,prfchw,rdrnd,rdseed,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("skylake"), str_lit("64bit,64bit-mode,adx,aes,allow-light-256-bit,avx,avx2,bmi,bmi2,clflushopt,cmov,crc32,cx16,cx8,ermsb,f16c,false-deps-popcnt,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,popcnt,prfchw,rdrnd,rdseed,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("skylake-avx512"), str_lit("64bit,64bit-mode,adx,aes,allow-light-256-bit,avx,avx2,avx512bw,avx512cd,avx512dq,avx512f,avx512vl,bmi,bmi2,clflushopt,clwb,cmov,crc32,cx16,cx8,ermsb,evex512,f16c,false-deps-popcnt,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,faster-shift-than-shuffle,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pku,popcnt,prefer-256-bit,prfchw,rdrnd,rdseed,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("skylake_avx512"), str_lit("64bit,64bit-mode,adx,aes,allow-light-256-bit,avx,avx2,avx512bw,avx512cd,avx512dq,avx512f,avx512vl,bmi,bmi2,clflushopt,clwb,cmov,crc32,cx16,cx8,ermsb,evex512,f16c,false-deps-popcnt,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,faster-shift-than-shuffle,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pku,popcnt,prefer-256-bit,prfchw,rdrnd,rdseed,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("slm"), str_lit("64bit,64bit-mode,cmov,crc32,cx16,cx8,false-deps-popcnt,fast-7bytenop,fast-movbe,fxsr,idivq-to-divl,mmx,movbe,no-bypass-delay,nopl,pclmul,popcnt,prfchw,rdrnd,sahf,slow-incdec,slow-lea,slow-pmulld,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,use-slm-arith-costs,vzeroupper,x87") },
	{ str_lit("tigerlake"), str_lit("64bit,64bit-mode,adx,aes,allow-light-256-bit,avx,avx2,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512f,avx512ifma,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vp2intersect,avx512vpopcntdq,bmi,bmi2,clflushopt,clwb,cmov,crc32,cx16,cx8,ermsb,evex512,f16c,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,gfni,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,movdir64b,movdiri,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pku,popcnt,prefer-256-bit,prfchw,rdpid,rdrnd,rdseed,sahf,sha,shstk,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vaes,vpclmulqdq,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("tremont"), str_lit("64bit,64bit-mode,aes,clflushopt,clwb,cmov,crc32,cx16,cx8,fast-movbe,fsgsbase,fxsr,gfni,mmx,movbe,no-bypass-delay,nopl,pclmul,popcnt,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,sha,slow-incdec,slow-lea,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,use-glm-div-sqrt-costs,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("westmere"), str_lit("64bit,64bit-mode,cmov,crc32,cx16,cx8,fxsr,macrofusion,mmx,no-bypass-delay-mov,nopl,pclmul,popcnt,sahf,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87") },
	{ str_lit("winchip-c6"), str_lit("64bit-mode,mmx,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("winchip2"), str_lit("3dnow,64bit-mode,mmx,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("x86-64"), str_lit("64bit,64bit-mode,cmov,cx8,fxsr,idivq-to-divl,macrofusion,mmx,nopl,slow-3ops-lea,slow-incdec,sse,sse2,vzeroupper,x87") },
	{ str_lit("x86-64-v2"), str_lit("64bit,64bit-mode,cmov,crc32,cx16,cx8,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fxsr,idivq-to-divl,macrofusion,mmx,nopl,popcnt,sahf,slow-3ops-lea,slow-unaligned-mem-32,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87") },
	{ str_lit("x86-64-v3"), str_lit("64bit,64bit-mode,allow-light-256-bit,avx,avx2,bmi,bmi2,cmov,crc32,cx16,cx8,f16c,false-deps-lzcnt-tzcnt,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fma,fxsr,idivq-to-divl,lzcnt,macrofusion,mmx,movbe,nopl,popcnt,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave") },
	{ str_lit("x86-64-v4"), str_lit("64bit,64bit-mode,allow-light-256-bit,avx,avx2,avx512bw,avx512cd,avx512dq,avx512f,avx512vl,bmi,bmi2,cmov,crc32,cx16,cx8,evex512,f16c,false-deps-popcnt,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fxsr,idivq-to-divl,lzcnt,macrofusion,mmx,movbe,nopl,popcnt,prefer-256-bit,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave") },
	{ str_lit("yonah"), str_lit("64bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,sse2,sse3,vzeroupper,x87") },
	{ str_lit("znver1"), str_lit("64bit,64bit-mode,adx,aes,allow-light-256-bit,avx,avx2,bmi,bmi2,branchfusion,clflushopt,clzero,cmov,crc32,cx16,cx8,f16c,fast-15bytenop,fast-bextr,fast-lzcnt,fast-movbe,fast-scalar-fsqrt,fast-scalar-shift-masks,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fxsr,lzcnt,mmx,movbe,mwaitx,nopl,pclmul,popcnt,prfchw,rdrnd,rdseed,sahf,sbb-dep-breaking,sha,slow-shld,sse,sse2,sse3,sse4.1,sse4.2,sse4a,ssse3,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("znver2"), str_lit("64bit,64bit-mode,adx,aes,allow-light-256-bit,avx,avx2,bmi,bmi2,branchfusion,clflushopt,clwb,clzero,cmov,crc32,cx16,cx8,f16c,fast-15bytenop,fast-bextr,fast-lzcnt,fast-movbe,fast-scalar-fsqrt,fast-scalar-shift-masks,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fxsr,lzcnt,mmx,movbe,mwaitx,nopl,pclmul,popcnt,prfchw,rdpid,rdpru,rdrnd,rdseed,sahf,sbb-dep-breaking,sha,slow-shld,sse,sse2,sse3,sse4.1,sse4.2,sse4a,ssse3,vzeroupper,wbnoinvd,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("znver3"), str_lit("64bit,64bit-mode,adx,aes,allow-light-256-bit,avx,avx2,bmi,bmi2,branchfusion,clflushopt,clwb,clzero,cmov,crc32,cx16,cx8,f16c,fast-15bytenop,fast-bextr,fast-lzcnt,fast-movbe,fast-scalar-fsqrt,fast-scalar-shift-masks,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,invpcid,lzcnt,macrofusion,mmx,movbe,mwaitx,nopl,pclmul,pku,popcnt,prfchw,rdpid,rdpru,rdrnd,rdseed,sahf,sbb-dep-breaking,sha,slow-shld,sse,sse2,sse3,sse4.1,sse4.2,sse4a,ssse3,vaes,vpclmulqdq,vzeroupper,wbnoinvd,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("znver4"), str_lit("64bit,64bit-mode,adx,aes,allow-light-256-bit,avx,avx2,avx512bf16,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512f,avx512ifma,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vpopcntdq,bmi,bmi2,branchfusion,clflushopt,clwb,clzero,cmov,crc32,cx16,cx8,evex512,f16c,fast-15bytenop,fast-bextr,fast-lzcnt,fast-movbe,fast-scalar-fsqrt,fast-scalar-shift-masks,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,gfni,invpcid,lzcnt,macrofusion,mmx,movbe,mwaitx,nopl,pclmul,pku,popcnt,prfchw,rdpid,rdpru,rdrnd,rdseed,sahf,sbb-dep-breaking,sha,shstk,slow-shld,sse,sse2,sse3,sse4.1,sse4.2,sse4a,ssse3,vaes,vpclmulqdq,vzeroupper,wbnoinvd,x87,xsave,xsavec,xsaveopt,xsaves") },
	// TargetArch_i386:
	{ str_lit("alderlake"), str_lit("32bit-mode,64bit,adx,aes,allow-light-256-bit,avx,avx2,avxvnni,bmi,bmi2,cldemote,clflushopt,clwb,cmov,crc32,cx16,cx8,f16c,false-deps-perm,false-deps-popcnt,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fxsr,gfni,hreset,idivq-to-divl,invpcid,kl,lzcnt,macrofusion,mmx,movbe,movdir64b,movdiri,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pconfig,pku,popcnt,prefer-movmsk-over-vtest,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,serialize,sha,shstk,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vaes,vpclmulqdq,vzeroupper,waitpkg,widekl,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("amdfam10"), str_lit("32bit-mode,3dnow,3dnowa,64bit,cmov,cx16,cx8,fast-scalar-shift-masks,fxsr,lzcnt,mmx,nopl,popcnt,prfchw,sahf,sbb-dep-breaking,slow-shld,sse,sse2,sse3,sse4a,vzeroupper,x87") },
	{ str_lit("athlon"), str_lit("32bit-mode,3dnow,3dnowa,cmov,cx8,mmx,nopl,slow-shld,slow-unaligned-mem-16,vzeroupper,x87") },
	{ str_lit("athlon-4"), str_lit("32bit-mode,3dnow,3dnowa,cmov,cx8,fxsr,mmx,nopl,slow-shld,slow-unaligned-mem-16,sse,vzeroupper,x87") },
	{ str_lit("athlon-fx"), str_lit("32bit-mode,3dnow,3dnowa,64bit,cmov,cx8,fast-scalar-shift-masks,fxsr,mmx,nopl,sbb-dep-breaking,slow-shld,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("athlon-mp"), str_lit("32bit-mode,3dnow,3dnowa,cmov,cx8,fxsr,mmx,nopl,slow-shld,slow-unaligned-mem-16,sse,vzeroupper,x87") },
	{ str_lit("athlon-tbird"), str_lit("32bit-mode,3dnow,3dnowa,cmov,cx8,mmx,nopl,slow-shld,slow-unaligned-mem-16,vzeroupper,x87") },
	{ str_lit("athlon-xp"), str_lit("32bit-mode,3dnow,3dnowa,cmov,cx8,fxsr,mmx,nopl,slow-shld,slow-unaligned-mem-16,sse,vzeroupper,x87") },
	{ str_lit("athlon64"), str_lit("32bit-mode,3dnow,3dnowa,64bit,cmov,cx8,fast-scalar-shift-masks,fxsr,mmx,nopl,sbb-dep-breaking,slow-shld,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("athlon64-sse3"), str_lit("32bit-mode,3dnow,3dnowa,64bit,cmov,cx16,cx8,fast-scalar-shift-masks,fxsr,mmx,nopl,sbb-dep-breaking,slow-shld,slow-unaligned-mem-16,sse,sse2,sse3,vzeroupper,x87") },
	{ str_lit("atom"), str_lit("32bit-mode,64bit,cmov,cx16,cx8,fxsr,idivl-to-divb,idivq-to-divl,lea-sp,lea-uses-ag,mmx,movbe,no-bypass-delay,nopl,pad-short-functions,sahf,slow-two-mem-ops,slow-unaligned-mem-16,sse,sse2,sse3,ssse3,vzeroupper,x87") },
	{ str_lit("atom_sse4_2"), str_lit("32bit-mode,64bit,cmov,crc32,cx16,cx8,false-deps-popcnt,fast-7bytenop,fast-movbe,fxsr,idivq-to-divl,mmx,movbe,no-bypass-delay,nopl,pclmul,popcnt,prfchw,rdrnd,sahf,slow-incdec,slow-lea,slow-pmulld,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,use-slm-arith-costs,vzeroupper,x87") },
	{ str_lit("atom_sse4_2_movbe"), str_lit("32bit-mode,64bit,aes,clflushopt,cmov,crc32,cx16,cx8,false-deps-popcnt,fast-7bytenop,fast-movbe,fsgsbase,fxsr,idivq-to-divl,mmx,movbe,no-bypass-delay,nopl,pclmul,popcnt,prfchw,rdrnd,rdseed,sahf,sha,slow-incdec,slow-lea,slow-pmulld,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,use-slm-arith-costs,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("barcelona"), str_lit("32bit-mode,3dnow,3dnowa,64bit,cmov,cx16,cx8,fast-scalar-shift-masks,fxsr,lzcnt,mmx,nopl,popcnt,prfchw,sahf,sbb-dep-breaking,slow-shld,sse,sse2,sse3,sse4a,vzeroupper,x87") },
	{ str_lit("bdver1"), str_lit("32bit-mode,64bit,aes,avx,branchfusion,cmov,crc32,cx16,cx8,fast-11bytenop,fast-scalar-shift-masks,fma4,fxsr,lwp,lzcnt,mmx,nopl,pclmul,popcnt,prfchw,sahf,sbb-dep-breaking,slow-shld,sse,sse2,sse3,sse4.1,sse4.2,sse4a,ssse3,vzeroupper,x87,xop,xsave") },
	{ str_lit("bdver2"), str_lit("32bit-mode,64bit,aes,avx,bmi,branchfusion,cmov,crc32,cx16,cx8,f16c,fast-11bytenop,fast-bextr,fast-movbe,fast-scalar-shift-masks,fma,fma4,fxsr,lwp,lzcnt,mmx,nopl,pclmul,popcnt,prfchw,sahf,sbb-dep-breaking,slow-shld,sse,sse2,sse3,sse4.1,sse4.2,sse4a,ssse3,tbm,vzeroupper,x87,xop,xsave") },
	{ str_lit("bdver3"), str_lit("32bit-mode,64bit,aes,avx,bmi,branchfusion,cmov,crc32,cx16,cx8,f16c,fast-11bytenop,fast-bextr,fast-movbe,fast-scalar-shift-masks,fma,fma4,fsgsbase,fxsr,lwp,lzcnt,mmx,nopl,pclmul,popcnt,prfchw,sahf,sbb-dep-breaking,slow-shld,sse,sse2,sse3,sse4.1,sse4.2,sse4a,ssse3,tbm,vzeroupper,x87,xop,xsave,xsaveopt") },
	{ str_lit("bdver4"), str_lit("32bit-mode,64bit,aes,avx,avx2,bmi,bmi2,branchfusion,cmov,crc32,cx16,cx8,f16c,fast-11bytenop,fast-bextr,fast-movbe,fast-scalar-shift-masks,fma,fma4,fsgsbase,fxsr,lwp,lzcnt,mmx,movbe,mwaitx,nopl,pclmul,popcnt,prfchw,rdrnd,sahf,sbb-dep-breaking,slow-shld,sse,sse2,sse3,sse4.1,sse4.2,sse4a,ssse3,tbm,vzeroupper,x87,xop,xsave,xsaveopt") },
	{ str_lit("bonnell"), str_lit("32bit-mode,64bit,cmov,cx16,cx8,fxsr,idivl-to-divb,idivq-to-divl,lea-sp,lea-uses-ag,mmx,movbe,no-bypass-delay,nopl,pad-short-functions,sahf,slow-two-mem-ops,slow-unaligned-mem-16,sse,sse2,sse3,ssse3,vzeroupper,x87") },
	{ str_lit("broadwell"), str_lit("32bit-mode,64bit,adx,allow-light-256-bit,avx,avx2,bmi,bmi2,cmov,crc32,cx16,cx8,ermsb,f16c,false-deps-lzcnt-tzcnt,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,popcnt,prfchw,rdrnd,rdseed,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("btver1"), str_lit("32bit-mode,64bit,cmov,cx16,cx8,fast-15bytenop,fast-scalar-shift-masks,fast-vector-shift-masks,fxsr,lzcnt,mmx,nopl,popcnt,prfchw,sahf,sbb-dep-breaking,slow-shld,sse,sse2,sse3,sse4a,ssse3,vzeroupper,x87") },
	{ str_lit("btver2"), str_lit("32bit-mode,64bit,aes,avx,bmi,cmov,crc32,cx16,cx8,f16c,fast-15bytenop,fast-bextr,fast-hops,fast-lzcnt,fast-movbe,fast-scalar-shift-masks,fast-vector-shift-masks,fxsr,lzcnt,mmx,movbe,nopl,pclmul,popcnt,prfchw,sahf,sbb-dep-breaking,slow-shld,sse,sse2,sse3,sse4.1,sse4.2,sse4a,ssse3,x87,xsave,xsaveopt") },
	{ str_lit("c3"), str_lit("32bit-mode,3dnow,mmx,slow-unaligned-mem-16,vzeroupper,x87") },
	{ str_lit("c3-2"), str_lit("32bit-mode,cmov,cx8,fxsr,mmx,slow-unaligned-mem-16,sse,vzeroupper,x87") },
	{ str_lit("cannonlake"), str_lit("32bit-mode,64bit,adx,aes,allow-light-256-bit,avx,avx2,avx512bw,avx512cd,avx512dq,avx512f,avx512ifma,avx512vbmi,avx512vl,bmi,bmi2,clflushopt,cmov,crc32,cx16,cx8,ermsb,evex512,f16c,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pku,popcnt,prefer-256-bit,prfchw,rdrnd,rdseed,sahf,sha,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("cascadelake"), str_lit("32bit-mode,64bit,adx,aes,allow-light-256-bit,avx,avx2,avx512bw,avx512cd,avx512dq,avx512f,avx512vl,avx512vnni,bmi,bmi2,clflushopt,clwb,cmov,crc32,cx16,cx8,ermsb,evex512,f16c,false-deps-popcnt,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,faster-shift-than-shuffle,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pku,popcnt,prefer-256-bit,prfchw,rdrnd,rdseed,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("cooperlake"), str_lit("32bit-mode,64bit,adx,aes,allow-light-256-bit,avx,avx2,avx512bf16,avx512bw,avx512cd,avx512dq,avx512f,avx512vl,avx512vnni,bmi,bmi2,clflushopt,clwb,cmov,crc32,cx16,cx8,ermsb,evex512,f16c,false-deps-popcnt,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,faster-shift-than-shuffle,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pku,popcnt,prefer-256-bit,prfchw,rdrnd,rdseed,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("core-avx-i"), str_lit("32bit-mode,64bit,avx,cmov,crc32,cx16,cx8,f16c,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fsgsbase,fxsr,idivq-to-divl,macrofusion,mmx,no-bypass-delay-mov,nopl,pclmul,popcnt,rdrnd,sahf,slow-3ops-lea,slow-unaligned-mem-32,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("core-avx2"), str_lit("32bit-mode,64bit,allow-light-256-bit,avx,avx2,bmi,bmi2,cmov,crc32,cx16,cx8,ermsb,f16c,false-deps-lzcnt-tzcnt,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,popcnt,rdrnd,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("core2"), str_lit("32bit-mode,64bit,cmov,cx16,cx8,fxsr,macrofusion,mmx,nopl,sahf,slow-unaligned-mem-16,sse,sse2,sse3,ssse3,vzeroupper,x87") },
	{ str_lit("core_2_duo_sse4_1"), str_lit("32bit-mode,64bit,cmov,cx16,cx8,fxsr,macrofusion,mmx,nopl,sahf,slow-unaligned-mem-16,sse,sse2,sse3,sse4.1,ssse3,vzeroupper,x87") },
	{ str_lit("core_2_duo_ssse3"), str_lit("32bit-mode,64bit,cmov,cx16,cx8,fxsr,macrofusion,mmx,nopl,sahf,slow-unaligned-mem-16,sse,sse2,sse3,ssse3,vzeroupper,x87") },
	{ str_lit("core_2nd_gen_avx"), str_lit("32bit-mode,64bit,avx,cmov,crc32,cx16,cx8,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fxsr,idivq-to-divl,macrofusion,mmx,no-bypass-delay-mov,nopl,pclmul,popcnt,sahf,slow-3ops-lea,slow-unaligned-mem-32,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("core_3rd_gen_avx"), str_lit("32bit-mode,64bit,avx,cmov,crc32,cx16,cx8,f16c,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fsgsbase,fxsr,idivq-to-divl,macrofusion,mmx,no-bypass-delay-mov,nopl,pclmul,popcnt,rdrnd,sahf,slow-3ops-lea,slow-unaligned-mem-32,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("core_4th_gen_avx"), str_lit("32bit-mode,64bit,allow-light-256-bit,avx,avx2,bmi,bmi2,cmov,crc32,cx16,cx8,ermsb,f16c,false-deps-lzcnt-tzcnt,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,popcnt,rdrnd,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("core_4th_gen_avx_tsx"), str_lit("32bit-mode,64bit,allow-light-256-bit,avx,avx2,bmi,bmi2,cmov,crc32,cx16,cx8,ermsb,f16c,false-deps-lzcnt-tzcnt,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,popcnt,rdrnd,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("core_5th_gen_avx"), str_lit("32bit-mode,64bit,adx,allow-light-256-bit,avx,avx2,bmi,bmi2,cmov,crc32,cx16,cx8,ermsb,f16c,false-deps-lzcnt-tzcnt,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,popcnt,prfchw,rdrnd,rdseed,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("core_5th_gen_avx_tsx"), str_lit("32bit-mode,64bit,adx,allow-light-256-bit,avx,avx2,bmi,bmi2,cmov,crc32,cx16,cx8,ermsb,f16c,false-deps-lzcnt-tzcnt,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,popcnt,prfchw,rdrnd,rdseed,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("core_aes_pclmulqdq"), str_lit("32bit-mode,64bit,cmov,crc32,cx16,cx8,fxsr,macrofusion,mmx,no-bypass-delay-mov,nopl,pclmul,popcnt,sahf,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87") },
	{ str_lit("core_i7_sse4_2"), str_lit("32bit-mode,64bit,cmov,crc32,cx16,cx8,fxsr,macrofusion,mmx,no-bypass-delay-mov,nopl,popcnt,sahf,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87") },
	{ str_lit("corei7"), str_lit("32bit-mode,64bit,cmov,crc32,cx16,cx8,fxsr,macrofusion,mmx,no-bypass-delay-mov,nopl,popcnt,sahf,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87") },
	{ str_lit("corei7-avx"), str_lit("32bit-mode,64bit,avx,cmov,crc32,cx16,cx8,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fxsr,idivq-to-divl,macrofusion,mmx,no-bypass-delay-mov,nopl,pclmul,popcnt,sahf,slow-3ops-lea,slow-unaligned-mem-32,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("emeraldrapids"), str_lit("32bit-mode,64bit,adx,aes,allow-light-256-bit,amx-bf16,amx-int8,amx-tile,avx,avx2,avx512bf16,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512f,avx512fp16,avx512ifma,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vpopcntdq,avxvnni,bmi,bmi2,cldemote,clflushopt,clwb,cmov,crc32,cx16,cx8,enqcmd,ermsb,evex512,f16c,false-deps-getmant,false-deps-mulc,false-deps-mullq,false-deps-perm,false-deps-range,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,gfni,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,movdir64b,movdiri,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pconfig,pku,popcnt,prefer-256-bit,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,serialize,sha,shstk,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tsxldtrk,tuning-fast-imm-vector-shift,uintr,vaes,vpclmulqdq,vzeroupper,waitpkg,wbnoinvd,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("generic"), str_lit("32bit-mode,64bit,cx8,fast-15bytenop,fast-scalar-fsqrt,idivq-to-divl,macrofusion,slow-3ops-lea,vzeroupper,x87") },
	{ str_lit("geode"), str_lit("32bit-mode,3dnow,3dnowa,cx8,mmx,slow-unaligned-mem-16,vzeroupper,x87") },
	{ str_lit("goldmont"), str_lit("32bit-mode,64bit,aes,clflushopt,cmov,crc32,cx16,cx8,false-deps-popcnt,fast-movbe,fsgsbase,fxsr,mmx,movbe,no-bypass-delay,nopl,pclmul,popcnt,prfchw,rdrnd,rdseed,sahf,sha,slow-incdec,slow-lea,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,use-glm-div-sqrt-costs,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("goldmont-plus"), str_lit("32bit-mode,64bit,aes,clflushopt,cmov,crc32,cx16,cx8,fast-movbe,fsgsbase,fxsr,mmx,movbe,no-bypass-delay,nopl,pclmul,popcnt,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,sha,slow-incdec,slow-lea,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,use-glm-div-sqrt-costs,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("goldmont_plus"), str_lit("32bit-mode,64bit,aes,clflushopt,cmov,crc32,cx16,cx8,fast-movbe,fsgsbase,fxsr,mmx,movbe,no-bypass-delay,nopl,pclmul,popcnt,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,sha,slow-incdec,slow-lea,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,use-glm-div-sqrt-costs,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("grandridge"), str_lit("32bit-mode,64bit,adx,aes,avx,avx2,avxifma,avxneconvert,avxvnni,avxvnniint8,bmi,bmi2,cldemote,clflushopt,clwb,cmov,cmpccxadd,crc32,cx16,cx8,enqcmd,f16c,fast-movbe,fma,fsgsbase,fxsr,gfni,hreset,invpcid,kl,lzcnt,mmx,movbe,movdir64b,movdiri,no-bypass-delay,nopl,pclmul,pconfig,pku,popcnt,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,serialize,sha,shstk,slow-incdec,slow-lea,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,uintr,use-glm-div-sqrt-costs,vaes,vpclmulqdq,vzeroupper,waitpkg,widekl,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("graniterapids"), str_lit("32bit-mode,64bit,adx,aes,allow-light-256-bit,amx-bf16,amx-fp16,amx-int8,amx-tile,avx,avx2,avx512bf16,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512f,avx512fp16,avx512ifma,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vpopcntdq,avxvnni,bmi,bmi2,cldemote,clflushopt,clwb,cmov,crc32,cx16,cx8,enqcmd,ermsb,evex512,f16c,false-deps-getmant,false-deps-mulc,false-deps-mullq,false-deps-perm,false-deps-range,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,gfni,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,movdir64b,movdiri,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pconfig,pku,popcnt,prefer-256-bit,prefetchi,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,serialize,sha,shstk,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tsxldtrk,tuning-fast-imm-vector-shift,uintr,vaes,vpclmulqdq,vzeroupper,waitpkg,wbnoinvd,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("graniterapids-d"), str_lit("32bit-mode,64bit,adx,aes,allow-light-256-bit,amx-bf16,amx-complex,amx-fp16,amx-int8,amx-tile,avx,avx2,avx512bf16,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512f,avx512fp16,avx512ifma,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vpopcntdq,avxvnni,bmi,bmi2,cldemote,clflushopt,clwb,cmov,crc32,cx16,cx8,enqcmd,ermsb,evex512,f16c,false-deps-getmant,false-deps-mulc,false-deps-mullq,false-deps-perm,false-deps-range,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,gfni,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,movdir64b,movdiri,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pconfig,pku,popcnt,prefer-256-bit,prefetchi,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,serialize,sha,shstk,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tsxldtrk,tuning-fast-imm-vector-shift,uintr,vaes,vpclmulqdq,vzeroupper,waitpkg,wbnoinvd,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("graniterapids_d"), str_lit("32bit-mode,64bit,adx,aes,allow-light-256-bit,amx-bf16,amx-complex,amx-fp16,amx-int8,amx-tile,avx,avx2,avx512bf16,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512f,avx512fp16,avx512ifma,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vpopcntdq,avxvnni,bmi,bmi2,cldemote,clflushopt,clwb,cmov,crc32,cx16,cx8,enqcmd,ermsb,evex512,f16c,false-deps-getmant,false-deps-mulc,false-deps-mullq,false-deps-perm,false-deps-range,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,gfni,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,movdir64b,movdiri,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pconfig,pku,popcnt,prefer-256-bit,prefetchi,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,serialize,sha,shstk,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tsxldtrk,tuning-fast-imm-vector-shift,uintr,vaes,vpclmulqdq,vzeroupper,waitpkg,wbnoinvd,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("haswell"), str_lit("32bit-mode,64bit,allow-light-256-bit,avx,avx2,bmi,bmi2,cmov,crc32,cx16,cx8,ermsb,f16c,false-deps-lzcnt-tzcnt,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,popcnt,rdrnd,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("i386"), str_lit("32bit-mode,slow-unaligned-mem-16,vzeroupper,x87") },
	{ str_lit("i486"), str_lit("32bit-mode,slow-unaligned-mem-16,vzeroupper,x87") },
	{ str_lit("i586"), str_lit("32bit-mode,cx8,slow-unaligned-mem-16,vzeroupper,x87") },
	{ str_lit("i686"), str_lit("32bit-mode,cmov,cx8,slow-unaligned-mem-16,vzeroupper,x87") },
	{ str_lit("icelake-client"), str_lit("32bit-mode,64bit,adx,aes,allow-light-256-bit,avx,avx2,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512f,avx512ifma,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vpopcntdq,bmi,bmi2,clflushopt,cmov,crc32,cx16,cx8,ermsb,evex512,f16c,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,gfni,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pku,popcnt,prefer-256-bit,prfchw,rdpid,rdrnd,rdseed,sahf,sha,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vaes,vpclmulqdq,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("icelake-server"), str_lit("32bit-mode,64bit,adx,aes,allow-light-256-bit,avx,avx2,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512f,avx512ifma,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vpopcntdq,bmi,bmi2,clflushopt,clwb,cmov,crc32,cx16,cx8,ermsb,evex512,f16c,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,gfni,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pconfig,pku,popcnt,prefer-256-bit,prfchw,rdpid,rdrnd,rdseed,sahf,sha,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vaes,vpclmulqdq,vzeroupper,wbnoinvd,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("icelake_client"), str_lit("32bit-mode,64bit,adx,aes,allow-light-256-bit,avx,avx2,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512f,avx512ifma,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vpopcntdq,bmi,bmi2,clflushopt,cmov,crc32,cx16,cx8,ermsb,evex512,f16c,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,gfni,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pku,popcnt,prefer-256-bit,prfchw,rdpid,rdrnd,rdseed,sahf,sha,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vaes,vpclmulqdq,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("icelake_server"), str_lit("32bit-mode,64bit,adx,aes,allow-light-256-bit,avx,avx2,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512f,avx512ifma,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vpopcntdq,bmi,bmi2,clflushopt,clwb,cmov,crc32,cx16,cx8,ermsb,evex512,f16c,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,gfni,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pconfig,pku,popcnt,prefer-256-bit,prfchw,rdpid,rdrnd,rdseed,sahf,sha,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vaes,vpclmulqdq,vzeroupper,wbnoinvd,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("ivybridge"), str_lit("32bit-mode,64bit,avx,cmov,crc32,cx16,cx8,f16c,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fsgsbase,fxsr,idivq-to-divl,macrofusion,mmx,no-bypass-delay-mov,nopl,pclmul,popcnt,rdrnd,sahf,slow-3ops-lea,slow-unaligned-mem-32,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("k6"), str_lit("32bit-mode,cx8,mmx,slow-unaligned-mem-16,vzeroupper,x87") },
	{ str_lit("k6-2"), str_lit("32bit-mode,3dnow,cx8,mmx,slow-unaligned-mem-16,vzeroupper,x87") },
	{ str_lit("k6-3"), str_lit("32bit-mode,3dnow,cx8,mmx,slow-unaligned-mem-16,vzeroupper,x87") },
	{ str_lit("k8"), str_lit("32bit-mode,3dnow,3dnowa,64bit,cmov,cx8,fast-scalar-shift-masks,fxsr,mmx,nopl,sbb-dep-breaking,slow-shld,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("k8-sse3"), str_lit("32bit-mode,3dnow,3dnowa,64bit,cmov,cx16,cx8,fast-scalar-shift-masks,fxsr,mmx,nopl,sbb-dep-breaking,slow-shld,slow-unaligned-mem-16,sse,sse2,sse3,vzeroupper,x87") },
	{ str_lit("knl"), str_lit("32bit-mode,64bit,adx,aes,avx,avx2,avx512cd,avx512er,avx512f,avx512pf,bmi,bmi2,cmov,crc32,cx16,cx8,evex512,f16c,fast-gather,fast-movbe,fma,fsgsbase,fxsr,idivq-to-divl,lzcnt,mmx,movbe,nopl,pclmul,popcnt,prefer-mask-registers,prefetchwt1,prfchw,rdrnd,rdseed,sahf,slow-3ops-lea,slow-incdec,slow-pmaddwd,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,x87,xsave,xsaveopt") },
	{ str_lit("knm"), str_lit("32bit-mode,64bit,adx,aes,avx,avx2,avx512cd,avx512er,avx512f,avx512pf,avx512vpopcntdq,bmi,bmi2,cmov,crc32,cx16,cx8,evex512,f16c,fast-gather,fast-movbe,fma,fsgsbase,fxsr,idivq-to-divl,lzcnt,mmx,movbe,nopl,pclmul,popcnt,prefer-mask-registers,prefetchwt1,prfchw,rdrnd,rdseed,sahf,slow-3ops-lea,slow-incdec,slow-pmaddwd,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,x87,xsave,xsaveopt") },
	{ str_lit("lakemont"), str_lit("32bit-mode,cx8,slow-unaligned-mem-16,vzeroupper") },
	{ str_lit("meteorlake"), str_lit("32bit-mode,64bit,adx,aes,allow-light-256-bit,avx,avx2,avxvnni,bmi,bmi2,cldemote,clflushopt,clwb,cmov,crc32,cx16,cx8,f16c,false-deps-perm,false-deps-popcnt,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fxsr,gfni,hreset,idivq-to-divl,invpcid,kl,lzcnt,macrofusion,mmx,movbe,movdir64b,movdiri,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pconfig,pku,popcnt,prefer-movmsk-over-vtest,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,serialize,sha,shstk,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vaes,vpclmulqdq,vzeroupper,waitpkg,widekl,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("mic_avx512"), str_lit("32bit-mode,64bit,adx,aes,avx,avx2,avx512cd,avx512er,avx512f,avx512pf,bmi,bmi2,cmov,crc32,cx16,cx8,evex512,f16c,fast-gather,fast-movbe,fma,fsgsbase,fxsr,idivq-to-divl,lzcnt,mmx,movbe,nopl,pclmul,popcnt,prefer-mask-registers,prefetchwt1,prfchw,rdrnd,rdseed,sahf,slow-3ops-lea,slow-incdec,slow-pmaddwd,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,x87,xsave,xsaveopt") },
	{ str_lit("nehalem"), str_lit("32bit-mode,64bit,cmov,crc32,cx16,cx8,fxsr,macrofusion,mmx,no-bypass-delay-mov,nopl,popcnt,sahf,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87") },
	{ str_lit("nocona"), str_lit("32bit-mode,64bit,cmov,cx16,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,sse2,sse3,vzeroupper,x87") },
	{ str_lit("opteron"), str_lit("32bit-mode,3dnow,3dnowa,64bit,cmov,cx8,fast-scalar-shift-masks,fxsr,mmx,nopl,sbb-dep-breaking,slow-shld,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("opteron-sse3"), str_lit("32bit-mode,3dnow,3dnowa,64bit,cmov,cx16,cx8,fast-scalar-shift-masks,fxsr,mmx,nopl,sbb-dep-breaking,slow-shld,slow-unaligned-mem-16,sse,sse2,sse3,vzeroupper,x87") },
	{ str_lit("penryn"), str_lit("32bit-mode,64bit,cmov,cx16,cx8,fxsr,macrofusion,mmx,nopl,sahf,slow-unaligned-mem-16,sse,sse2,sse3,sse4.1,ssse3,vzeroupper,x87") },
	{ str_lit("pentium"), str_lit("32bit-mode,cx8,slow-unaligned-mem-16,vzeroupper,x87") },
	{ str_lit("pentium-m"), str_lit("32bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("pentium-mmx"), str_lit("32bit-mode,cx8,mmx,slow-unaligned-mem-16,vzeroupper,x87") },
	{ str_lit("pentium2"), str_lit("32bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,vzeroupper,x87") },
	{ str_lit("pentium3"), str_lit("32bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,vzeroupper,x87") },
	{ str_lit("pentium3m"), str_lit("32bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,vzeroupper,x87") },
	{ str_lit("pentium4"), str_lit("32bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("pentium4m"), str_lit("32bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("pentium_4"), str_lit("32bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("pentium_4_sse3"), str_lit("32bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,sse2,sse3,vzeroupper,x87") },
	{ str_lit("pentium_ii"), str_lit("32bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,vzeroupper,x87") },
	{ str_lit("pentium_iii"), str_lit("32bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,vzeroupper,x87") },
	{ str_lit("pentium_iii_no_xmm_regs"), str_lit("32bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,vzeroupper,x87") },
	{ str_lit("pentium_m"), str_lit("32bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,sse2,vzeroupper,x87") },
	{ str_lit("pentium_mmx"), str_lit("32bit-mode,cx8,mmx,slow-unaligned-mem-16,vzeroupper,x87") },
	{ str_lit("pentium_pro"), str_lit("32bit-mode,cmov,cx8,nopl,slow-unaligned-mem-16,vzeroupper,x87") },
	{ str_lit("pentiumpro"), str_lit("32bit-mode,cmov,cx8,nopl,slow-unaligned-mem-16,vzeroupper,x87") },
	{ str_lit("prescott"), str_lit("32bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,sse2,sse3,vzeroupper,x87") },
	{ str_lit("raptorlake"), str_lit("32bit-mode,64bit,adx,aes,allow-light-256-bit,avx,avx2,avxvnni,bmi,bmi2,cldemote,clflushopt,clwb,cmov,crc32,cx16,cx8,f16c,false-deps-perm,false-deps-popcnt,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fxsr,gfni,hreset,idivq-to-divl,invpcid,kl,lzcnt,macrofusion,mmx,movbe,movdir64b,movdiri,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pconfig,pku,popcnt,prefer-movmsk-over-vtest,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,serialize,sha,shstk,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vaes,vpclmulqdq,vzeroupper,waitpkg,widekl,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("rocketlake"), str_lit("32bit-mode,64bit,adx,aes,allow-light-256-bit,avx,avx2,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512f,avx512ifma,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vpopcntdq,bmi,bmi2,clflushopt,cmov,crc32,cx16,cx8,ermsb,evex512,f16c,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,gfni,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pku,popcnt,prefer-256-bit,prfchw,rdpid,rdrnd,rdseed,sahf,sha,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vaes,vpclmulqdq,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("sandybridge"), str_lit("32bit-mode,64bit,avx,cmov,crc32,cx16,cx8,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fxsr,idivq-to-divl,macrofusion,mmx,no-bypass-delay-mov,nopl,pclmul,popcnt,sahf,slow-3ops-lea,slow-unaligned-mem-32,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsaveopt") },
	{ str_lit("sapphirerapids"), str_lit("32bit-mode,64bit,adx,aes,allow-light-256-bit,amx-bf16,amx-int8,amx-tile,avx,avx2,avx512bf16,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512f,avx512fp16,avx512ifma,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vpopcntdq,avxvnni,bmi,bmi2,cldemote,clflushopt,clwb,cmov,crc32,cx16,cx8,enqcmd,ermsb,evex512,f16c,false-deps-getmant,false-deps-mulc,false-deps-mullq,false-deps-perm,false-deps-range,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,gfni,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,movdir64b,movdiri,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pconfig,pku,popcnt,prefer-256-bit,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,serialize,sha,shstk,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tsxldtrk,tuning-fast-imm-vector-shift,uintr,vaes,vpclmulqdq,vzeroupper,waitpkg,wbnoinvd,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("sierraforest"), str_lit("32bit-mode,64bit,adx,aes,avx,avx2,avxifma,avxneconvert,avxvnni,avxvnniint8,bmi,bmi2,cldemote,clflushopt,clwb,cmov,cmpccxadd,crc32,cx16,cx8,enqcmd,f16c,fast-movbe,fma,fsgsbase,fxsr,gfni,hreset,invpcid,kl,lzcnt,mmx,movbe,movdir64b,movdiri,no-bypass-delay,nopl,pclmul,pconfig,pku,popcnt,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,serialize,sha,shstk,slow-incdec,slow-lea,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,uintr,use-glm-div-sqrt-costs,vaes,vpclmulqdq,vzeroupper,waitpkg,widekl,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("silvermont"), str_lit("32bit-mode,64bit,cmov,crc32,cx16,cx8,false-deps-popcnt,fast-7bytenop,fast-movbe,fxsr,idivq-to-divl,mmx,movbe,no-bypass-delay,nopl,pclmul,popcnt,prfchw,rdrnd,sahf,slow-incdec,slow-lea,slow-pmulld,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,use-slm-arith-costs,vzeroupper,x87") },
	{ str_lit("skx"), str_lit("32bit-mode,64bit,adx,aes,allow-light-256-bit,avx,avx2,avx512bw,avx512cd,avx512dq,avx512f,avx512vl,bmi,bmi2,clflushopt,clwb,cmov,crc32,cx16,cx8,ermsb,evex512,f16c,false-deps-popcnt,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,faster-shift-than-shuffle,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pku,popcnt,prefer-256-bit,prfchw,rdrnd,rdseed,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("skylake"), str_lit("32bit-mode,64bit,adx,aes,allow-light-256-bit,avx,avx2,bmi,bmi2,clflushopt,cmov,crc32,cx16,cx8,ermsb,f16c,false-deps-popcnt,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,popcnt,prfchw,rdrnd,rdseed,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("skylake-avx512"), str_lit("32bit-mode,64bit,adx,aes,allow-light-256-bit,avx,avx2,avx512bw,avx512cd,avx512dq,avx512f,avx512vl,bmi,bmi2,clflushopt,clwb,cmov,crc32,cx16,cx8,ermsb,evex512,f16c,false-deps-popcnt,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,faster-shift-than-shuffle,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pku,popcnt,prefer-256-bit,prfchw,rdrnd,rdseed,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("skylake_avx512"), str_lit("32bit-mode,64bit,adx,aes,allow-light-256-bit,avx,avx2,avx512bw,avx512cd,avx512dq,avx512f,avx512vl,bmi,bmi2,clflushopt,clwb,cmov,crc32,cx16,cx8,ermsb,evex512,f16c,false-deps-popcnt,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,faster-shift-than-shuffle,fma,fsgsbase,fxsr,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pku,popcnt,prefer-256-bit,prfchw,rdrnd,rdseed,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("slm"), str_lit("32bit-mode,64bit,cmov,crc32,cx16,cx8,false-deps-popcnt,fast-7bytenop,fast-movbe,fxsr,idivq-to-divl,mmx,movbe,no-bypass-delay,nopl,pclmul,popcnt,prfchw,rdrnd,sahf,slow-incdec,slow-lea,slow-pmulld,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,use-slm-arith-costs,vzeroupper,x87") },
	{ str_lit("tigerlake"), str_lit("32bit-mode,64bit,adx,aes,allow-light-256-bit,avx,avx2,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512f,avx512ifma,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vp2intersect,avx512vpopcntdq,bmi,bmi2,clflushopt,clwb,cmov,crc32,cx16,cx8,ermsb,evex512,f16c,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,gfni,idivq-to-divl,invpcid,lzcnt,macrofusion,mmx,movbe,movdir64b,movdiri,no-bypass-delay-blend,no-bypass-delay-mov,no-bypass-delay-shuffle,nopl,pclmul,pku,popcnt,prefer-256-bit,prfchw,rdpid,rdrnd,rdseed,sahf,sha,shstk,sse,sse2,sse3,sse4.1,sse4.2,ssse3,tuning-fast-imm-vector-shift,vaes,vpclmulqdq,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("tremont"), str_lit("32bit-mode,64bit,aes,clflushopt,clwb,cmov,crc32,cx16,cx8,fast-movbe,fsgsbase,fxsr,gfni,mmx,movbe,no-bypass-delay,nopl,pclmul,popcnt,prfchw,ptwrite,rdpid,rdrnd,rdseed,sahf,sha,slow-incdec,slow-lea,slow-two-mem-ops,sse,sse2,sse3,sse4.1,sse4.2,ssse3,use-glm-div-sqrt-costs,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("westmere"), str_lit("32bit-mode,64bit,cmov,crc32,cx16,cx8,fxsr,macrofusion,mmx,no-bypass-delay-mov,nopl,pclmul,popcnt,sahf,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87") },
	{ str_lit("winchip-c6"), str_lit("32bit-mode,mmx,slow-unaligned-mem-16,vzeroupper,x87") },
	{ str_lit("winchip2"), str_lit("32bit-mode,3dnow,mmx,slow-unaligned-mem-16,vzeroupper,x87") },
	{ str_lit("x86-64"), str_lit("32bit-mode,64bit,cmov,cx8,fxsr,idivq-to-divl,macrofusion,mmx,nopl,slow-3ops-lea,slow-incdec,sse,sse2,vzeroupper,x87") },
	{ str_lit("x86-64-v2"), str_lit("32bit-mode,64bit,cmov,crc32,cx16,cx8,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fxsr,idivq-to-divl,macrofusion,mmx,nopl,popcnt,sahf,slow-3ops-lea,slow-unaligned-mem-32,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87") },
	{ str_lit("x86-64-v3"), str_lit("32bit-mode,64bit,allow-light-256-bit,avx,avx2,bmi,bmi2,cmov,crc32,cx16,cx8,f16c,false-deps-lzcnt-tzcnt,false-deps-popcnt,fast-15bytenop,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fma,fxsr,idivq-to-divl,lzcnt,macrofusion,mmx,movbe,nopl,popcnt,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave") },
	{ str_lit("x86-64-v4"), str_lit("32bit-mode,64bit,allow-light-256-bit,avx,avx2,avx512bw,avx512cd,avx512dq,avx512f,avx512vl,bmi,bmi2,cmov,crc32,cx16,cx8,evex512,f16c,false-deps-popcnt,fast-15bytenop,fast-gather,fast-scalar-fsqrt,fast-shld-rotate,fast-variable-crosslane-shuffle,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fxsr,idivq-to-divl,lzcnt,macrofusion,mmx,movbe,nopl,popcnt,prefer-256-bit,sahf,slow-3ops-lea,sse,sse2,sse3,sse4.1,sse4.2,ssse3,vzeroupper,x87,xsave") },
	{ str_lit("yonah"), str_lit("32bit-mode,cmov,cx8,fxsr,mmx,nopl,slow-unaligned-mem-16,sse,sse2,sse3,vzeroupper,x87") },
	{ str_lit("znver1"), str_lit("32bit-mode,64bit,adx,aes,allow-light-256-bit,avx,avx2,bmi,bmi2,branchfusion,clflushopt,clzero,cmov,crc32,cx16,cx8,f16c,fast-15bytenop,fast-bextr,fast-lzcnt,fast-movbe,fast-scalar-fsqrt,fast-scalar-shift-masks,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fxsr,lzcnt,mmx,movbe,mwaitx,nopl,pclmul,popcnt,prfchw,rdrnd,rdseed,sahf,sbb-dep-breaking,sha,slow-shld,sse,sse2,sse3,sse4.1,sse4.2,sse4a,ssse3,vzeroupper,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("znver2"), str_lit("32bit-mode,64bit,adx,aes,allow-light-256-bit,avx,avx2,bmi,bmi2,branchfusion,clflushopt,clwb,clzero,cmov,crc32,cx16,cx8,f16c,fast-15bytenop,fast-bextr,fast-lzcnt,fast-movbe,fast-scalar-fsqrt,fast-scalar-shift-masks,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fxsr,lzcnt,mmx,movbe,mwaitx,nopl,pclmul,popcnt,prfchw,rdpid,rdpru,rdrnd,rdseed,sahf,sbb-dep-breaking,sha,slow-shld,sse,sse2,sse3,sse4.1,sse4.2,sse4a,ssse3,vzeroupper,wbnoinvd,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("znver3"), str_lit("32bit-mode,64bit,adx,aes,allow-light-256-bit,avx,avx2,bmi,bmi2,branchfusion,clflushopt,clwb,clzero,cmov,crc32,cx16,cx8,f16c,fast-15bytenop,fast-bextr,fast-lzcnt,fast-movbe,fast-scalar-fsqrt,fast-scalar-shift-masks,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,invpcid,lzcnt,macrofusion,mmx,movbe,mwaitx,nopl,pclmul,pku,popcnt,prfchw,rdpid,rdpru,rdrnd,rdseed,sahf,sbb-dep-breaking,sha,slow-shld,sse,sse2,sse3,sse4.1,sse4.2,sse4a,ssse3,vaes,vpclmulqdq,vzeroupper,wbnoinvd,x87,xsave,xsavec,xsaveopt,xsaves") },
	{ str_lit("znver4"), str_lit("32bit-mode,64bit,adx,aes,allow-light-256-bit,avx,avx2,avx512bf16,avx512bitalg,avx512bw,avx512cd,avx512dq,avx512f,avx512ifma,avx512vbmi,avx512vbmi2,avx512vl,avx512vnni,avx512vpopcntdq,bmi,bmi2,branchfusion,clflushopt,clwb,clzero,cmov,crc32,cx16,cx8,evex512,f16c,fast-15bytenop,fast-bextr,fast-lzcnt,fast-movbe,fast-scalar-fsqrt,fast-scalar-shift-masks,fast-variable-perlane-shuffle,fast-vector-fsqrt,fma,fsgsbase,fsrm,fxsr,gfni,invpcid,lzcnt,macrofusion,mmx,movbe,mwaitx,nopl,pclmul,pku,popcnt,prfchw,rdpid,rdpru,rdrnd,rdseed,sahf,sbb-dep-breaking,sha,shstk,slow-shld,sse,sse2,sse3,sse4.1,sse4.2,sse4a,ssse3,vaes,vpclmulqdq,vzeroupper,wbnoinvd,x87,xsave,xsavec,xsaveopt,xsaves") },
	// TargetArch_arm32:
	{ str_lit("arm1020e"), str_lit("armv5te,v4t,v5t,v5te") },
	{ str_lit("arm1020t"), str_lit("armv5t,v4t,v5t") },
	{ str_lit("arm1022e"), str_lit("armv5te,v4t,v5t,v5te") },
	{ str_lit("arm10e"), str_lit("armv5te,v4t,v5t,v5te") },
	{ str_lit("arm10tdmi"), str_lit("armv5t,v4t,v5t") },
	{ str_lit("arm1136j-s"), str_lit("armv6,dsp,v4t,v5t,v5te,v6") },
	{ str_lit("arm1136jf-s"), str_lit("armv6,dsp,fp64,fpregs,fpregs64,slowfpvmlx,v4t,v5t,v5te,v6,vfp2,vfp2sp") },
	{ str_lit("arm1156t2-s"), str_lit("armv6t2,dsp,thumb2,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v8m") },
	{ str_lit("arm1156t2f-s"), str_lit("armv6t2,dsp,fp64,fpregs,fpregs64,slowfpvmlx,thumb2,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v8m,vfp2,vfp2sp") },
	{ str_lit("arm1176jz-s"), str_lit("armv6kz,trustzone,v4t,v5t,v5te,v6,v6k") },
	{ str_lit("arm1176jzf-s"), str_lit("armv6kz,fp64,fpregs,fpregs64,slowfpvmlx,trustzone,v4t,v5t,v5te,v6,v6k,vfp2,vfp2sp") },
	{ str_lit("arm710t"), str_lit("armv4t,v4t") },
	{ str_lit("arm720t"), str_lit("armv4t,v4t") },
	{ str_lit("arm7tdmi"), str_lit("armv4t,v4t") },
	{ str_lit("arm7tdmi-s"), str_lit("armv4t,v4t") },
	{ str_lit("arm8"), str_lit("armv4") },
	{ str_lit("arm810"), str_lit("armv4") },
	{ str_lit("arm9"), str_lit("armv4t,v4t") },
	{ str_lit("arm920"), str_lit("armv4t,v4t") },
	{ str_lit("arm920t"), str_lit("armv4t,v4t") },
	{ str_lit("arm922t"), str_lit("armv4t,v4t") },
	{ str_lit("arm926ej-s"), str_lit("armv5te,v4t,v5t,v5te") },
	{ str_lit("arm940t"), str_lit("armv4t,v4t") },
	{ str_lit("arm946e-s"), str_lit("armv5te,v4t,v5t,v5te") },
	{ str_lit("arm966e-s"), str_lit("armv5te,v4t,v5t,v5te") },
	{ str_lit("arm968e-s"), str_lit("armv5te,v4t,v5t,v5te") },
	{ str_lit("arm9e"), str_lit("armv5te,v4t,v5t,v5te") },
	{ str_lit("arm9tdmi"), str_lit("armv4t,v4t") },
	{ str_lit("cortex-a12"), str_lit("a12,aclass,armv7-a,avoid-partial-cpsr,d32,db,dsp,fp16,fp64,fpregs,fpregs64,hwdiv,hwdiv-arm,mp,neon,perfmon,ret-addr-stack,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization,vmlx-forwarding") },
	{ str_lit("cortex-a15"), str_lit("a15,aclass,armv7-a,avoid-partial-cpsr,d32,db,dont-widen-vmovs,dsp,fp16,fp64,fpregs,fpregs64,hwdiv,hwdiv-arm,mp,muxed-units,neon,perfmon,ret-addr-stack,splat-vfp-neon,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization,vldn-align") },
	{ str_lit("cortex-a17"), str_lit("a17,aclass,armv7-a,avoid-partial-cpsr,d32,db,dsp,fp16,fp64,fpregs,fpregs64,hwdiv,hwdiv-arm,mp,neon,perfmon,ret-addr-stack,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization,vmlx-forwarding") },
	{ str_lit("cortex-a32"), str_lit("aclass,acquire-release,aes,armv8-a,crc,crypto,d32,db,dsp,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp64,fpregs,fpregs64,hwdiv,hwdiv-arm,mp,neon,perfmon,sha2,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization") },
	{ str_lit("cortex-a35"), str_lit("a35,aclass,acquire-release,aes,armv8-a,crc,crypto,d32,db,dsp,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp64,fpregs,fpregs64,hwdiv,hwdiv-arm,mp,neon,perfmon,sha2,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization") },
	{ str_lit("cortex-a5"), str_lit("a5,aclass,armv7-a,d32,db,dsp,fp16,fp64,fpregs,fpregs64,mp,neon,perfmon,ret-addr-stack,slow-fp-brcc,slowfpvfmx,slowfpvmlx,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,vmlx-forwarding") },
	{ str_lit("cortex-a53"), str_lit("a53,aclass,acquire-release,aes,armv8-a,crc,crypto,d32,db,dsp,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp64,fpao,fpregs,fpregs64,hwdiv,hwdiv-arm,mp,neon,perfmon,sha2,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization") },
	{ str_lit("cortex-a55"), str_lit("a55,aclass,acquire-release,aes,armv8.2-a,crc,crypto,d32,db,dotprod,dsp,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp64,fpregs,fpregs64,hwdiv,hwdiv-arm,mp,neon,perfmon,ras,sha2,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8.1a,v8.2a,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization") },
	{ str_lit("cortex-a57"), str_lit("a57,aclass,acquire-release,aes,armv8-a,avoid-partial-cpsr,cheap-predicable-cpsr,crc,crypto,d32,db,dsp,fix-cortex-a57-aes-1742098,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp64,fpao,fpregs,fpregs64,hwdiv,hwdiv-arm,mp,neon,perfmon,sha2,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization") },
	{ str_lit("cortex-a7"), str_lit("a7,aclass,armv7-a,d32,db,dsp,fp16,fp64,fpregs,fpregs64,hwdiv,hwdiv-arm,mp,neon,perfmon,ret-addr-stack,slow-fp-brcc,slowfpvfmx,slowfpvmlx,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization,vmlx-forwarding,vmlx-hazards") },
	{ str_lit("cortex-a710"), str_lit("aclass,acquire-release,armv9-a,bf16,cortex-a710,crc,d32,db,dotprod,dsp,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp16fml,fp64,fpregs,fpregs16,fpregs64,fullfp16,hwdiv,hwdiv-arm,i8mm,mp,neon,perfmon,ras,sb,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8.1a,v8.2a,v8.3a,v8.4a,v8.5a,v8m,v9a,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization") },
	{ str_lit("cortex-a72"), str_lit("a72,aclass,acquire-release,aes,armv8-a,crc,crypto,d32,db,dsp,fix-cortex-a57-aes-1742098,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp64,fpregs,fpregs64,hwdiv,hwdiv-arm,mp,neon,perfmon,sha2,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization") },
	{ str_lit("cortex-a73"), str_lit("a73,aclass,acquire-release,aes,armv8-a,crc,crypto,d32,db,dsp,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp64,fpregs,fpregs64,hwdiv,hwdiv-arm,mp,neon,perfmon,sha2,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization") },
	{ str_lit("cortex-a75"), str_lit("a75,aclass,acquire-release,aes,armv8.2-a,crc,crypto,d32,db,dotprod,dsp,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp64,fpregs,fpregs64,hwdiv,hwdiv-arm,mp,neon,perfmon,ras,sha2,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8.1a,v8.2a,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization") },
	{ str_lit("cortex-a76"), str_lit("a76,aclass,acquire-release,aes,armv8.2-a,crc,crypto,d32,db,dotprod,dsp,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp64,fpregs,fpregs16,fpregs64,fullfp16,hwdiv,hwdiv-arm,mp,neon,perfmon,ras,sha2,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8.1a,v8.2a,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization") },
	{ str_lit("cortex-a76ae"), str_lit("a76,aclass,acquire-release,aes,armv8.2-a,crc,crypto,d32,db,dotprod,dsp,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp64,fpregs,fpregs16,fpregs64,fullfp16,hwdiv,hwdiv-arm,mp,neon,perfmon,ras,sha2,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8.1a,v8.2a,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization") },
	{ str_lit("cortex-a77"), str_lit("a77,aclass,acquire-release,aes,armv8.2-a,crc,crypto,d32,db,dotprod,dsp,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp64,fpregs,fpregs16,fpregs64,fullfp16,hwdiv,hwdiv-arm,mp,neon,perfmon,ras,sha2,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8.1a,v8.2a,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization") },
	{ str_lit("cortex-a78"), str_lit("aclass,acquire-release,aes,armv8.2-a,cortex-a78,crc,crypto,d32,db,dotprod,dsp,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp64,fpregs,fpregs16,fpregs64,fullfp16,hwdiv,hwdiv-arm,mp,neon,perfmon,ras,sha2,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8.1a,v8.2a,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization") },
	{ str_lit("cortex-a78c"), str_lit("a78c,aclass,acquire-release,aes,armv8.2-a,crc,crypto,d32,db,dotprod,dsp,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp64,fpregs,fpregs16,fpregs64,fullfp16,hwdiv,hwdiv-arm,mp,neon,perfmon,ras,sha2,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8.1a,v8.2a,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization") },
	{ str_lit("cortex-a8"), str_lit("a8,aclass,armv7-a,d32,db,dsp,fp64,fpregs,fpregs64,neon,nonpipelined-vfp,perfmon,ret-addr-stack,slow-fp-brcc,slowfpvfmx,slowfpvmlx,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vmlx-forwarding,vmlx-hazards") },
	{ str_lit("cortex-a9"), str_lit("a9,aclass,armv7-a,avoid-partial-cpsr,d32,db,dsp,expand-fp-mlx,fp16,fp64,fpregs,fpregs64,mp,muxed-units,neon,neon-fpmovs,perfmon,prefer-vmovsr,ret-addr-stack,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vldn-align,vmlx-forwarding,vmlx-hazards") },
	{ str_lit("cortex-m0"), str_lit("armv6-m,db,mclass,no-branch-predictor,noarm,strict-align,thumb-mode,v4t,v5t,v5te,v6,v6m") },
	{ str_lit("cortex-m0plus"), str_lit("armv6-m,db,mclass,no-branch-predictor,noarm,strict-align,thumb-mode,v4t,v5t,v5te,v6,v6m") },
	{ str_lit("cortex-m1"), str_lit("armv6-m,db,mclass,no-branch-predictor,noarm,strict-align,thumb-mode,v4t,v5t,v5te,v6,v6m") },
	{ str_lit("cortex-m23"), str_lit("8msecext,acquire-release,armv8-m.base,db,hwdiv,mclass,no-branch-predictor,no-movt,noarm,strict-align,thumb-mode,v4t,v5t,v5te,v6,v6m,v7clrex,v8m") },
	{ str_lit("cortex-m3"), str_lit("armv7-m,db,hwdiv,loop-align,m3,mclass,no-branch-predictor,noarm,thumb-mode,thumb2,use-misched,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8m") },
	{ str_lit("cortex-m33"), str_lit("8msecext,acquire-release,armv8-m.main,db,dsp,fix-cmse-cve-2021-35465,fp-armv8d16sp,fp16,fpregs,hwdiv,loop-align,mclass,no-branch-predictor,noarm,slowfpvfmx,slowfpvmlx,thumb-mode,thumb2,use-misched,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8m,v8m.main,vfp2sp,vfp3d16sp,vfp4d16sp") },
	{ str_lit("cortex-m35p"), str_lit("8msecext,acquire-release,armv8-m.main,db,dsp,fix-cmse-cve-2021-35465,fp-armv8d16sp,fp16,fpregs,hwdiv,loop-align,mclass,no-branch-predictor,noarm,slowfpvfmx,slowfpvmlx,thumb-mode,thumb2,use-misched,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8m,v8m.main,vfp2sp,vfp3d16sp,vfp4d16sp") },
	{ str_lit("cortex-m4"), str_lit("armv7e-m,db,dsp,fp16,fpregs,hwdiv,loop-align,mclass,no-branch-predictor,noarm,slowfpvfmx,slowfpvmlx,thumb-mode,thumb2,use-misched,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8m,vfp2sp,vfp3d16sp,vfp4d16sp") },
	{ str_lit("cortex-m55"), str_lit("8msecext,acquire-release,armv8.1-m.main,db,dsp,fix-cmse-cve-2021-35465,fp-armv8d16,fp-armv8d16sp,fp16,fp64,fpregs,fpregs16,fpregs64,fullfp16,hwdiv,lob,loop-align,mclass,mve,mve.fp,no-branch-predictor,noarm,ras,slowfpvmlx,thumb-mode,thumb2,use-misched,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8.1m.main,v8m,v8m.main,vfp2,vfp2sp,vfp3d16,vfp3d16sp,vfp4d16,vfp4d16sp") },
	{ str_lit("cortex-m7"), str_lit("armv7e-m,db,dsp,fp-armv8d16,fp-armv8d16sp,fp16,fp64,fpregs,fpregs64,hwdiv,m7,mclass,noarm,thumb-mode,thumb2,use-mipipeliner,use-misched,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8m,vfp2,vfp2sp,vfp3d16,vfp3d16sp,vfp4d16,vfp4d16sp") },
	{ str_lit("cortex-m85"), str_lit("8msecext,acquire-release,armv8.1-m.main,db,dsp,fp-armv8d16,fp-armv8d16sp,fp16,fp64,fpregs,fpregs16,fpregs64,fullfp16,hwdiv,lob,mclass,mve,mve.fp,noarm,pacbti,ras,thumb-mode,thumb2,use-misched,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8.1m.main,v8m,v8m.main,vfp2,vfp2sp,vfp3d16,vfp3d16sp,vfp4d16,vfp4d16sp") },
	{ str_lit("cortex-r4"), str_lit("armv7-r,avoid-partial-cpsr,db,dsp,hwdiv,perfmon,r4,rclass,ret-addr-stack,thumb2,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8m") },
	{ str_lit("cortex-r4f"), str_lit("armv7-r,avoid-partial-cpsr,db,dsp,fp64,fpregs,fpregs64,hwdiv,perfmon,r4,rclass,ret-addr-stack,slow-fp-brcc,slowfpvfmx,slowfpvmlx,thumb2,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8m,vfp2,vfp2sp,vfp3d16,vfp3d16sp") },
	{ str_lit("cortex-r5"), str_lit("armv7-r,avoid-partial-cpsr,db,dsp,fp64,fpregs,fpregs64,hwdiv,hwdiv-arm,perfmon,r5,rclass,ret-addr-stack,slow-fp-brcc,slowfpvfmx,slowfpvmlx,thumb2,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8m,vfp2,vfp2sp,vfp3d16,vfp3d16sp") },
	{ str_lit("cortex-r52"), str_lit("acquire-release,armv8-r,crc,d32,db,dfb,dsp,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp64,fpao,fpregs,fpregs64,hwdiv,hwdiv-arm,mp,neon,perfmon,r52,rclass,thumb2,use-misched,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization") },
	{ str_lit("cortex-r7"), str_lit("armv7-r,avoid-partial-cpsr,db,dsp,fp16,fp64,fpregs,fpregs64,hwdiv,hwdiv-arm,mp,perfmon,r7,rclass,ret-addr-stack,slow-fp-brcc,slowfpvfmx,slowfpvmlx,thumb2,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8m,vfp2,vfp2sp,vfp3d16,vfp3d16sp") },
	{ str_lit("cortex-r8"), str_lit("armv7-r,avoid-partial-cpsr,db,dsp,fp16,fp64,fpregs,fpregs64,hwdiv,hwdiv-arm,mp,perfmon,rclass,ret-addr-stack,slow-fp-brcc,slowfpvfmx,slowfpvmlx,thumb2,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8m,vfp2,vfp2sp,vfp3d16,vfp3d16sp") },
	{ str_lit("cortex-x1"), str_lit("aclass,acquire-release,aes,armv8.2-a,cortex-x1,crc,crypto,d32,db,dotprod,dsp,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp64,fpregs,fpregs16,fpregs64,fullfp16,hwdiv,hwdiv-arm,mp,neon,perfmon,ras,sha2,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8.1a,v8.2a,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization") },
	{ str_lit("cortex-x1c"), str_lit("aclass,acquire-release,aes,armv8.2-a,cortex-x1c,crc,crypto,d32,db,dotprod,dsp,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp64,fpregs,fpregs16,fpregs64,fullfp16,hwdiv,hwdiv-arm,mp,neon,perfmon,ras,sha2,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8.1a,v8.2a,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization") },
	{ str_lit("cyclone"), str_lit("aclass,acquire-release,aes,armv8-a,avoid-movs-shop,avoid-partial-cpsr,crc,crypto,d32,db,disable-postra-scheduler,dsp,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp64,fpregs,fpregs64,hwdiv,hwdiv-arm,mp,neon,neonfp,perfmon,ret-addr-stack,sha2,slowfpvfmx,slowfpvmlx,swift,thumb2,trustzone,use-misched,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization,zcz") },
	{ str_lit("ep9312"), str_lit("armv4t,v4t") },
	{ str_lit("exynos-m3"), str_lit("aclass,acquire-release,aes,armv8-a,crc,crypto,d32,db,dont-widen-vmovs,dsp,expand-fp-mlx,exynos,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp64,fpregs,fpregs64,fuse-aes,fuse-literals,hwdiv,hwdiv-arm,mp,neon,perfmon,prof-unpr,ret-addr-stack,sha2,slow-fp-brcc,slow-vdup32,slow-vgetlni32,slowfpvfmx,slowfpvmlx,splat-vfp-neon,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization,wide-stride-vfp,zcz") },
	{ str_lit("exynos-m4"), str_lit("aclass,acquire-release,aes,armv8.2-a,crc,crypto,d32,db,dont-widen-vmovs,dotprod,dsp,expand-fp-mlx,exynos,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp64,fpregs,fpregs16,fpregs64,fullfp16,fuse-aes,fuse-literals,hwdiv,hwdiv-arm,mp,neon,perfmon,prof-unpr,ras,ret-addr-stack,sha2,slow-fp-brcc,slow-vdup32,slow-vgetlni32,slowfpvfmx,slowfpvmlx,splat-vfp-neon,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8.1a,v8.2a,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization,wide-stride-vfp,zcz") },
	{ str_lit("exynos-m5"), str_lit("aclass,acquire-release,aes,armv8.2-a,crc,crypto,d32,db,dont-widen-vmovs,dotprod,dsp,expand-fp-mlx,exynos,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp64,fpregs,fpregs16,fpregs64,fullfp16,fuse-aes,fuse-literals,hwdiv,hwdiv-arm,mp,neon,perfmon,prof-unpr,ras,ret-addr-stack,sha2,slow-fp-brcc,slow-vdup32,slow-vgetlni32,slowfpvfmx,slowfpvmlx,splat-vfp-neon,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8.1a,v8.2a,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization,wide-stride-vfp,zcz") },
	{ str_lit("generic"), str_lit("") },
	{ str_lit("iwmmxt"), str_lit("armv5te,v4t,v5t,v5te") },
	{ str_lit("krait"), str_lit("aclass,armv7-a,avoid-partial-cpsr,d32,db,dsp,fp16,fp64,fpregs,fpregs64,hwdiv,hwdiv-arm,krait,muxed-units,neon,perfmon,ret-addr-stack,thumb2,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,vldn-align,vmlx-forwarding") },
	{ str_lit("kryo"), str_lit("aclass,acquire-release,aes,armv8-a,crc,crypto,d32,db,dsp,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp64,fpregs,fpregs64,hwdiv,hwdiv-arm,kryo,mp,neon,perfmon,sha2,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization") },
	{ str_lit("mpcore"), str_lit("armv6k,fp64,fpregs,fpregs64,slowfpvmlx,v4t,v5t,v5te,v6,v6k,vfp2,vfp2sp") },
	{ str_lit("mpcorenovfp"), str_lit("armv6k,v4t,v5t,v5te,v6,v6k") },
	{ str_lit("neoverse-n1"), str_lit("aclass,acquire-release,aes,armv8.2-a,crc,crypto,d32,db,dotprod,dsp,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp64,fpregs,fpregs64,hwdiv,hwdiv-arm,mp,neon,perfmon,ras,sha2,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8.1a,v8.2a,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization") },
	{ str_lit("neoverse-n2"), str_lit("aclass,acquire-release,armv9-a,bf16,crc,d32,db,dotprod,dsp,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp64,fpregs,fpregs64,hwdiv,hwdiv-arm,i8mm,mp,neon,perfmon,ras,sb,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8.1a,v8.2a,v8.3a,v8.4a,v8.5a,v8m,v9a,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization") },
	{ str_lit("neoverse-v1"), str_lit("aclass,acquire-release,aes,armv8.4-a,bf16,crc,crypto,d32,db,dotprod,dsp,fp-armv8,fp-armv8d16,fp-armv8d16sp,fp-armv8sp,fp16,fp64,fpregs,fpregs16,fpregs64,fullfp16,hwdiv,hwdiv-arm,i8mm,mp,neon,perfmon,ras,sha2,thumb2,trustzone,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8,v8.1a,v8.2a,v8.3a,v8.4a,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,virtualization") },
	{ str_lit("sc000"), str_lit("armv6-m,db,mclass,no-branch-predictor,noarm,strict-align,thumb-mode,v4t,v5t,v5te,v6,v6m") },
	{ str_lit("sc300"), str_lit("armv7-m,db,hwdiv,m3,mclass,no-branch-predictor,noarm,thumb-mode,thumb2,use-misched,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8m") },
	{ str_lit("strongarm"), str_lit("armv4") },
	{ str_lit("strongarm110"), str_lit("armv4") },
	{ str_lit("strongarm1100"), str_lit("armv4") },
	{ str_lit("strongarm1110"), str_lit("armv4") },
	{ str_lit("swift"), str_lit("aclass,armv7-a,avoid-movs-shop,avoid-partial-cpsr,d32,db,disable-postra-scheduler,dsp,fp16,fp64,fpregs,fpregs64,hwdiv,hwdiv-arm,mp,neon,neonfp,perfmon,prefer-ishst,prof-unpr,ret-addr-stack,slow-load-D-subreg,slow-odd-reg,slow-vdup32,slow-vgetlni32,slowfpvfmx,slowfpvmlx,swift,thumb2,use-misched,v4t,v5t,v5te,v6,v6k,v6m,v6t2,v7,v7clrex,v8m,vfp2,vfp2sp,vfp3,vfp3d16,vfp3d16sp,vfp3sp,vfp4,vfp4d16,vfp4d16sp,vfp4sp,vmlx-hazards,wide-stride-vfp") },
	{ str_lit("xscale"), str_lit("armv5te,v4t,v5t,v5te") },
	// TargetArch_arm64:
	{ str_lit("a64fx"), str_lit("CONTEXTIDREL2,a64fx,aggressive-fma,arith-bcc-fusion,ccpp,complxnum,crc,el2vmsa,el3,fp-armv8,fullfp16,lor,lse,neon,pan,pan-rwv,perfmon,predictable-select-expensive,ras,rdm,sha2,store-pair-suppress,sve,uaops,use-postra-scheduler,v8.1a,v8.2a,v8a,vh") },
	{ str_lit("ampere1"), str_lit("CONTEXTIDREL2,addr-lsl-fast,aes,aggressive-fma,altnzcv,alu-lsl-fast,am,ampere1,amvs,arith-bcc-fusion,bf16,bti,ccdp,ccidx,ccpp,cmp-bcc-fusion,complxnum,crc,dit,dotprod,ecv,el2vmsa,el3,fgt,flagm,fp-armv8,fptoint,fuse-address,fuse-aes,fuse-literals,i8mm,jsconv,ldp-aligned-only,lor,lse,lse2,mpam,neon,nv,pan,pan-rwv,pauth,perfmon,predres,rand,ras,rcpc,rcpc-immo,rdm,sb,sel2,sha2,sha3,specrestrict,ssbs,store-pair-suppress,stp-aligned-only,tlb-rmi,tracev8.4,uaops,use-postra-scheduler,v8.1a,v8.2a,v8.3a,v8.4a,v8.5a,v8.6a,v8a,vh") },
	{ str_lit("ampere1a"), str_lit("CONTEXTIDREL2,addr-lsl-fast,aes,aggressive-fma,altnzcv,alu-lsl-fast,am,ampere1a,amvs,arith-bcc-fusion,bf16,bti,ccdp,ccidx,ccpp,cmp-bcc-fusion,complxnum,crc,dit,dotprod,ecv,el2vmsa,el3,fgt,flagm,fp-armv8,fptoint,fuse-address,fuse-aes,fuse-literals,i8mm,jsconv,ldp-aligned-only,lor,lse,lse2,mpam,mte,neon,nv,pan,pan-rwv,pauth,perfmon,predres,rand,ras,rcpc,rcpc-immo,rdm,sb,sel2,sha2,sha3,sm4,specrestrict,ssbs,store-pair-suppress,stp-aligned-only,tlb-rmi,tracev8.4,uaops,use-postra-scheduler,v8.1a,v8.2a,v8.3a,v8.4a,v8.5a,v8.6a,v8a,vh") },
	{ str_lit("apple-a10"), str_lit("CONTEXTIDREL2,aes,alternate-sextload-cvt-f32-pattern,apple-a10,arith-bcc-fusion,arith-cbz-fusion,crc,crypto,disable-latency-sched-heuristic,el2vmsa,el3,fp-armv8,fuse-aes,fuse-crypto-eor,lor,neon,pan,perfmon,rdm,sha2,store-pair-suppress,v8a,vh,zcm,zcz,zcz-gp") },
	{ str_lit("apple-a11"), str_lit("CONTEXTIDREL2,aes,alternate-sextload-cvt-f32-pattern,apple-a11,arith-bcc-fusion,arith-cbz-fusion,ccpp,crc,crypto,disable-latency-sched-heuristic,el2vmsa,el3,fp-armv8,fullfp16,fuse-aes,fuse-crypto-eor,lor,lse,neon,pan,pan-rwv,perfmon,ras,rdm,sha2,store-pair-suppress,uaops,v8.1a,v8.2a,v8a,vh,zcm,zcz,zcz-gp") },
	{ str_lit("apple-a12"), str_lit("CONTEXTIDREL2,aes,alternate-sextload-cvt-f32-pattern,apple-a12,arith-bcc-fusion,arith-cbz-fusion,ccidx,ccpp,complxnum,crc,crypto,disable-latency-sched-heuristic,el2vmsa,el3,fp-armv8,fullfp16,fuse-aes,fuse-crypto-eor,jsconv,lor,lse,neon,pan,pan-rwv,pauth,perfmon,ras,rcpc,rdm,sha2,store-pair-suppress,uaops,v8.1a,v8.2a,v8.3a,v8a,vh,zcm,zcz,zcz-gp") },
	{ str_lit("apple-a13"), str_lit("CONTEXTIDREL2,aes,alternate-sextload-cvt-f32-pattern,am,apple-a13,arith-bcc-fusion,arith-cbz-fusion,ccidx,ccpp,complxnum,crc,crypto,disable-latency-sched-heuristic,dit,dotprod,el2vmsa,el3,flagm,fp-armv8,fp16fml,fullfp16,fuse-aes,fuse-crypto-eor,jsconv,lor,lse,lse2,mpam,neon,nv,pan,pan-rwv,pauth,perfmon,ras,rcpc,rcpc-immo,rdm,sel2,sha2,sha3,store-pair-suppress,tlb-rmi,tracev8.4,uaops,v8.1a,v8.2a,v8.3a,v8.4a,v8a,vh,zcm,zcz,zcz-gp") },
	{ str_lit("apple-a14"), str_lit("CONTEXTIDREL2,aes,aggressive-fma,alternate-sextload-cvt-f32-pattern,altnzcv,am,apple-a14,arith-bcc-fusion,arith-cbz-fusion,ccdp,ccidx,ccpp,complxnum,crc,crypto,disable-latency-sched-heuristic,dit,dotprod,el2vmsa,el3,flagm,fp-armv8,fp16fml,fptoint,fullfp16,fuse-address,fuse-adrp-add,fuse-aes,fuse-arith-logic,fuse-crypto-eor,fuse-csel,fuse-literals,jsconv,lor,lse,lse2,mpam,neon,nv,pan,pan-rwv,pauth,perfmon,predres,ras,rcpc,rcpc-immo,rdm,sb,sel2,sha2,sha3,specrestrict,ssbs,store-pair-suppress,tlb-rmi,tracev8.4,uaops,v8.1a,v8.2a,v8.3a,v8.4a,v8a,vh,zcm,zcz,zcz-gp") },
	{ str_lit("apple-a15"), str_lit("CONTEXTIDREL2,aes,alternate-sextload-cvt-f32-pattern,altnzcv,am,amvs,apple-a15,arith-bcc-fusion,arith-cbz-fusion,bf16,bti,ccdp,ccidx,ccpp,complxnum,crc,crypto,disable-latency-sched-heuristic,dit,dotprod,ecv,el2vmsa,el3,fgt,flagm,fp-armv8,fp16fml,fptoint,fullfp16,fuse-address,fuse-aes,fuse-arith-logic,fuse-crypto-eor,fuse-csel,fuse-literals,i8mm,jsconv,lor,lse,lse2,mpam,neon,nv,pan,pan-rwv,pauth,perfmon,predres,ras,rcpc,rcpc-immo,rdm,sb,sel2,sha2,sha3,specrestrict,ssbs,store-pair-suppress,tlb-rmi,tracev8.4,uaops,v8.1a,v8.2a,v8.3a,v8.4a,v8.5a,v8.6a,v8a,vh,zcm,zcz,zcz-gp") },
	{ str_lit("apple-a16"), str_lit("CONTEXTIDREL2,aes,alternate-sextload-cvt-f32-pattern,altnzcv,am,amvs,apple-a16,arith-bcc-fusion,arith-cbz-fusion,bf16,bti,ccdp,ccidx,ccpp,complxnum,crc,crypto,disable-latency-sched-heuristic,dit,dotprod,ecv,el2vmsa,el3,fgt,flagm,fp-armv8,fp16fml,fptoint,fullfp16,fuse-address,fuse-aes,fuse-arith-logic,fuse-crypto-eor,fuse-csel,fuse-literals,hcx,i8mm,jsconv,lor,lse,lse2,mpam,neon,nv,pan,pan-rwv,pauth,perfmon,predres,ras,rcpc,rcpc-immo,rdm,sb,sel2,sha2,sha3,specrestrict,ssbs,store-pair-suppress,tlb-rmi,tracev8.4,uaops,v8.1a,v8.2a,v8.3a,v8.4a,v8.5a,v8.6a,v8a,vh,zcm,zcz,zcz-gp") },
	{ str_lit("apple-a7"), str_lit("aes,alternate-sextload-cvt-f32-pattern,apple-a7,apple-a7-sysreg,arith-bcc-fusion,arith-cbz-fusion,crypto,disable-latency-sched-heuristic,el2vmsa,el3,fp-armv8,fuse-aes,fuse-crypto-eor,neon,perfmon,sha2,store-pair-suppress,v8a,zcm,zcz,zcz-fp-workaround,zcz-gp") },
	{ str_lit("apple-a8"), str_lit("aes,alternate-sextload-cvt-f32-pattern,apple-a7,apple-a7-sysreg,arith-bcc-fusion,arith-cbz-fusion,crypto,disable-latency-sched-heuristic,el2vmsa,el3,fp-armv8,fuse-aes,fuse-crypto-eor,neon,perfmon,sha2,store-pair-suppress,v8a,zcm,zcz,zcz-fp-workaround,zcz-gp") },
	{ str_lit("apple-a9"), str_lit("aes,alternate-sextload-cvt-f32-pattern,apple-a7,apple-a7-sysreg,arith-bcc-fusion,arith-cbz-fusion,crypto,disable-latency-sched-heuristic,el2vmsa,el3,fp-armv8,fuse-aes,fuse-crypto-eor,neon,perfmon,sha2,store-pair-suppress,v8a,zcm,zcz,zcz-fp-workaround,zcz-gp") },
	{ str_lit("apple-latest"), str_lit("CONTEXTIDREL2,aes,alternate-sextload-cvt-f32-pattern,altnzcv,am,amvs,apple-a16,arith-bcc-fusion,arith-cbz-fusion,bf16,bti,ccdp,ccidx,ccpp,complxnum,crc,crypto,disable-latency-sched-heuristic,dit,dotprod,ecv,el2vmsa,el3,fgt,flagm,fp-armv8,fp16fml,fptoint,fullfp16,fuse-address,fuse-aes,fuse-arith-logic,fuse-crypto-eor,fuse-csel,fuse-literals,hcx,i8mm,jsconv,lor,lse,lse2,mpam,neon,nv,pan,pan-rwv,pauth,perfmon,predres,ras,rcpc,rcpc-immo,rdm,sb,sel2,sha2,sha3,specrestrict,ssbs,store-pair-suppress,tlb-rmi,tracev8.4,uaops,v8.1a,v8.2a,v8.3a,v8.4a,v8.5a,v8.6a,v8a,vh,zcm,zcz,zcz-gp") },
	{ str_lit("apple-m1"), str_lit("CONTEXTIDREL2,aes,aggressive-fma,alternate-sextload-cvt-f32-pattern,altnzcv,am,apple-a14,arith-bcc-fusion,arith-cbz-fusion,ccdp,ccidx,ccpp,complxnum,crc,crypto,disable-latency-sched-heuristic,dit,dotprod,el2vmsa,el3,flagm,fp-armv8,fp16fml,fptoint,fullfp16,fuse-address,fuse-adrp-add,fuse-aes,fuse-arith-logic,fuse-crypto-eor,fuse-csel,fuse-literals,jsconv,lor,lse,lse2,mpam,neon,nv,pan,pan-rwv,pauth,perfmon,predres,ras,rcpc,rcpc-immo,rdm,sb,sel2,sha2,sha3,specrestrict,ssbs,store-pair-suppress,tlb-rmi,tracev8.4,uaops,v8.1a,v8.2a,v8.3a,v8.4a,v8a,vh,zcm,zcz,zcz-gp") },
	{ str_lit("apple-m2"), str_lit("CONTEXTIDREL2,aes,alternate-sextload-cvt-f32-pattern,altnzcv,am,amvs,apple-a15,arith-bcc-fusion,arith-cbz-fusion,bf16,bti,ccdp,ccidx,ccpp,complxnum,crc,crypto,disable-latency-sched-heuristic,dit,dotprod,ecv,el2vmsa,el3,fgt,flagm,fp-armv8,fp16fml,fptoint,fullfp16,fuse-address,fuse-aes,fuse-arith-logic,fuse-crypto-eor,fuse-csel,fuse-literals,i8mm,jsconv,lor,lse,lse2,mpam,neon,nv,pan,pan-rwv,pauth,perfmon,predres,ras,rcpc,rcpc-immo,rdm,sb,sel2,sha2,sha3,specrestrict,ssbs,store-pair-suppress,tlb-rmi,tracev8.4,uaops,v8.1a,v8.2a,v8.3a,v8.4a,v8.5a,v8.6a,v8a,vh,zcm,zcz,zcz-gp") },
	{ str_lit("apple-s4"), str_lit("CONTEXTIDREL2,aes,alternate-sextload-cvt-f32-pattern,apple-a12,arith-bcc-fusion,arith-cbz-fusion,ccidx,ccpp,complxnum,crc,crypto,disable-latency-sched-heuristic,el2vmsa,el3,fp-armv8,fullfp16,fuse-aes,fuse-crypto-eor,jsconv,lor,lse,neon,pan,pan-rwv,pauth,perfmon,ras,rcpc,rdm,sha2,store-pair-suppress,uaops,v8.1a,v8.2a,v8.3a,v8a,vh,zcm,zcz,zcz-gp") },
	{ str_lit("apple-s5"), str_lit("CONTEXTIDREL2,aes,alternate-sextload-cvt-f32-pattern,apple-a12,arith-bcc-fusion,arith-cbz-fusion,ccidx,ccpp,complxnum,crc,crypto,disable-latency-sched-heuristic,el2vmsa,el3,fp-armv8,fullfp16,fuse-aes,fuse-crypto-eor,jsconv,lor,lse,neon,pan,pan-rwv,pauth,perfmon,ras,rcpc,rdm,sha2,store-pair-suppress,uaops,v8.1a,v8.2a,v8.3a,v8a,vh,zcm,zcz,zcz-gp") },
	{ str_lit("carmel"), str_lit("CONTEXTIDREL2,aes,carmel,ccpp,crc,crypto,el2vmsa,el3,fp-armv8,fullfp16,lor,lse,neon,pan,pan-rwv,ras,rdm,sha2,uaops,v8.1a,v8.2a,v8a,vh") },
	{ str_lit("cortex-a34"), str_lit("a35,aes,crc,crypto,el2vmsa,el3,fp-armv8,neon,perfmon,sha2,v8a") },
	{ str_lit("cortex-a35"), str_lit("a35,aes,crc,crypto,el2vmsa,el3,fp-armv8,neon,perfmon,sha2,v8a") },
	{ str_lit("cortex-a510"), str_lit("CONTEXTIDREL2,a510,altnzcv,am,bf16,bti,ccdp,ccidx,ccpp,complxnum,crc,dit,dotprod,el2vmsa,el3,ete,flagm,fp-armv8,fp16fml,fptoint,fullfp16,fuse-adrp-add,fuse-aes,i8mm,jsconv,lor,lse,lse2,mec,mpam,mte,neon,nv,pan,pan-rwv,pauth,perfmon,predres,ras,rcpc,rcpc-immo,rdm,rme,sb,sel2,specrestrict,ssbs,sve,sve2,sve2-bitperm,tlb-rmi,tracev8.4,trbe,uaops,use-postra-scheduler,use-scalar-inc-vl,v8.1a,v8.2a,v8.3a,v8.4a,v8.5a,v8a,v9a,vh") },
	{ str_lit("cortex-a53"), str_lit("a53,aes,balance-fp-ops,crc,crypto,el2vmsa,el3,fp-armv8,fuse-adrp-add,fuse-aes,neon,perfmon,sha2,use-postra-scheduler,v8a") },
	{ str_lit("cortex-a55"), str_lit("CONTEXTIDREL2,a55,aes,ccpp,crc,crypto,dotprod,el2vmsa,el3,fp-armv8,fullfp16,fuse-address,fuse-adrp-add,fuse-aes,lor,lse,neon,pan,pan-rwv,perfmon,ras,rcpc,rdm,sha2,uaops,use-postra-scheduler,v8.1a,v8.2a,v8a,vh") },
	{ str_lit("cortex-a57"), str_lit("a57,aes,balance-fp-ops,crc,crypto,el2vmsa,el3,enable-select-opt,fp-armv8,fuse-adrp-add,fuse-aes,fuse-literals,neon,perfmon,predictable-select-expensive,sha2,use-postra-scheduler,v8a") },
	{ str_lit("cortex-a65"), str_lit("CONTEXTIDREL2,a65,aes,ccpp,crc,crypto,dotprod,el2vmsa,el3,enable-select-opt,fp-armv8,fullfp16,fuse-address,fuse-adrp-add,fuse-aes,fuse-literals,lor,lse,neon,pan,pan-rwv,perfmon,predictable-select-expensive,ras,rcpc,rdm,sha2,ssbs,uaops,v8.1a,v8.2a,v8a,vh") },
	{ str_lit("cortex-a65ae"), str_lit("CONTEXTIDREL2,a65,aes,ccpp,crc,crypto,dotprod,el2vmsa,el3,enable-select-opt,fp-armv8,fullfp16,fuse-address,fuse-adrp-add,fuse-aes,fuse-literals,lor,lse,neon,pan,pan-rwv,perfmon,predictable-select-expensive,ras,rcpc,rdm,sha2,ssbs,uaops,v8.1a,v8.2a,v8a,vh") },
	{ str_lit("cortex-a710"), str_lit("CONTEXTIDREL2,a710,addr-lsl-fast,altnzcv,alu-lsl-fast,am,bf16,bti,ccdp,ccidx,ccpp,cmp-bcc-fusion,complxnum,crc,dit,dotprod,el2vmsa,el3,enable-select-opt,ete,flagm,fp-armv8,fp16fml,fptoint,fullfp16,fuse-adrp-add,fuse-aes,i8mm,jsconv,lor,lse,lse2,mec,mpam,mte,neon,nv,pan,pan-rwv,pauth,perfmon,predictable-select-expensive,predres,ras,rcpc,rcpc-immo,rdm,rme,sb,sel2,specrestrict,ssbs,sve,sve2,sve2-bitperm,tlb-rmi,tracev8.4,trbe,uaops,use-postra-scheduler,use-scalar-inc-vl,v8.1a,v8.2a,v8.3a,v8.4a,v8.5a,v8a,v9a,vh") },
	{ str_lit("cortex-a715"), str_lit("CONTEXTIDREL2,a715,addr-lsl-fast,altnzcv,alu-lsl-fast,am,bf16,bti,ccdp,ccidx,ccpp,cmp-bcc-fusion,complxnum,crc,dit,dotprod,el2vmsa,el3,enable-select-opt,ete,flagm,fp-armv8,fp16fml,fptoint,fullfp16,fuse-adrp-add,fuse-aes,i8mm,jsconv,lor,lse,lse2,mec,mpam,mte,neon,nv,pan,pan-rwv,pauth,perfmon,predictable-select-expensive,predres,ras,rcpc,rcpc-immo,rdm,rme,sb,sel2,spe,specrestrict,ssbs,sve,sve2,sve2-bitperm,tlb-rmi,tracev8.4,trbe,uaops,use-postra-scheduler,use-scalar-inc-vl,v8.1a,v8.2a,v8.3a,v8.4a,v8.5a,v8a,v9a,vh") },
	{ str_lit("cortex-a72"), str_lit("a72,aes,crc,crypto,el2vmsa,el3,enable-select-opt,fp-armv8,fuse-adrp-add,fuse-aes,fuse-literals,neon,perfmon,predictable-select-expensive,sha2,v8a") },
	{ str_lit("cortex-a73"), str_lit("a73,aes,crc,crypto,el2vmsa,el3,enable-select-opt,fp-armv8,fuse-adrp-add,fuse-aes,neon,perfmon,predictable-select-expensive,sha2,v8a") },
	{ str_lit("cortex-a75"), str_lit("CONTEXTIDREL2,a75,aes,ccpp,crc,crypto,dotprod,el2vmsa,el3,enable-select-opt,fp-armv8,fullfp16,fuse-adrp-add,fuse-aes,lor,lse,neon,pan,pan-rwv,perfmon,predictable-select-expensive,ras,rcpc,rdm,sha2,uaops,v8.1a,v8.2a,v8a,vh") },
	{ str_lit("cortex-a76"), str_lit("CONTEXTIDREL2,a76,addr-lsl-fast,aes,alu-lsl-fast,ccpp,crc,crypto,dotprod,el2vmsa,el3,enable-select-opt,fp-armv8,fullfp16,fuse-adrp-add,fuse-aes,lor,lse,neon,pan,pan-rwv,perfmon,predictable-select-expensive,ras,rcpc,rdm,sha2,ssbs,uaops,v8.1a,v8.2a,v8a,vh") },
	{ str_lit("cortex-a76ae"), str_lit("CONTEXTIDREL2,a76,addr-lsl-fast,aes,alu-lsl-fast,ccpp,crc,crypto,dotprod,el2vmsa,el3,enable-select-opt,fp-armv8,fullfp16,fuse-adrp-add,fuse-aes,lor,lse,neon,pan,pan-rwv,perfmon,predictable-select-expensive,ras,rcpc,rdm,sha2,ssbs,uaops,v8.1a,v8.2a,v8a,vh") },
	{ str_lit("cortex-a77"), str_lit("CONTEXTIDREL2,a77,addr-lsl-fast,aes,alu-lsl-fast,ccpp,cmp-bcc-fusion,crc,crypto,dotprod,el2vmsa,el3,enable-select-opt,fp-armv8,fullfp16,fuse-adrp-add,fuse-aes,lor,lse,neon,pan,pan-rwv,perfmon,predictable-select-expensive,ras,rcpc,rdm,sha2,ssbs,uaops,v8.1a,v8.2a,v8a,vh") },
	{ str_lit("cortex-a78"), str_lit("CONTEXTIDREL2,a78,addr-lsl-fast,aes,alu-lsl-fast,ccpp,cmp-bcc-fusion,crc,crypto,dotprod,el2vmsa,el3,enable-select-opt,fp-armv8,fullfp16,fuse-adrp-add,fuse-aes,lor,lse,neon,pan,pan-rwv,perfmon,predictable-select-expensive,ras,rcpc,rdm,sha2,spe,ssbs,uaops,use-postra-scheduler,v8.1a,v8.2a,v8a,vh") },
	{ str_lit("cortex-a78c"), str_lit("CONTEXTIDREL2,a78c,addr-lsl-fast,aes,alu-lsl-fast,ccpp,cmp-bcc-fusion,crc,crypto,dotprod,el2vmsa,el3,enable-select-opt,flagm,fp-armv8,fullfp16,fuse-adrp-add,fuse-aes,lor,lse,neon,pan,pan-rwv,pauth,perfmon,predictable-select-expensive,ras,rcpc,rdm,sha2,spe,ssbs,uaops,use-postra-scheduler,v8.1a,v8.2a,v8a,vh") },
	{ str_lit("cortex-r82"), str_lit("CONTEXTIDREL2,ccidx,ccpp,complxnum,cortex-r82,crc,dit,dotprod,flagm,fp-armv8,fp16fml,fullfp16,jsconv,lse,neon,pan,pan-rwv,pauth,perfmon,predres,ras,rcpc,rcpc-immo,rdm,sb,sel2,specrestrict,ssbs,tlb-rmi,tracev8.4,uaops,use-postra-scheduler,v8r") },
	{ str_lit("cortex-x1"), str_lit("CONTEXTIDREL2,addr-lsl-fast,aes,alu-lsl-fast,ccpp,cmp-bcc-fusion,cortex-x1,crc,crypto,dotprod,el2vmsa,el3,enable-select-opt,fp-armv8,fullfp16,fuse-adrp-add,fuse-aes,lor,lse,neon,pan,pan-rwv,perfmon,predictable-select-expensive,ras,rcpc,rdm,sha2,spe,ssbs,uaops,use-postra-scheduler,v8.1a,v8.2a,v8a,vh") },
	{ str_lit("cortex-x1c"), str_lit("CONTEXTIDREL2,addr-lsl-fast,aes,alu-lsl-fast,ccpp,cmp-bcc-fusion,cortex-x1,crc,crypto,dotprod,el2vmsa,el3,enable-select-opt,flagm,fp-armv8,fullfp16,fuse-adrp-add,fuse-aes,lor,lse,lse2,neon,pan,pan-rwv,pauth,perfmon,predictable-select-expensive,ras,rcpc,rcpc-immo,rdm,sha2,spe,ssbs,uaops,use-postra-scheduler,v8.1a,v8.2a,v8a,vh") },
	{ str_lit("cortex-x2"), str_lit("CONTEXTIDREL2,addr-lsl-fast,altnzcv,alu-lsl-fast,am,bf16,bti,ccdp,ccidx,ccpp,cmp-bcc-fusion,complxnum,cortex-x2,crc,dit,dotprod,el2vmsa,el3,enable-select-opt,ete,flagm,fp-armv8,fp16fml,fptoint,fullfp16,fuse-adrp-add,fuse-aes,i8mm,jsconv,lor,lse,lse2,mec,mpam,mte,neon,nv,pan,pan-rwv,pauth,perfmon,predictable-select-expensive,predres,ras,rcpc,rcpc-immo,rdm,rme,sb,sel2,specrestrict,ssbs,sve,sve2,sve2-bitperm,tlb-rmi,tracev8.4,trbe,uaops,use-postra-scheduler,use-scalar-inc-vl,v8.1a,v8.2a,v8.3a,v8.4a,v8.5a,v8a,v9a,vh") },
	{ str_lit("cortex-x3"), str_lit("CONTEXTIDREL2,addr-lsl-fast,altnzcv,alu-lsl-fast,am,bf16,bti,ccdp,ccidx,ccpp,complxnum,cortex-x3,crc,dit,dotprod,el2vmsa,el3,enable-select-opt,ete,flagm,fp-armv8,fp16fml,fptoint,fullfp16,fuse-adrp-add,fuse-aes,i8mm,jsconv,lor,lse,lse2,mec,mpam,mte,neon,nv,pan,pan-rwv,pauth,perfmon,predictable-select-expensive,predres,ras,rcpc,rcpc-immo,rdm,rme,sb,sel2,spe,specrestrict,ssbs,sve,sve2,sve2-bitperm,tlb-rmi,tracev8.4,trbe,uaops,use-postra-scheduler,use-scalar-inc-vl,v8.1a,v8.2a,v8.3a,v8.4a,v8.5a,v8a,v9a,vh") },
	{ str_lit("cyclone"), str_lit("aes,alternate-sextload-cvt-f32-pattern,apple-a7,apple-a7-sysreg,arith-bcc-fusion,arith-cbz-fusion,crypto,disable-latency-sched-heuristic,el2vmsa,el3,fp-armv8,fuse-aes,fuse-crypto-eor,neon,perfmon,sha2,store-pair-suppress,v8a,zcm,zcz,zcz-fp-workaround,zcz-gp") },
	{ str_lit("exynos-m3"), str_lit("addr-lsl-fast,aes,alu-lsl-fast,crc,crypto,el2vmsa,el3,exynos-cheap-as-move,exynosm3,force-32bit-jump-tables,fp-armv8,fuse-address,fuse-adrp-add,fuse-aes,fuse-csel,fuse-literals,neon,perfmon,predictable-select-expensive,sha2,store-pair-suppress,use-postra-scheduler,v8a") },
	{ str_lit("exynos-m4"), str_lit("CONTEXTIDREL2,addr-lsl-fast,aes,alu-lsl-fast,arith-bcc-fusion,arith-cbz-fusion,ccpp,crc,crypto,dotprod,el2vmsa,el3,exynos-cheap-as-move,exynosm4,force-32bit-jump-tables,fp-armv8,fullfp16,fuse-address,fuse-adrp-add,fuse-aes,fuse-arith-logic,fuse-csel,fuse-literals,lor,lse,neon,pan,pan-rwv,perfmon,ras,rdm,sha2,store-pair-suppress,uaops,use-postra-scheduler,v8.1a,v8.2a,v8a,vh,zcz,zcz-gp") },
	{ str_lit("exynos-m5"), str_lit("CONTEXTIDREL2,addr-lsl-fast,aes,alu-lsl-fast,arith-bcc-fusion,arith-cbz-fusion,ccpp,crc,crypto,dotprod,el2vmsa,el3,exynos-cheap-as-move,exynosm4,force-32bit-jump-tables,fp-armv8,fullfp16,fuse-address,fuse-adrp-add,fuse-aes,fuse-arith-logic,fuse-csel,fuse-literals,lor,lse,neon,pan,pan-rwv,perfmon,ras,rdm,sha2,store-pair-suppress,uaops,use-postra-scheduler,v8.1a,v8.2a,v8a,vh,zcz,zcz-gp") },
	{ str_lit("falkor"), str_lit("addr-lsl-fast,aes,alu-lsl-fast,crc,crypto,el2vmsa,el3,falkor,fp-armv8,neon,perfmon,predictable-select-expensive,rdm,sha2,slow-strqro-store,store-pair-suppress,use-postra-scheduler,v8a,zcz,zcz-gp") },
	{ str_lit("generic"), str_lit("enable-select-opt,ete,fp-armv8,fuse-adrp-add,fuse-aes,neon,trbe,use-postra-scheduler") },
	{ str_lit("kryo"), str_lit("addr-lsl-fast,aes,alu-lsl-fast,crc,crypto,el2vmsa,el3,fp-armv8,kryo,neon,perfmon,predictable-select-expensive,sha2,store-pair-suppress,use-postra-scheduler,v8a,zcz,zcz-gp") },
	{ str_lit("neoverse-512tvb"), str_lit("CONTEXTIDREL2,addr-lsl-fast,aes,alu-lsl-fast,am,bf16,ccdp,ccidx,ccpp,complxnum,crc,crypto,dit,dotprod,el2vmsa,el3,enable-select-opt,flagm,fp-armv8,fp16fml,fullfp16,fuse-adrp-add,fuse-aes,i8mm,jsconv,lor,lse,lse2,mpam,neon,neoverse512tvb,nv,pan,pan-rwv,pauth,perfmon,predictable-select-expensive,rand,ras,rcpc,rcpc-immo,rdm,sel2,sha2,spe,ssbs,sve,tlb-rmi,tracev8.4,uaops,use-postra-scheduler,v8.1a,v8.2a,v8.3a,v8.4a,v8a,vh") },
	{ str_lit("neoverse-e1"), str_lit("CONTEXTIDREL2,aes,ccpp,crc,crypto,dotprod,el2vmsa,el3,fp-armv8,fullfp16,fuse-adrp-add,fuse-aes,lor,lse,neon,neoversee1,pan,pan-rwv,perfmon,ras,rcpc,rdm,sha2,ssbs,uaops,use-postra-scheduler,v8.1a,v8.2a,v8a,vh") },
	{ str_lit("neoverse-n1"), str_lit("CONTEXTIDREL2,addr-lsl-fast,aes,alu-lsl-fast,ccpp,crc,crypto,dotprod,el2vmsa,el3,enable-select-opt,fp-armv8,fullfp16,fuse-adrp-add,fuse-aes,lor,lse,neon,neoversen1,pan,pan-rwv,perfmon,predictable-select-expensive,ras,rcpc,rdm,sha2,spe,ssbs,uaops,use-postra-scheduler,v8.1a,v8.2a,v8a,vh") },
	{ str_lit("neoverse-n2"), str_lit("CONTEXTIDREL2,addr-lsl-fast,altnzcv,alu-lsl-fast,am,bf16,bti,ccdp,ccidx,ccpp,complxnum,crc,dit,dotprod,el2vmsa,el3,enable-select-opt,ete,flagm,fp-armv8,fptoint,fullfp16,fuse-adrp-add,fuse-aes,i8mm,jsconv,lor,lse,lse2,mec,mpam,mte,neon,neoversen2,nv,pan,pan-rwv,pauth,perfmon,predictable-select-expensive,predres,ras,rcpc,rcpc-immo,rdm,rme,sb,sel2,specrestrict,ssbs,sve,sve2,sve2-bitperm,tlb-rmi,tracev8.4,trbe,uaops,use-postra-scheduler,use-scalar-inc-vl,v8.1a,v8.2a,v8.3a,v8.4a,v8.5a,v8a,v9a,vh") },
	{ str_lit("neoverse-v1"), str_lit("CONTEXTIDREL2,addr-lsl-fast,aes,alu-lsl-fast,am,bf16,ccdp,ccidx,ccpp,complxnum,crc,crypto,dit,dotprod,el2vmsa,el3,enable-select-opt,flagm,fp-armv8,fp16fml,fullfp16,fuse-adrp-add,fuse-aes,i8mm,jsconv,lor,lse,lse2,mpam,neon,neoversev1,no-sve-fp-ld1r,nv,pan,pan-rwv,pauth,perfmon,predictable-select-expensive,rand,ras,rcpc,rcpc-immo,rdm,sel2,sha2,spe,ssbs,sve,tlb-rmi,tracev8.4,uaops,use-postra-scheduler,v8.1a,v8.2a,v8.3a,v8.4a,v8a,vh") },
	{ str_lit("neoverse-v2"), str_lit("CONTEXTIDREL2,addr-lsl-fast,altnzcv,alu-lsl-fast,am,bf16,bti,ccdp,ccidx,ccpp,complxnum,crc,dit,dotprod,el2vmsa,el3,enable-select-opt,ete,flagm,fp-armv8,fp16fml,fptoint,fullfp16,fuse-adrp-add,fuse-aes,i8mm,jsconv,lor,lse,lse2,mec,mpam,mte,neon,neoversev2,nv,pan,pan-rwv,pauth,perfmon,predictable-select-expensive,predres,rand,ras,rcpc,rcpc-immo,rdm,rme,sb,sel2,spe,specrestrict,ssbs,sve,sve2,sve2-bitperm,tlb-rmi,tracev8.4,trbe,uaops,use-postra-scheduler,use-scalar-inc-vl,v8.1a,v8.2a,v8.3a,v8.4a,v8.5a,v8a,v9a,vh") },
	{ str_lit("saphira"), str_lit("CONTEXTIDREL2,addr-lsl-fast,aes,alu-lsl-fast,am,ccidx,ccpp,complxnum,crc,crypto,dit,dotprod,el2vmsa,el3,flagm,fp-armv8,jsconv,lor,lse,lse2,mpam,neon,nv,pan,pan-rwv,pauth,perfmon,predictable-select-expensive,ras,rcpc,rcpc-immo,rdm,saphira,sel2,sha2,spe,store-pair-suppress,tlb-rmi,tracev8.4,uaops,use-postra-scheduler,v8.1a,v8.2a,v8.3a,v8.4a,v8a,vh,zcz,zcz-gp") },
	{ str_lit("thunderx"), str_lit("aes,crc,crypto,el2vmsa,el3,fp-armv8,neon,perfmon,predictable-select-expensive,sha2,store-pair-suppress,thunderx,use-postra-scheduler,v8a") },
	{ str_lit("thunderx2t99"), str_lit("CONTEXTIDREL2,aes,aggressive-fma,arith-bcc-fusion,crc,crypto,el2vmsa,el3,fp-armv8,lor,lse,neon,pan,predictable-select-expensive,rdm,sha2,store-pair-suppress,thunderx2t99,use-postra-scheduler,v8.1a,v8a,vh") },
	{ str_lit("thunderx3t110"), str_lit("CONTEXTIDREL2,aes,aggressive-fma,arith-bcc-fusion,balance-fp-ops,ccidx,ccpp,complxnum,crc,crypto,el2vmsa,el3,fp-armv8,jsconv,lor,lse,neon,pan,pan-rwv,pauth,perfmon,predictable-select-expensive,ras,rcpc,rdm,sha2,store-pair-suppress,strict-align,thunderx3t110,uaops,use-postra-scheduler,v8.1a,v8.2a,v8.3a,v8a,vh") },
	{ str_lit("thunderxt81"), str_lit("aes,crc,crypto,el2vmsa,el3,fp-armv8,neon,perfmon,predictable-select-expensive,sha2,store-pair-suppress,thunderxt81,use-postra-scheduler,v8a") },
	{ str_lit("thunderxt83"), str_lit("aes,crc,crypto,el2vmsa,el3,fp-armv8,neon,perfmon,predictable-select-expensive,sha2,store-pair-suppress,thunderxt83,use-postra-scheduler,v8a") },
	{ str_lit("thunderxt88"), str_lit("aes,crc,crypto,el2vmsa,el3,fp-armv8,neon,perfmon,predictable-select-expensive,sha2,store-pair-suppress,thunderxt88,use-postra-scheduler,v8a") },
	{ str_lit("tsv110"), str_lit("CONTEXTIDREL2,aes,ccpp,complxnum,crc,crypto,dotprod,el2vmsa,el3,fp-armv8,fp16fml,fullfp16,fuse-aes,jsconv,lor,lse,neon,pan,pan-rwv,perfmon,ras,rdm,sha2,spe,store-pair-suppress,tsv110,uaops,use-postra-scheduler,v8.1a,v8.2a,v8a,vh") },
	// TargetArch_wasm32:
	{ str_lit("bleeding-edge"), str_lit("atomics,bulk-memory,mutable-globals,nontrapping-fptoint,sign-ext,simd128,tail-call") },
	{ str_lit("generic"), str_lit("mutable-globals,sign-ext") },
	{ str_lit("mvp"), str_lit("") },
	// TargetArch_wasm64p32:
	{ str_lit("bleeding-edge"), str_lit("atomics,bulk-memory,mutable-globals,nontrapping-fptoint,sign-ext,simd128,tail-call") },
	{ str_lit("generic"), str_lit("mutable-globals,sign-ext") },
	{ str_lit("mvp"), str_lit("") },
};

gb_global String target_endian_names[TargetEndian_COUNT] = {
	str_lit("little"),
	str_lit("big"),
};

gb_global String target_abi_names[TargetABI_COUNT] = {
	str_lit(""),
	str_lit("win64"),
	str_lit("sysv"),
};

gb_global TargetEndianKind target_endians[TargetArch_COUNT] = {
	TargetEndian_Little,
	TargetEndian_Little,
	TargetEndian_Little,
	TargetEndian_Little,
	TargetEndian_Little,
	TargetEndian_Little,
	TargetEndian_Little,
};

gb_global String windows_subsystem_names[Windows_Subsystem_COUNT] = {
	str_lit("BOOT_APPLICATION"),
	str_lit("CONSOLE"),                 // Default
	str_lit("EFI_APPLICATION"),
	str_lit("EFI_BOOT_SERVICE_DRIVER"),
	str_lit("EFI_ROM"),
	str_lit("EFI_RUNTIME_DRIVER"),
	str_lit("NATIVE"),
	str_lit("POSIX"),
	str_lit("WINDOWS"),
	str_lit("WINDOWSCE"),
};

#ifndef ODIN_VERSION_RAW
#define ODIN_VERSION_RAW "dev-unknown-unknown"
#endif

gb_global String const ODIN_VERSION = str_lit(ODIN_VERSION_RAW);

struct TargetMetrics {
	TargetOsKind   os;
	TargetArchKind arch;
	isize          ptr_size;
	isize          int_size;
	isize          max_align;
	isize          max_simd_align;
	String         target_triplet;
	TargetABIKind  abi;
};

enum Subtarget : u32 {
	Subtarget_Default,
	Subtarget_iOS,

	Subtarget_COUNT,
};

gb_global String subtarget_strings[Subtarget_COUNT] = {
	str_lit(""),
	str_lit("ios"),
};


enum QueryDataSetKind {
	QueryDataSet_Invalid,
	QueryDataSet_GlobalDefinitions,
	QueryDataSet_GoToDefinitions,
};

struct QueryDataSetSettings {
	QueryDataSetKind kind;
	bool ok;
	bool compact;
};

enum BuildModeKind {
	BuildMode_Executable,
	BuildMode_DynamicLibrary,
	BuildMode_StaticLibrary,
	BuildMode_Object,
	BuildMode_Assembly,
	BuildMode_LLVM_IR,

	BuildMode_COUNT,
};

enum CommandKind : u32 {
	Command_run             = 1<<0,
	Command_build           = 1<<1,
	Command_check           = 1<<3,
	Command_doc             = 1<<5,
	Command_version         = 1<<6,
	Command_test            = 1<<7,
	
	Command_strip_semicolon = 1<<8,
	Command_bug_report      = 1<<9,

	Command__does_check = Command_run|Command_build|Command_check|Command_doc|Command_test|Command_strip_semicolon,
	Command__does_build = Command_run|Command_build|Command_test,
	Command_all = ~(u32)0,
};

gb_global char const *odin_command_strings[32] = {
	"run",
	"build",
	"check",
	"doc",
	"version",
	"test",
	"strip-semicolon",
};



enum CmdDocFlag : u32 {
	CmdDocFlag_Short       = 1<<0,
	CmdDocFlag_AllPackages = 1<<1,
	CmdDocFlag_DocFormat   = 1<<2,
};

enum TimingsExportFormat : i32 {
	TimingsExportUnspecified = 0,
	TimingsExportJson        = 1,
	TimingsExportCSV         = 2,
};

enum ErrorPosStyle {
	ErrorPosStyle_Default, // path(line:column) msg
	ErrorPosStyle_Unix,    // path:line:column: msg

	ErrorPosStyle_COUNT
};

enum RelocMode : u8 {
	RelocMode_Default,
	RelocMode_Static,
	RelocMode_PIC,
	RelocMode_DynamicNoPIC,
};

enum BuildPath : u8 {
	BuildPath_Main_Package,     // Input  Path to the package directory (or file) we're building.
	BuildPath_RC,               // Input  Path for .rc  file, can be set with `-resource:`.
	BuildPath_RES,              // Output Path for .res file, generated from previous.
	BuildPath_Win_SDK_Bin_Path, // windows_sdk_bin_path
	BuildPath_Win_SDK_UM_Lib,   // windows_sdk_um_library_path
	BuildPath_Win_SDK_UCRT_Lib, // windows_sdk_ucrt_library_path
	BuildPath_VS_EXE,           // vs_exe_path
	BuildPath_VS_LIB,           // vs_library_path

	BuildPath_Output,           // Output Path for .exe, .dll, .so, etc. Can be overridden with `-out:`.
	BuildPath_PDB,              // Output Path for .pdb file, can be overridden with `-pdb-name:`.

	BuildPathCOUNT,
};

enum VetFlags : u64 {
	VetFlag_NONE            = 0,
	VetFlag_Shadowing       = 1u<<0,
	VetFlag_UsingStmt       = 1u<<1,
	VetFlag_UsingParam      = 1u<<2,
	VetFlag_Style           = 1u<<3,
	VetFlag_Semicolon       = 1u<<4,
	VetFlag_UnusedVariables = 1u<<5,
	VetFlag_UnusedImports   = 1u<<6,
	VetFlag_Deprecated      = 1u<<7,

	VetFlag_Unused = VetFlag_UnusedVariables|VetFlag_UnusedImports,

	VetFlag_All = VetFlag_Unused|VetFlag_Shadowing|VetFlag_UsingStmt|VetFlag_Deprecated,

	VetFlag_Using = VetFlag_UsingStmt|VetFlag_UsingParam,
};

u64 get_vet_flag_from_name(String const &name) {
	if (name == "unused") {
		return VetFlag_Unused;
	} else if (name == "unused-variables") {
		return VetFlag_UnusedVariables;
	} else if (name == "unused-imports") {
		return VetFlag_UnusedImports;
	} else if (name == "shadowing") {
		return VetFlag_Shadowing;
	} else if (name == "using-stmt") {
		return VetFlag_UsingStmt;
	} else if (name == "using-param") {
		return VetFlag_UsingParam;
	} else if (name == "style") {
		return VetFlag_Style;
	} else if (name == "semicolon") {
		return VetFlag_Semicolon;
	} else if (name == "deprecated") {
		return VetFlag_Deprecated;
	}
	return VetFlag_NONE;
}


enum SanitizerFlags : u32 {
	SanitizerFlag_NONE = 0,
	SanitizerFlag_Address = 1u<<0,
	SanitizerFlag_Memory  = 1u<<1,
	SanitizerFlag_Thread  = 1u<<2,
};



// This stores the information for the specify architecture of this build
struct BuildContext {
	// Constants
	String ODIN_OS;                       // Target operating system
	String ODIN_ARCH;                     // Target architecture
	String ODIN_VENDOR;                   // Compiler vendor
	String ODIN_VERSION;                  // Compiler version
	String ODIN_ROOT;                     // Odin ROOT
	String ODIN_BUILD_PROJECT_NAME;       // Odin main/initial package's directory name
	String ODIN_WINDOWS_SUBSYSTEM;        // Empty string for non-Windows targets
	bool   ODIN_DEBUG;                    // Odin in debug mode
	bool   ODIN_DISABLE_ASSERT;           // Whether the default 'assert' et al is disabled in code or not
	bool   ODIN_DEFAULT_TO_NIL_ALLOCATOR; // Whether the default allocator is a "nil" allocator or not (i.e. it does nothing)
	bool   ODIN_DEFAULT_TO_PANIC_ALLOCATOR; // Whether the default allocator is a "panic" allocator or not (i.e. panics on any call to it)
	bool   ODIN_FOREIGN_ERROR_PROCEDURES;
	bool   ODIN_VALGRIND_SUPPORT;

	ErrorPosStyle ODIN_ERROR_POS_STYLE;

	TargetEndianKind endian_kind;

	// In bytes
	i64    ptr_size;       // Size of a pointer, must be >= 4
	i64    int_size;       // Size of a int/uint, must be >= 4
	i64    max_align;      // max alignment, must be >= 1 (and typically >= ptr_size)
	i64    max_simd_align; // max alignment, must be >= 1 (and typically >= ptr_size)

	CommandKind command_kind;
	String command;

	TargetMetrics metrics;

	bool show_help;

	Array<Path> build_paths;   // Contains `Path` objects to output filename, pdb, resource and intermediate files.
	                           // BuildPath enum contains the indices of paths we know *before* the work starts.

	String out_filepath;
	String resource_filepath;
	String pdb_filepath;

	u64 vet_flags;
	u32 sanitizer_flags;

	bool   has_resource;
	String link_flags;
	String extra_linker_flags;
	String extra_assembler_flags;
	String microarch;
	BuildModeKind build_mode;
	bool   generate_docs;
	bool   custom_optimization_level;
	i32    optimization_level;
	bool   show_timings;
	TimingsExportFormat export_timings_format;
	String export_timings_file;
	bool   show_unused;
	bool   show_unused_with_location;
	bool   show_more_timings;
	bool   show_system_calls;
	bool   keep_temp_files;
	bool   ignore_unknown_attributes;
	bool   no_bounds_check;
	bool   no_type_assert;
	bool   no_dynamic_literals;
	bool   no_output_files;
	bool   no_crt;
	bool   no_entry_point;
	bool   no_thread_local;
	bool   use_lld;
	bool   cross_compiling;
	bool   different_os;
	bool   keep_object_files;
	bool   disallow_do;

	bool   strict_style;

	bool   ignore_warnings;
	bool   warnings_as_errors;
	bool   hide_error_line;
	bool   terse_errors;
	bool   json_errors;
	bool   has_ansi_terminal_colours;

	bool   ignore_lazy;
	bool   ignore_llvm_build;

	bool   ignore_microsoft_magic;
	bool   linker_map_file;

	bool   use_separate_modules;
	bool   no_threaded_checker;

	bool   show_debug_messages;
	
	bool   copy_file_contents;

	bool   no_rtti;

	bool   dynamic_map_calls;

	bool   obfuscate_source_code_locations;

	bool   min_link_libs;

	RelocMode reloc_mode;
	bool   disable_red_zone;

	isize max_error_count;

	bool tilde_backend;


	u32 cmd_doc_flags;
	Array<String> extra_packages;

	StringSet test_names;
	bool      test_all_packages;

	gbAffinity affinity;
	isize      thread_count;

	PtrMap<char const *, ExactValue> defined_values;

	StringSet target_features_set;
	String target_features_string;
	bool strict_target_features;

	String minimum_os_version_string;
	bool   minimum_os_version_string_given;
};

gb_global BuildContext build_context = {0};

gb_internal bool IS_ODIN_DEBUG(void) {
	return build_context.ODIN_DEBUG;
}


gb_internal bool global_warnings_as_errors(void) {
	return build_context.warnings_as_errors;
}
gb_internal bool global_ignore_warnings(void) {
	return build_context.ignore_warnings;
}

gb_internal isize MAX_ERROR_COLLECTOR_COUNT(void) {
	if (build_context.max_error_count <= 0) {
		return DEFAULT_MAX_ERROR_COLLECTOR_COUNT;
	}
	return build_context.max_error_count;
}

#if defined(GB_SYSTEM_WINDOWS)
	#include <llvm-c/Config/llvm-config.h>
#else
	#include <llvm/Config/llvm-config.h>
#endif

// NOTE: AMD64 targets had their alignment on 128 bit ints bumped from 8 to 16 (undocumented of course).
#if LLVM_VERSION_MAJOR >= 18
	#define AMD64_MAX_ALIGNMENT 16
#else
	#define AMD64_MAX_ALIGNMENT 8
#endif

gb_global TargetMetrics target_windows_i386 = {
	TargetOs_windows,
	TargetArch_i386,
	4, 4, 4, 8,
	str_lit("i386-pc-windows-msvc"),
};
gb_global TargetMetrics target_windows_amd64 = {
	TargetOs_windows,
	TargetArch_amd64,
	8, 8, AMD64_MAX_ALIGNMENT, 16,
	str_lit("x86_64-pc-windows-msvc"),
};

gb_global TargetMetrics target_linux_i386 = {
	TargetOs_linux,
	TargetArch_i386,
	4, 4, 4, 8,
	str_lit("i386-pc-linux-gnu"),

};
gb_global TargetMetrics target_linux_amd64 = {
	TargetOs_linux,
	TargetArch_amd64,
	8, 8, AMD64_MAX_ALIGNMENT, 16,
	str_lit("x86_64-pc-linux-gnu"),
};
gb_global TargetMetrics target_linux_arm64 = {
	TargetOs_linux,
	TargetArch_arm64,
	8, 8, 16, 16,
	str_lit("aarch64-linux-elf"),
};

gb_global TargetMetrics target_linux_arm32 = {
	TargetOs_linux,
	TargetArch_arm32,
	4, 4, 4, 8,
	str_lit("arm-linux-gnu"),
};

gb_global TargetMetrics target_darwin_amd64 = {
	TargetOs_darwin,
	TargetArch_amd64,
	8, 8, AMD64_MAX_ALIGNMENT, 16,
	str_lit("x86_64-apple-macosx"), // NOTE: Changes during initialization based on build flags.
};

gb_global TargetMetrics target_darwin_arm64 = {
	TargetOs_darwin,
	TargetArch_arm64,
	8, 8, 16, 16,
	str_lit("arm64-apple-macosx"), // NOTE: Changes during initialization based on build flags.
};

gb_global TargetMetrics target_freebsd_i386 = {
	TargetOs_freebsd,
	TargetArch_i386,
	4, 4, 4, 8,
	str_lit("i386-unknown-freebsd-elf"),
};

gb_global TargetMetrics target_freebsd_amd64 = {
	TargetOs_freebsd,
	TargetArch_amd64,
	8, 8, AMD64_MAX_ALIGNMENT, 16,
	str_lit("x86_64-unknown-freebsd-elf"),
};

gb_global TargetMetrics target_freebsd_arm64 = {
	TargetOs_freebsd,
	TargetArch_arm64,
	8, 8, 16, 16,
	str_lit("aarch64-unknown-freebsd-elf"),
};

gb_global TargetMetrics target_openbsd_amd64 = {
	TargetOs_openbsd,
	TargetArch_amd64,
	8, 8, AMD64_MAX_ALIGNMENT, 16,
	str_lit("x86_64-unknown-openbsd-elf"),
};

gb_global TargetMetrics target_netbsd_amd64 = {
	TargetOs_netbsd,
	TargetArch_amd64,
	8, 8, AMD64_MAX_ALIGNMENT, 16,
	str_lit("x86_64-unknown-netbsd-elf"),
};

gb_global TargetMetrics target_haiku_amd64 = {
	TargetOs_haiku,
	TargetArch_amd64,
	8, 8, AMD64_MAX_ALIGNMENT, 16,
	str_lit("x86_64-unknown-haiku"),
};

gb_global TargetMetrics target_essence_amd64 = {
	TargetOs_essence,
	TargetArch_amd64,
	8, 8, AMD64_MAX_ALIGNMENT, 16,
	str_lit("x86_64-pc-none-elf"),
};


gb_global TargetMetrics target_freestanding_wasm32 = {
	TargetOs_freestanding,
	TargetArch_wasm32,
	4, 4, 8, 16,
	str_lit("wasm32-freestanding-js"),
};

gb_global TargetMetrics target_js_wasm32 = {
	TargetOs_js,
	TargetArch_wasm32,
	4, 4, 8, 16,
	str_lit("wasm32-js-js"),
};

gb_global TargetMetrics target_wasi_wasm32 = {
	TargetOs_wasi,
	TargetArch_wasm32,
	4, 4, 8, 16,
	str_lit("wasm32-wasi-js"),
};


gb_global TargetMetrics target_freestanding_wasm64p32 = {
	TargetOs_freestanding,
	TargetArch_wasm64p32,
	4, 8, 8, 16,
	str_lit("wasm32-freestanding-js"),
};

gb_global TargetMetrics target_js_wasm64p32 = {
	TargetOs_js,
	TargetArch_wasm64p32,
	4, 8, 8, 16,
	str_lit("wasm32-js-js"),
};

gb_global TargetMetrics target_wasi_wasm64p32 = {
	TargetOs_wasi,
	TargetArch_wasm32,
	4, 8, 8, 16,
	str_lit("wasm32-wasi-js"),
};



gb_global TargetMetrics target_freestanding_amd64_sysv = {
	TargetOs_freestanding,
	TargetArch_amd64,
	8, 8, AMD64_MAX_ALIGNMENT, 16,
	str_lit("x86_64-pc-none-gnu"),
	TargetABI_SysV,
};

gb_global TargetMetrics target_freestanding_amd64_win64 = {
	TargetOs_freestanding,
	TargetArch_amd64,
	8, 8, AMD64_MAX_ALIGNMENT, 16,
	str_lit("x86_64-pc-none-msvc"),
	TargetABI_Win64,
};

gb_global TargetMetrics target_freestanding_arm64 = {
	TargetOs_freestanding,
	TargetArch_arm64,
	8, 8, 16, 16,
	str_lit("aarch64-none-elf"),
};

struct NamedTargetMetrics {
	String name;
	TargetMetrics *metrics;
};

gb_global NamedTargetMetrics named_targets[] = {
	{ str_lit("darwin_amd64"),        &target_darwin_amd64   },
	{ str_lit("darwin_arm64"),        &target_darwin_arm64   },

	{ str_lit("essence_amd64"),       &target_essence_amd64  },

	{ str_lit("linux_i386"),          &target_linux_i386     },
	{ str_lit("linux_amd64"),         &target_linux_amd64    },
	{ str_lit("linux_arm64"),         &target_linux_arm64    },
	{ str_lit("linux_arm32"),         &target_linux_arm32    },

	{ str_lit("windows_i386"),        &target_windows_i386   },
	{ str_lit("windows_amd64"),       &target_windows_amd64  },

	{ str_lit("freebsd_i386"),        &target_freebsd_i386   },
	{ str_lit("freebsd_amd64"),       &target_freebsd_amd64  },
	{ str_lit("freebsd_arm64"),       &target_freebsd_arm64  },

	{ str_lit("openbsd_amd64"),       &target_openbsd_amd64  },
	{ str_lit("netbsd_amd64"),        &target_netbsd_amd64   },
	{ str_lit("haiku_amd64"),         &target_haiku_amd64    },

	{ str_lit("freestanding_wasm32"), &target_freestanding_wasm32 },
	{ str_lit("wasi_wasm32"),         &target_wasi_wasm32 },
	{ str_lit("js_wasm32"),           &target_js_wasm32 },

	{ str_lit("freestanding_wasm64p32"), &target_freestanding_wasm64p32 },
	{ str_lit("js_wasm64p32"),           &target_js_wasm64p32 },
	{ str_lit("wasi_wasm64p32"),         &target_wasi_wasm64p32 },

	{ str_lit("freestanding_amd64_sysv"),  &target_freestanding_amd64_sysv },
	{ str_lit("freestanding_amd64_win64"), &target_freestanding_amd64_win64 },

	{ str_lit("freestanding_arm64"), &target_freestanding_arm64 },
};

gb_global NamedTargetMetrics *selected_target_metrics;
gb_global Subtarget selected_subtarget;


gb_internal TargetOsKind get_target_os_from_string(String str) {
	for (isize i = 0; i < TargetOs_COUNT; i++) {
		if (str_eq_ignore_case(target_os_names[i], str)) {
			return cast(TargetOsKind)i;
		}
	}
	return TargetOs_Invalid;
}

gb_internal TargetArchKind get_target_arch_from_string(String str) {
	for (isize i = 0; i < TargetArch_COUNT; i++) {
		if (str_eq_ignore_case(target_arch_names[i], str)) {
			return cast(TargetArchKind)i;
		}
	}
	return TargetArch_Invalid;
}

gb_internal bool is_excluded_target_filename(String name) {
	String original_name = name;
	name = remove_extension_from_path(name);

	if (string_starts_with(name, str_lit("."))) {
		// Ignore .*.odin files
		return true;
	}

	if (build_context.command_kind != Command_test) {
		String test_suffix = str_lit("_test");
		if (string_ends_with(name, test_suffix) && name != test_suffix) {
			// Ignore *_test.odin files
			return true;
		}
	}

	String str1 = {};
	String str2 = {};
	isize n = 0;

	str1 = name;
	n = str1.len;
	for (isize i = str1.len-1; i >= 0 && str1[i] != '_'; i--) {
		n -= 1;
	}
	str1 = substring(str1, n, str1.len);

	str2 = substring(name, 0, gb_max(n-1, 0));
	n = str2.len;
	for (isize i = str2.len-1; i >= 0 && str2[i] != '_'; i--) {
		n -= 1;
	}
	str2 = substring(str2, n, str2.len);

	if (str1 == name) {
		return false;
	}

	TargetOsKind   os1   = get_target_os_from_string(str1);
	TargetArchKind arch1 = get_target_arch_from_string(str1);
	TargetOsKind   os2   = get_target_os_from_string(str2);
	TargetArchKind arch2 = get_target_arch_from_string(str2);

	if (os1 != TargetOs_Invalid && arch2 != TargetArch_Invalid) {
		return os1 != build_context.metrics.os || arch2 != build_context.metrics.arch;
	} else if (arch1 != TargetArch_Invalid && os2 != TargetOs_Invalid) {
		return arch1 != build_context.metrics.arch || os2 != build_context.metrics.os;
	} else if (os1 != TargetOs_Invalid) {
		return os1 != build_context.metrics.os;
	} else if (arch1 != TargetArch_Invalid) {
		return arch1 != build_context.metrics.arch;
	}

	return false;
}


struct LibraryCollections {
	String name;
	String path;
};

gb_global Array<LibraryCollections> library_collections = {0};

gb_internal void add_library_collection(String name, String path) {
	LibraryCollections lc = {name, string_trim_whitespace(path)};
	array_add(&library_collections, lc);
}

gb_internal bool find_library_collection_path(String name, String *path) {
	for (auto const &lc : library_collections) {
		if (lc.name == name) {
			if (path) *path = lc.path;
			return true;
		}
	}
	return false;
}

gb_internal bool is_arch_wasm(void) {
	switch (build_context.metrics.arch) {
	case TargetArch_wasm32:
	case TargetArch_wasm64p32:
		return true;
	}
	return false;
}

gb_internal bool is_arch_x86(void) {
	switch (build_context.metrics.arch) {
	case TargetArch_i386:
	case TargetArch_amd64:
		return true;
	}
	return false;
}

gb_internal bool allow_check_foreign_filepath(void) {
	switch (build_context.metrics.arch) {
	case TargetArch_wasm32:
	case TargetArch_wasm64p32:
		return false;
	}
	return true;
}

// TODO(bill): OS dependent versions for the BuildContext
// join_path
// is_dir
// is_file
// is_abs_path
// has_subdir

gb_global String const WIN32_SEPARATOR_STRING = {cast(u8 *)"\\", 1};
gb_global String const NIX_SEPARATOR_STRING   = {cast(u8 *)"/",  1};

gb_global String const WASM_MODULE_NAME_SEPARATOR = str_lit("..");

gb_internal String internal_odin_root_dir(void);

gb_internal String odin_root_dir(void) {
	if (global_module_path_set) {
		return global_module_path;
	}

	gbAllocator a = permanent_allocator();
	char const *found = gb_get_env("ODIN_ROOT", a);
	if (found) {
		String path = path_to_full_path(a, make_string_c(found));
		#if defined(GB_SYSTEM_WINDOWS)
			path = normalize_path(a, path, WIN32_SEPARATOR_STRING);
		#else
			path = normalize_path(a, path, NIX_SEPARATOR_STRING);
		#endif

		global_module_path = path;
		global_module_path_set = true;
		return global_module_path;
	}
	return internal_odin_root_dir();
}


#if defined(GB_SYSTEM_WINDOWS)
gb_internal String internal_odin_root_dir(void) {
	String path = global_module_path;
	isize len, i;
	wchar_t *text;

	if (global_module_path_set) {
		return global_module_path;
	}

	auto path_buf = array_make<wchar_t>(heap_allocator(), 300);

	len = 0;
	for (;;) {
		len = GetModuleFileNameW(nullptr, &path_buf[0], cast(int)path_buf.count);
		if (len == 0) {
			return make_string(nullptr, 0);
		}
		if (len < path_buf.count) {
			break;
		}
		array_resize(&path_buf, 2*path_buf.count + 300);
	}
	len += 1; // NOTE(bill): It needs an extra 1 for some reason

	mutex_lock(&string_buffer_mutex);
	defer (mutex_unlock(&string_buffer_mutex));

	text = gb_alloc_array(permanent_allocator(), wchar_t, len+1);

	GetModuleFileNameW(nullptr, text, cast(int)len);
	path = string16_to_string(heap_allocator(), make_string16(text, len));

	for (i = path.len-1; i >= 0; i--) {
		u8 c = path[i];
		if (c == '/' || c == '\\') {
			break;
		}
		path.len--;
	}

	global_module_path = path;
	global_module_path_set = true;


	array_free(&path_buf);

	return path;
}

#elif defined(GB_SYSTEM_HAIKU)

#include <FindDirectory.h>

gb_internal String path_to_fullpath(gbAllocator a, String s, bool *ok_);

gb_internal String internal_odin_root_dir(void) {
	String path = global_module_path;
	isize len, i;
	u8 *text;

	if (global_module_path_set) {
		return global_module_path;
	}

	auto path_buf = array_make<char>(heap_allocator(), 300);
	defer (array_free(&path_buf));

	len = 0;
	for (;;) {
		u32 sz = path_buf.count;
		int res = find_path(B_APP_IMAGE_SYMBOL, B_FIND_PATH_IMAGE_PATH, nullptr, &path_buf[0], sz);
		if(res == B_OK) {
			len = sz;
			break;
		} else {
			array_resize(&path_buf, sz + 1);
		}
	}

	mutex_lock(&string_buffer_mutex);
	defer (mutex_unlock(&string_buffer_mutex));

	text = gb_alloc_array(permanent_allocator(), u8, len + 1);
	gb_memmove(text, &path_buf[0], len);

	path = path_to_fullpath(heap_allocator(), make_string(text, len), nullptr);

	for (i = path.len-1; i >= 0; i--) {
		u8 c = path[i];
		if (c == '/' || c == '\\') {
			break;
		}
		path.len--;
	}

	global_module_path = path;
	global_module_path_set = true;

	return path;
}

#elif defined(GB_SYSTEM_OSX)

#include <mach-o/dyld.h>

gb_internal String path_to_fullpath(gbAllocator a, String s, bool *ok_);

gb_internal String internal_odin_root_dir(void) {
	String path = global_module_path;
	isize len, i;
	u8 *text;

	if (global_module_path_set) {
		return global_module_path;
	}

	auto path_buf = array_make<char>(heap_allocator(), 300);
	defer (array_free(&path_buf));

	len = 0;
	for (;;) {
		u32 sz = path_buf.count;
		int res = _NSGetExecutablePath(&path_buf[0], &sz);
		if(res == 0) {
			len = sz;
			break;
		} else {
			array_resize(&path_buf, sz + 1);
		}
	}

	mutex_lock(&string_buffer_mutex);
	defer (mutex_unlock(&string_buffer_mutex));

	text = gb_alloc_array(permanent_allocator(), u8, len + 1);
	gb_memmove(text, &path_buf[0], len);

	path = path_to_fullpath(heap_allocator(), make_string(text, len), nullptr);

	for (i = path.len-1; i >= 0; i--) {
		u8 c = path[i];
		if (c == '/' || c == '\\') {
			break;
		}
		path.len--;
	}

	global_module_path = path;
	global_module_path_set = true;

	return path;
}
#else

// NOTE: Linux / Unix is unfinished and not tested very well.
#include <sys/stat.h>

gb_internal String path_to_fullpath(gbAllocator a, String s, bool *ok_);

gb_internal String internal_odin_root_dir(void) {
	String path = global_module_path;
	isize len, i;
	u8 *text;

	if (global_module_path_set) {
		return global_module_path;
	}

	auto path_buf = array_make<char>(heap_allocator(), 300);
	defer (array_free(&path_buf));

	len = 0;
	for (;;) {
		// This is not a 100% reliable system, but for the purposes
		// of this compiler, it should be _good enough_.
		// That said, there's no solid 100% method on Linux to get the program's
		// path without checking this link. Sorry.
#if defined(GB_SYSTEM_FREEBSD)
		int mib[4];
		mib[0] = CTL_KERN;
		mib[1] = KERN_PROC;
		mib[2] = KERN_PROC_PATHNAME;
		mib[3] = -1;
		len = path_buf.count;
		sysctl(mib, 4, &path_buf[0], (size_t *) &len, NULL, 0);
#elif defined(GB_SYSTEM_NETBSD)
		len = readlink("/proc/curproc/exe", &path_buf[0], path_buf.count);
#elif defined(GB_SYSTEM_DRAGONFLYBSD)
		len = readlink("/proc/curproc/file", &path_buf[0], path_buf.count);
#elif defined(GB_SYSTEM_LINUX)
		len = readlink("/proc/self/exe", &path_buf[0], path_buf.count);
#elif defined(GB_SYSTEM_OPENBSD)
		int error;
		int mib[] = {
			CTL_KERN,
			KERN_PROC_ARGS,
			getpid(),
			KERN_PROC_ARGV,
		};
		// get argv size
		error = sysctl(mib, 4, NULL, (size_t *) &len, NULL, 0);
		if (error == -1) {
			// sysctl error
			return make_string(nullptr, 0);
		}
		// get argv
		char **argv = (char **)gb_malloc(len);
		error = sysctl(mib, 4, argv, (size_t *) &len, NULL, 0);
		if (error == -1) {
			// sysctl error
			gb_mfree(argv);
			return make_string(nullptr, 0);
		}

		// NOTE(Jeroen):
		// On OpenBSD, if `odin` is on the path, `argv[0]` will contain just `odin`,
		// even though that isn't then the relative path.
		// When run from Odin's directory, it returns `./odin`.
		// Check argv[0] for lack of / to see if it's a reference to PATH.
		// If so, walk PATH to find the executable.

		len = gb_strlen(argv[0]);

		bool slash_found = false;
		bool odin_found  = false;

		for (int i = 0; i < len; i += 1) {
			if (argv[0][i] == '/') {
				slash_found = true;
				break;
			}
		}

		if (slash_found) {
			// copy argv[0] to path_buf
			if(len < path_buf.count) {
				gb_memmove(&path_buf[0], argv[0], len);
				odin_found = true;
			}
		} else {
			gbAllocator a = heap_allocator();
			char const *path_env = gb_get_env("PATH", a);
			defer (gb_free(a, cast(void *)path_env));

			if (path_env) {
				int path_len = gb_strlen(path_env);
				int path_start = 0;
				int path_end   = 0;

				for (; path_start < path_len; ) {
					for (; path_end <= path_len; path_end++) {
						if (path_env[path_end] == ':' || path_end == path_len) {
							break;
						}
					}
					String path_needle    = (const String)make_string((const u8 *)(path_env + path_start), path_end - path_start);
					String argv0          = (const String)make_string((const u8 *)argv[0], len);
					String odin_candidate = concatenate3_strings(a, path_needle, STR_LIT("/"), argv0);
					defer (gb_free(a, odin_candidate.text));

					if (gb_file_exists((const char *)odin_candidate.text)) {
						len = odin_candidate.len;
						if(len < path_buf.count) {
							gb_memmove(&path_buf[0], odin_candidate.text, len);
						}
						odin_found = true;
						break;
					}

					path_start = path_end + 1;
					path_end   = path_start;
					if (path_start > path_len) {
						break;
					}
				}
			}

			if (!odin_found) {
				gb_printf_err("Odin could not locate itself in PATH, and ODIN_ROOT wasn't set either.\n");
			}
		}
		gb_mfree(argv);
#endif
		if(len == 0 || len == -1) {
			return make_string(nullptr, 0);
		}
		if (len < path_buf.count) {
			break;
		}
		array_resize(&path_buf, 2*path_buf.count + 300);
	}

	mutex_lock(&string_buffer_mutex);
	defer (mutex_unlock(&string_buffer_mutex));

	text = gb_alloc_array(permanent_allocator(), u8, len + 1);

	gb_memmove(text, &path_buf[0], len);

	path = path_to_fullpath(heap_allocator(), make_string(text, len), nullptr);
	for (i = path.len-1; i >= 0; i--) {
		u8 c = path[i];
		if (c == '/' || c == '\\') {
			break;
		}
		path.len--;
	}

	global_module_path = path;
	global_module_path_set = true;

	return path;
}
#endif

gb_global BlockingMutex fullpath_mutex;

#if defined(GB_SYSTEM_WINDOWS)
gb_internal String path_to_fullpath(gbAllocator a, String s, bool *ok_) {
	String result = {};

	String16 string16 = string_to_string16(heap_allocator(), s);
	defer (gb_free(heap_allocator(), string16.text));

	DWORD len;

	mutex_lock(&fullpath_mutex);

	len = GetFullPathNameW(&string16[0], 0, nullptr, nullptr);
	if (len != 0) {
		wchar_t *text = gb_alloc_array(permanent_allocator(), wchar_t, len+1);
		GetFullPathNameW(&string16[0], len, text, nullptr);
		mutex_unlock(&fullpath_mutex);

		text[len] = 0;
		result = string16_to_string(a, make_string16(text, len));
		result = string_trim_whitespace(result);

		// Replace Windows style separators
		for (isize i = 0; i < result.len; i++) {
			if (result.text[i] == '\\') {
				result.text[i] = '/';
			}
		}
		if (ok_) *ok_ = true;
	} else {
		if (ok_) *ok_ = false;
		mutex_unlock(&fullpath_mutex);
	}

	return result;
}
#elif defined(GB_SYSTEM_OSX) || defined(GB_SYSTEM_UNIX)

struct PathToFullpathResult {
	String result;
	bool   ok;
};

gb_internal String path_to_fullpath(gbAllocator a, String s, bool *ok_) {
	static gb_thread_local StringMap<PathToFullpathResult> cache;

	PathToFullpathResult *cached = string_map_get(&cache, s);
	if (cached != nullptr) {
		if (ok_) *ok_ = cached->ok;
		return copy_string(a, cached->result);
	}

	char *p;
	p = realpath(cast(char *)s.text, 0);
	defer (free(p));
	if(p == nullptr) {
		if (ok_) *ok_ = false;

		// Path doesn't exist or is malformed, Windows's `GetFullPathNameW` does not check for
		// existence of the file where `realpath` does, which causes different behaviour between platforms.
		// Two things could be done here:
		// 1. clean the path and resolve it manually, just like the Windows function does,
		//    probably requires porting `filepath.clean` from Odin and doing some more processing.
		// 2. just return a copy of the original path.
		//
		// I have opted for 2 because it is much simpler + we already return `ok = false` + further
		// checks and processes will use the path and cause errors (which we want).
		String result = copy_string(a, s);

		PathToFullpathResult cached_result = {};
		cached_result.result = copy_string(permanent_allocator(), result);
		cached_result.ok     = false;
		string_map_set(&cache, copy_string(permanent_allocator(), s), cached_result);

		return result;
	}
	if (ok_) *ok_ = true;
	String result = copy_string(a, make_string_c(p));

	PathToFullpathResult cached_result = {};
	cached_result.result = copy_string(permanent_allocator(), result);
	cached_result.ok     = true;
	string_map_set(&cache, copy_string(permanent_allocator(), s), cached_result);

	return result;
}
#else
#error Implement system
#endif


gb_internal String get_fullpath_relative(gbAllocator a, String base_dir, String path, bool *ok_) {
	u8 *str = gb_alloc_array(heap_allocator(), u8, base_dir.len+1+path.len+1);
	defer (gb_free(heap_allocator(), str));

	isize i = 0;
	gb_memmove(str+i, base_dir.text, base_dir.len); i += base_dir.len;
	gb_memmove(str+i, "/", 1);                      i += 1;
	gb_memmove(str+i, path.text,     path.len);     i += path.len;
	str[i] = 0;

	// IMPORTANT NOTE(bill): Remove trailing path separators
	// this is required to make sure there is a conventional
	// notation for the path
	for (/**/; i > 0; i--) {
		u8 c = str[i-1];
		if (c != '/' && c != '\\') {
			break;
		}
	}

	String res = make_string(str, i);
	res = string_trim_whitespace(res);
	return path_to_fullpath(a, res, ok_);
}


gb_internal String get_fullpath_base_collection(gbAllocator a, String path, bool *ok_) {
	String module_dir = odin_root_dir();

	String base = str_lit("base/");

	isize str_len = module_dir.len + base.len + path.len;
	u8 *str = gb_alloc_array(heap_allocator(), u8, str_len+1);
	defer (gb_free(heap_allocator(), str));

	isize i = 0;
	gb_memmove(str+i, module_dir.text, module_dir.len); i += module_dir.len;
	gb_memmove(str+i, base.text, base.len);             i += base.len;
	gb_memmove(str+i, path.text, path.len);             i += path.len;
	str[i] = 0;

	String res = make_string(str, i);
	res = string_trim_whitespace(res);
	return path_to_fullpath(a, res, ok_);
}

gb_internal String get_fullpath_core_collection(gbAllocator a, String path, bool *ok_) {
	String module_dir = odin_root_dir();

	String core = str_lit("core/");

	isize str_len = module_dir.len + core.len + path.len;
	u8 *str = gb_alloc_array(heap_allocator(), u8, str_len+1);
	defer (gb_free(heap_allocator(), str));

	isize i = 0;
	gb_memmove(str+i, module_dir.text, module_dir.len); i += module_dir.len;
	gb_memmove(str+i, core.text, core.len);             i += core.len;
	gb_memmove(str+i, path.text, path.len);             i += path.len;
	str[i] = 0;

	String res = make_string(str, i);
	res = string_trim_whitespace(res);
	return path_to_fullpath(a, res, ok_);
}

gb_internal bool show_error_line(void) {
	return !build_context.hide_error_line && !build_context.json_errors;
}

gb_internal bool terse_errors(void) {
	return build_context.terse_errors;
}
gb_internal bool json_errors(void) {
	return build_context.json_errors;
}
gb_internal bool has_ansi_terminal_colours(void) {
	return build_context.has_ansi_terminal_colours && !json_errors();
}

gb_internal bool has_asm_extension(String const &path) {
	String ext = path_extension(path);
	if (ext == ".asm") {
		return true;
	} else if (ext == ".s") {
		return true;
	} else if (ext == ".S") {
		return true;
	}
	return false;
}

// temporary
gb_internal char *token_pos_to_string(TokenPos const &pos) {
	gbString s = gb_string_make_reserve(temporary_allocator(), 128);
	String file = get_file_path_string(pos.file_id);
	switch (build_context.ODIN_ERROR_POS_STYLE) {
	default: /*fallthrough*/
	case ErrorPosStyle_Default:
		s = gb_string_append_fmt(s, "%.*s(%d:%d)", LIT(file), pos.line, pos.column);
		break;
	case ErrorPosStyle_Unix:
		s = gb_string_append_fmt(s, "%.*s:%d:%d:", LIT(file), pos.line, pos.column);
		break;
	}
	return s;
}

gb_internal void init_build_context(TargetMetrics *cross_target, Subtarget subtarget) {
	BuildContext *bc = &build_context;

	gb_affinity_init(&bc->affinity);
	if (bc->thread_count == 0) {
		bc->thread_count = gb_max(bc->affinity.thread_count, 1);
	}

	bc->ODIN_VENDOR  = str_lit("odin");
	bc->ODIN_VERSION = ODIN_VERSION;
	bc->ODIN_ROOT    = odin_root_dir();

	if (bc->max_error_count <= 0) {
		bc->max_error_count = DEFAULT_MAX_ERROR_COLLECTOR_COUNT;
	}

	{
		char const *found = gb_get_env("ODIN_ERROR_POS_STYLE", permanent_allocator());
		if (found) {
			ErrorPosStyle kind = ErrorPosStyle_Default;
			String style = make_string_c(found);
			style = string_trim_whitespace(style);
			if (style == "" || style == "default" || style == "odin") {
				kind = ErrorPosStyle_Default;
			} else if (style == "unix" || style == "gcc" || style == "clang" || style == "llvm") {
				kind = ErrorPosStyle_Unix;
			} else {
				gb_printf_err("Invalid ODIN_ERROR_POS_STYLE: got %.*s\n", LIT(style));
				gb_printf_err("Valid formats:\n");
				gb_printf_err("\t\"default\" or \"odin\"\n");
				gb_printf_err("\t\tpath(line:column) message\n");
				gb_printf_err("\t\"unix\"\n");
				gb_printf_err("\t\tpath:line:column: message\n");
				gb_exit(1);
			}

			build_context.ODIN_ERROR_POS_STYLE = kind;
		}
	}

	bc->copy_file_contents = true;

	TargetMetrics *metrics = nullptr;

	#if defined(GB_ARCH_64_BIT)
		#if defined(GB_SYSTEM_WINDOWS)
			metrics = &target_windows_amd64;
		#elif defined(GB_SYSTEM_OSX)
			#if defined(GB_CPU_ARM)
				metrics = &target_darwin_arm64;
			#else
				metrics = &target_darwin_amd64;
			#endif
		#elif defined(GB_SYSTEM_FREEBSD)
			#if defined(GB_CPU_ARM)
				metrics = &target_freebsd_arm64;
			#else
				metrics = &target_freebsd_amd64;
			#endif
		#elif defined(GB_SYSTEM_OPENBSD)
			metrics = &target_openbsd_amd64;
		#elif defined(GB_SYSTEM_NETBSD)
			metrics = &target_netbsd_amd64;
		#elif defined(GB_SYSTEM_HAIKU)
			metrics = &target_haiku_amd64;
		#elif defined(GB_CPU_ARM)
			metrics = &target_linux_arm64;
		#else
			metrics = &target_linux_amd64;
		#endif
	#else
		#if defined(GB_SYSTEM_WINDOWS)
			metrics = &target_windows_i386;
		#elif defined(GB_SYSTEM_OSX)
			#error "Build Error: Unsupported architecture"
		#elif defined(GB_SYSTEM_FREEBSD)
			metrics = &target_freebsd_i386;
		#else
			metrics = &target_linux_i386;
		#endif
	#endif

	if (cross_target != nullptr && metrics != cross_target) {
		bc->different_os = cross_target->os != metrics->os;
		bc->cross_compiling = true;
		metrics = cross_target;
	}

	GB_ASSERT(metrics->os != TargetOs_Invalid);
	GB_ASSERT(metrics->arch != TargetArch_Invalid);
	GB_ASSERT(metrics->ptr_size > 1);
	GB_ASSERT(metrics->int_size  > 1);
	GB_ASSERT(metrics->max_align > 1);
	GB_ASSERT(metrics->max_simd_align > 1);

	GB_ASSERT(metrics->int_size >= metrics->ptr_size);
	if (metrics->int_size > metrics->ptr_size) {
		GB_ASSERT(metrics->int_size == 2*metrics->ptr_size);
	}

	bc->metrics = *metrics;

	bc->ODIN_OS           = target_os_names[metrics->os];
	bc->ODIN_ARCH         = target_arch_names[metrics->arch];
	bc->endian_kind       = target_endians[metrics->arch];
	bc->ptr_size          = metrics->ptr_size;
	bc->int_size          = metrics->int_size;
	bc->max_align         = metrics->max_align;
	bc->max_simd_align    = metrics->max_simd_align;
	bc->link_flags        = str_lit(" ");

	#if defined(DEFAULT_TO_THREADED_CHECKER)
	bc->threaded_checker = true;
	#endif

	if (bc->disable_red_zone) {
		if (is_arch_wasm() && bc->metrics.os == TargetOs_freestanding) {
			gb_printf_err("-disable-red-zone is not support for this target");
			gb_exit(1);
		}
	}

	if (bc->metrics.os == TargetOs_freestanding) {
		bc->no_entry_point = true;
	} else {
		if (bc->no_rtti) {
			gb_printf_err("-no-rtti is only allowed on freestanding targets\n");
			gb_exit(1);
		}
	}

	// Default to subsystem:CONSOLE on Windows targets
	if (bc->ODIN_WINDOWS_SUBSYSTEM == "" && bc->metrics.os == TargetOs_windows) {
		bc->ODIN_WINDOWS_SUBSYSTEM = windows_subsystem_names[Windows_Subsystem_CONSOLE];
	}

	if (metrics->os == TargetOs_darwin && subtarget == Subtarget_iOS) {
		switch (metrics->arch) {
		case TargetArch_arm64:
			bc->metrics.target_triplet = str_lit("arm64-apple-ios");
			break;
		case TargetArch_amd64:
			bc->metrics.target_triplet = str_lit("x86_64-apple-ios");
			break;
		default:
			GB_PANIC("Unknown architecture for darwin");
		}
	}

	if (bc->metrics.os == TargetOs_windows) {
		switch (bc->metrics.arch) {
		case TargetArch_amd64:
			bc->link_flags = str_lit("/machine:x64 ");
			break;
		case TargetArch_i386:
			bc->link_flags = str_lit("/machine:x86 ");
			break;
		}
	} else if (is_arch_wasm()) {
		gbString link_flags = gb_string_make(heap_allocator(), " ");
		// link_flags = gb_string_appendc(link_flags, "--export-all ");
		// link_flags = gb_string_appendc(link_flags, "--export-table ");
		link_flags = gb_string_appendc(link_flags, "--allow-undefined ");
		// if (bc->metrics.arch == TargetArch_wasm64) {
		// 	link_flags = gb_string_appendc(link_flags, "-mwasm64 ");
		// }
		if (bc->no_entry_point) {
			link_flags = gb_string_appendc(link_flags, "--no-entry ");
		}
		
		bc->link_flags = make_string_c(link_flags);
		
		// Disallow on wasm
		bc->use_separate_modules = false;
	} else {
		bc->link_flags = concatenate3_strings(permanent_allocator(),
			str_lit("-target "), bc->metrics.target_triplet, str_lit(" "));
	}

	// NOTE: needs to be done after adding the -target flag to the linker flags so the linker
	// does not annoy the user with version warnings.
	if (metrics->os == TargetOs_darwin) {
		if (!bc->minimum_os_version_string_given) {
			bc->minimum_os_version_string = str_lit("11.0.0");
		}

		if (subtarget == Subtarget_Default) {
			bc->metrics.target_triplet = concatenate_strings(permanent_allocator(), bc->metrics.target_triplet, bc->minimum_os_version_string);
		}
	}

	if (bc->ODIN_DEBUG && !bc->custom_optimization_level) {
		// NOTE(bill): when building with `-debug` but not specifying an optimization level
		// default to `-o:none` to improve the debug symbol generation by default
		bc->optimization_level = -1; // -o:none
	}

	bc->optimization_level = gb_clamp(bc->optimization_level, -1, 3);

	// TODO: Static map calls are bugged on `amd64sysv` abi.
	if (bc->metrics.os != TargetOs_windows && bc->metrics.arch == TargetArch_amd64) {
		// ENFORCE DYNAMIC MAP CALLS
		bc->dynamic_map_calls = true;
	}

	bc->ODIN_VALGRIND_SUPPORT = false;
	if (build_context.metrics.os != TargetOs_windows) {
		switch (bc->metrics.arch) {
		case TargetArch_amd64:
			bc->ODIN_VALGRIND_SUPPORT = true;
			break;
		}
	}

	if (bc->metrics.os == TargetOs_freestanding) {
		bc->ODIN_DEFAULT_TO_NIL_ALLOCATOR = !bc->ODIN_DEFAULT_TO_PANIC_ALLOCATOR;
	} else if (is_arch_wasm()) {
		if (bc->metrics.os == TargetOs_js || bc->metrics.os == TargetOs_wasi) {
			// TODO(bill): Should these even have a default "heap-like" allocator?
		}

		if (!bc->ODIN_DEFAULT_TO_NIL_ALLOCATOR && !bc->ODIN_DEFAULT_TO_PANIC_ALLOCATOR) {
			bc->ODIN_DEFAULT_TO_PANIC_ALLOCATOR = true;
		}
	}
}

#if defined(GB_SYSTEM_WINDOWS)
// NOTE(IC): In order to find Visual C++ paths without relying on environment variables.
// NOTE(Jeroen): No longer needed in `main.cpp -> linker_stage`. We now resolve those paths in `init_build_paths`.
#include "microsoft_craziness.h"
#endif

// NOTE: the target feature and microarch lists are all sorted, so if it turns out to be slow (I don't think it will)
// a binary search is possible.

gb_internal bool check_single_target_feature_is_valid(String const &feature_list, String const &feature) {
	String_Iterator it = {feature_list, 0};
	for (;;) {
		String str = string_split_iterator(&it, ',');
		if (str == "") break;
		if (str == feature) {
			return true;
		}
	}

	return false;
}

gb_internal bool check_target_feature_is_valid(String const &feature, TargetArchKind arch, String *invalid) {
	String feature_list = target_features_list[arch];
	String_Iterator it = {feature, 0};
	for (;;) {
		String str = string_split_iterator(&it, ',');
		if (str == "") break;
		if (!check_single_target_feature_is_valid(feature_list, str)) {
			if (invalid) *invalid = str;
			return false;
		}
	}

	return true;
}

gb_internal bool check_target_feature_is_valid_globally(String const &feature, String *invalid) {
	String_Iterator it = {feature, 0};
	for (;;) {
		String str = string_split_iterator(&it, ',');
		if (str == "") break;

		bool valid = false;
		for (int arch = TargetArch_Invalid; arch < TargetArch_COUNT; arch += 1) {
			if (check_target_feature_is_valid(str, cast(TargetArchKind)arch, invalid)) {
				valid = true;
				break;
			}
		}

		if (!valid) {
			if (invalid) *invalid = str;
			return false;
		}
	}

	return true;
}

gb_internal bool check_target_feature_is_valid_for_target_arch(String const &feature, String *invalid) {
	return check_target_feature_is_valid(feature, build_context.metrics.arch, invalid);
}

gb_internal bool check_target_feature_is_enabled(String const &feature, String *not_enabled) {
	String_Iterator it = {feature, 0};
	for (;;) {
		String str = string_split_iterator(&it, ',');
		if (str == "") break;
		if (!string_set_exists(&build_context.target_features_set, str)) {
			if (not_enabled) *not_enabled = str;
			return false;
		}
	}

	return true;
}

gb_internal bool check_target_feature_is_superset_of(String const &superset, String const &of, String *missing) {
	String_Iterator it = {of, 0};
	for (;;) {
		String str = string_split_iterator(&it, ',');
		if (str == "") break;
		if (!check_single_target_feature_is_valid(superset, str)) {
			if (missing) *missing = str;
			return false;
		}
	}
	return true;
}

// NOTE(Jeroen): Set/create the output and other paths and report an error as appropriate.
// We've previously called `parse_build_flags`, so `out_filepath` should be set.
gb_internal bool init_build_paths(String init_filename) {
	gbAllocator   ha = heap_allocator();
	BuildContext *bc = &build_context;

	// NOTE(Jeroen): We're pre-allocating BuildPathCOUNT slots so that certain paths are always at the same enumerated index.
	array_init(&bc->build_paths, permanent_allocator(), BuildPathCOUNT);

	string_set_init(&bc->target_features_set, 1024);

	// [BuildPathMainPackage] Turn given init path into a `Path`, which includes normalizing it into a full path.
	bc->build_paths[BuildPath_Main_Package] = path_from_string(ha, init_filename);

	{
		String build_project_name  = last_path_element(bc->build_paths[BuildPath_Main_Package].basename);
		GB_ASSERT(build_project_name.len > 0);
		bc->ODIN_BUILD_PROJECT_NAME = build_project_name;
	}

	bool produces_output_file = false;
	if (bc->command_kind == Command_doc && bc->cmd_doc_flags & CmdDocFlag_DocFormat) {
		produces_output_file = true;
	} else if (bc->command_kind & Command__does_build) {
		produces_output_file = true;
	}

	if (build_context.ODIN_DEFAULT_TO_NIL_ALLOCATOR ||
	    build_context.ODIN_DEFAULT_TO_PANIC_ALLOCATOR) {
		bc->no_dynamic_literals = true;
	}

	if (!produces_output_file) {
		// Command doesn't produce output files. We're done.
		return true;
	}

	#if defined(GB_SYSTEM_WINDOWS)
	if (bc->metrics.os == TargetOs_windows) {
		if (bc->resource_filepath.len > 0) {
			bc->build_paths[BuildPath_RC]      = path_from_string(ha, bc->resource_filepath);
			bc->build_paths[BuildPath_RES]     = path_from_string(ha, bc->resource_filepath);
			bc->build_paths[BuildPath_RC].ext  = copy_string(ha, STR_LIT("rc"));
			bc->build_paths[BuildPath_RES].ext = copy_string(ha, STR_LIT("res"));
		}

		if (bc->pdb_filepath.len > 0) {
			bc->build_paths[BuildPath_PDB]     = path_from_string(ha, bc->pdb_filepath);
		}

		if ((bc->command_kind & Command__does_build) && (!bc->ignore_microsoft_magic)) {
			// NOTE(ic): It would be nice to extend this so that we could specify the Visual Studio version that we want instead of defaulting to the latest.
			Find_Result find_result = find_visual_studio_and_windows_sdk();

			if (find_result.windows_sdk_version == 0) {
				gb_printf_err("Windows SDK not found.\n");
				return false;
			}

			if (!build_context.use_lld && find_result.vs_exe_path.len == 0) {
				gb_printf_err("link.exe not found.\n");
				return false;
			}

			if (find_result.vs_library_path.len == 0) {
				gb_printf_err("VS library path not found.\n");
				return false;
			}

			if (find_result.windows_sdk_um_library_path.len > 0) {
				GB_ASSERT(find_result.windows_sdk_ucrt_library_path.len > 0);

				if (find_result.windows_sdk_bin_path.len > 0) {
					bc->build_paths[BuildPath_Win_SDK_Bin_Path]  = path_from_string(ha, find_result.windows_sdk_bin_path);
				}

				if (find_result.windows_sdk_um_library_path.len > 0) {
					bc->build_paths[BuildPath_Win_SDK_UM_Lib]   = path_from_string(ha, find_result.windows_sdk_um_library_path);
				}

				if (find_result.windows_sdk_ucrt_library_path.len > 0) {
					bc->build_paths[BuildPath_Win_SDK_UCRT_Lib] = path_from_string(ha, find_result.windows_sdk_ucrt_library_path);
				}

				if (find_result.vs_exe_path.len > 0) {
					bc->build_paths[BuildPath_VS_EXE]           = path_from_string(ha, find_result.vs_exe_path);
				}

				if (find_result.vs_library_path.len > 0) {
					bc->build_paths[BuildPath_VS_LIB]           = path_from_string(ha, find_result.vs_library_path);
				}
			}
		}
	}
	#endif

	// All the build targets and OSes.
	String output_extension;

	if (bc->command_kind == Command_doc && bc->cmd_doc_flags & CmdDocFlag_DocFormat) {
		output_extension = STR_LIT("odin-doc");
	} else if (is_arch_wasm()) {
		output_extension = STR_LIT("wasm");
	} else if (build_context.build_mode == BuildMode_Executable) {
		// By default use no executable extension.
		output_extension = make_string(nullptr, 0);
		String const single_file_extension = str_lit(".odin");

		if (build_context.metrics.os == TargetOs_windows) {
			output_extension = STR_LIT("exe");
		} else if (build_context.cross_compiling && selected_target_metrics->metrics == &target_essence_amd64) {
			// Do nothing: we don't want the .bin extension
			// when cross compiling
		} else if (path_is_directory(last_path_element(bc->build_paths[BuildPath_Main_Package].basename))) {
			// Add .bin extension to avoid collision
			// with package directory name
			output_extension = STR_LIT("bin");
		} else if (string_ends_with(init_filename, single_file_extension) && path_is_directory(remove_extension_from_path(init_filename))) {
			// Add bin extension if compiling single-file package
			// with same output name as a directory
			output_extension = STR_LIT("bin");
		}
	} else if (build_context.build_mode == BuildMode_DynamicLibrary) {
		// By default use a .so shared library extension.
		output_extension = STR_LIT("so");

		if (build_context.metrics.os == TargetOs_windows) {
			output_extension = STR_LIT("dll");
		} else if (build_context.metrics.os == TargetOs_darwin) {
			output_extension = STR_LIT("dylib");
		}
	} else if (build_context.build_mode == BuildMode_StaticLibrary) {
		output_extension = STR_LIT("a");
		if (build_context.metrics.os == TargetOs_windows) {
			output_extension = STR_LIT("lib");
		}
	}else if (build_context.build_mode == BuildMode_Object) {
		// By default use a .o object extension.
		output_extension = STR_LIT("o");

		if (build_context.metrics.os == TargetOs_windows) {
			output_extension = STR_LIT("obj");
		}
	} else if (build_context.build_mode == BuildMode_Assembly) {
		// By default use a .S asm extension.
		output_extension = STR_LIT("S");
	} else if (build_context.build_mode == BuildMode_LLVM_IR) {
		output_extension = STR_LIT("ll");
	} else {
		GB_PANIC("Unhandled build mode/target combination.\n");
	}

	if (bc->out_filepath.len > 0) {
		bc->build_paths[BuildPath_Output] = path_from_string(ha, bc->out_filepath);
		if (build_context.metrics.os == TargetOs_windows) {
			String output_file = path_to_string(ha, bc->build_paths[BuildPath_Output]);
			defer (gb_free(ha, output_file.text));
			if (path_is_directory(bc->build_paths[BuildPath_Output])) {
				gb_printf_err("Output path %.*s is a directory.\n", LIT(output_file));
				return false;
			} else if (bc->build_paths[BuildPath_Output].ext.len == 0) {
				gb_printf_err("Output path %.*s must have an appropriate extension.\n", LIT(output_file));
				return false;				
			}
		}
	} else {
		Path output_path;

		if (str_eq(init_filename, str_lit("."))) {
			// We must name the output file after the current directory.
			debugf("Output name will be created from current base name %.*s.\n", LIT(bc->build_paths[BuildPath_Main_Package].basename));
			String last_element  = last_path_element(bc->build_paths[BuildPath_Main_Package].basename);

			if (last_element.len == 0) {
				gb_printf_err("The output name is created from the last path element. `%.*s` has none. Use `-out:output_name.ext` to set it.\n", LIT(bc->build_paths[BuildPath_Main_Package].basename));
				return false;
			}
			output_path.basename = copy_string(ha, bc->build_paths[BuildPath_Main_Package].basename);
			output_path.name     = copy_string(ha, last_element);

		} else {
			// Init filename was not 'current path'.
			// Contruct the output name from the path elements as usual.
			String output_name = init_filename;
			// If it ends with a trailing (back)slash, strip it before continuing.
			while (output_name.len > 0 && (output_name[output_name.len-1] == '/' || output_name[output_name.len-1] == '\\')) {
				output_name.len -= 1;
			}
			output_name = remove_directory_from_path(output_name);
			output_name = remove_extension_from_path(output_name);
			output_name = copy_string(ha, string_trim_whitespace(output_name));
			output_path = path_from_string(ha, output_name);
			
			// Note(Dragos): This is a fix for empty filenames
			// Turn the trailing folder into the file name
			if (output_path.name.len == 0) {
				isize len = output_path.basename.len;
				while (len > 1 && output_path.basename[len - 1] != '/') {
					len -= 1;
				}
				// We reached the slash
				String old_basename = output_path.basename;
				output_path.basename.len = len - 1; // Remove the slash
				output_path.name = substring(old_basename, len, old_basename.len);
				output_path.basename = copy_string(ha, output_path.basename);
				output_path.name = copy_string(ha, output_path.name);
				// The old basename is wrong. Delete it
				gb_free(ha, old_basename.text);
				
				
			}

			// Replace extension.
			if (output_path.ext.len > 0) {
				gb_free(ha, output_path.ext.text);
			}
		}
		output_path.ext  = copy_string(ha, output_extension);

		bc->build_paths[BuildPath_Output] = output_path;
	}

	// Do we have an extension? We might not if the output filename was supplied.
	if (bc->build_paths[BuildPath_Output].ext.len == 0) {
		if (build_context.metrics.os == TargetOs_windows || build_context.build_mode != BuildMode_Executable) {
			bc->build_paths[BuildPath_Output].ext = copy_string(ha, output_extension);
		}
	}

	// Check if output path is a directory.
	if (path_is_directory(bc->build_paths[BuildPath_Output])) {
		String output_file = path_to_string(ha, bc->build_paths[BuildPath_Output]);
		defer (gb_free(ha, output_file.text));
		gb_printf_err("Output path %.*s is a directory.\n", LIT(output_file));
		return false;
	}

	if (!write_directory(bc->build_paths[BuildPath_Output].basename)) {
		String output_file = path_to_string(ha, bc->build_paths[BuildPath_Output]);
		defer (gb_free(ha, output_file.text));
		gb_printf_err("No write permissions for output path: %.*s\n", LIT(output_file));
		return false;
	}

	if (build_context.sanitizer_flags & SanitizerFlag_Address) {
		switch (build_context.metrics.os) {
		case TargetOs_windows:
		case TargetOs_linux:
		case TargetOs_darwin:
			break;
		default:
			gb_printf_err("-sanitize:address is only supported on windows, linux, and darwin\n");
			return false;
		}
	}

	if (build_context.sanitizer_flags & SanitizerFlag_Memory) {
		switch (build_context.metrics.os) {
		case TargetOs_linux:
			break;
		default:
			gb_printf_err("-sanitize:memory is only supported on linux\n");
			return false;
		}
		if (build_context.metrics.os != TargetOs_linux) {
			return false;
		}
	}

	if (build_context.sanitizer_flags & SanitizerFlag_Thread) {
		switch (build_context.metrics.os) {
		case TargetOs_linux:
		case TargetOs_darwin:
			break;
		default:
			gb_printf_err("-sanitize:thread is only supported on linux and darwin\n");
			return false;
		}
	}

	if (build_context.no_crt && !build_context.ODIN_DEFAULT_TO_NIL_ALLOCATOR && !build_context.ODIN_DEFAULT_TO_PANIC_ALLOCATOR) {
		switch (build_context.metrics.os) {
		case TargetOs_linux:
		case TargetOs_darwin:
		case TargetOs_essence:
		case TargetOs_freebsd:
		case TargetOs_openbsd:
		case TargetOs_netbsd:
		case TargetOs_haiku:
			gb_printf_err("-no-crt on unix systems requires either -default-to-nil-allocator or -default-to-panic-allocator to also be present because the default allocator requires crt\n");
			return false;
		}
	}

	return true;
}

