/*
	Gather and print platform and version info to help with reporting Odin bugs.
*/

#if defined(GB_SYSTEM_LINUX)
	#include <sys/utsname.h>
	#include <sys/sysinfo.h>
#endif

#if defined(GB_SYSTEM_OSX)
	#include <sys/sysctl.h>
#endif

#if defined(GB_SYSTEM_OPENBSD) || defined(GB_SYSTEM_NETBSD)
	#include <sys/sysctl.h>
	#include <sys/utsname.h>
#endif

#if defined(GB_SYSTEM_FREEBSD)
	#include <sys/sysctl.h>
#endif

/*
	NOTE(Jeroen): This prints the Windows product edition only, to be called from `print_platform_details`.
*/
#if defined(GB_SYSTEM_WINDOWS)
gb_internal void report_windows_product_type(DWORD ProductType) {
	switch (ProductType) {
	case PRODUCT_ULTIMATE:
		gb_printf("Ultimate");
		break;

	case PRODUCT_HOME_BASIC:
		gb_printf("Home Basic");
		break;

	case PRODUCT_HOME_PREMIUM:
		gb_printf("Home Premium");
		break;

	case PRODUCT_ENTERPRISE:
		gb_printf("Enterprise");
		break;

	case PRODUCT_CORE:
		gb_printf("Home Basic");
		break;

	case PRODUCT_HOME_BASIC_N:
		gb_printf("Home Basic N");
		break;

	case PRODUCT_EDUCATION:
		gb_printf("Education");
		break;

	case PRODUCT_EDUCATION_N:
		gb_printf("Education N");
		break;

	case PRODUCT_BUSINESS:
		gb_printf("Business");
		break;

	case PRODUCT_STANDARD_SERVER:
		gb_printf("Standard Server");
		break;

	case PRODUCT_DATACENTER_SERVER:
		gb_printf("Datacenter");
		break;

	case PRODUCT_SMALLBUSINESS_SERVER:
		gb_printf("Windows Small Business Server");
		break;

	case PRODUCT_ENTERPRISE_SERVER:
		gb_printf("Enterprise Server");
		break;

	case PRODUCT_STARTER:
		gb_printf("Starter");
		break;

	case PRODUCT_DATACENTER_SERVER_CORE:
		gb_printf("Datacenter Server Core");
		break;

	case PRODUCT_STANDARD_SERVER_CORE:
		gb_printf("Server Standard Core");
		break;

	case PRODUCT_ENTERPRISE_SERVER_CORE:
		gb_printf("Enterprise Server Core");
		break;

	case PRODUCT_BUSINESS_N:
		gb_printf("Business N");
		break;

	case PRODUCT_HOME_SERVER:
		gb_printf("Home Server");
		break;

	case PRODUCT_SERVER_FOR_SMALLBUSINESS:
		gb_printf("Windows Server 2008 for Windows Essential Server Solutions");
		break;

	case PRODUCT_SMALLBUSINESS_SERVER_PREMIUM:
		gb_printf("Small Business Server Premium");
		break;

	case PRODUCT_HOME_PREMIUM_N:
		gb_printf("Home Premium N");
		break;

	case PRODUCT_ENTERPRISE_N:
		gb_printf("Enterprise N");
		break;

	case PRODUCT_ULTIMATE_N:
		gb_printf("Ultimate N");
		break;

	case PRODUCT_HYPERV:
		gb_printf("HyperV");
		break;

	case PRODUCT_STARTER_N:
		gb_printf("Starter N");
		break;

	case PRODUCT_PROFESSIONAL:
		gb_printf("Professional");
		break;

	case PRODUCT_PROFESSIONAL_N:
		gb_printf("Professional N");
		break;

	case PRODUCT_UNLICENSED:
		gb_printf("Unlicensed");
		break;

	default:
		gb_printf("Unknown Edition (%08x)", cast(unsigned)ProductType);
	}
}
#endif

gb_internal void report_cpu_info() {
	gb_printf("\tCPU:     ");

	#if defined(GB_CPU_X86)

	/*
		Get extended leaf info
	*/
	int cpu[4];

	odin_cpuid(0x80000000, &cpu[0]);
	int number_of_extended_ids = cpu[0];

	int brand[0x12] = {};

	/*
		Read CPU brand if supported.
	*/
	if (number_of_extended_ids >= 0x80000004) {
		odin_cpuid(0x80000002, &brand[0]);
		odin_cpuid(0x80000003, &brand[4]);
		odin_cpuid(0x80000004, &brand[8]);

		/*
			Some CPUs like `      Intel(R) Xeon(R) CPU E5-1650 v2 @ 3.50GHz` may include leading spaces. Trim them.
		*/
		char * brand_name = (char *)&brand[0];
		for (; brand_name[0] == ' '; brand_name++) {}

		gb_printf("%s\n", brand_name);
	} else {
		gb_printf("Unable to retrieve.\n");
	}

	#elif defined(GB_CPU_ARM)
		bool generic = true;

		#if defined(GB_SYSTEM_OSX)
			char cpu_name[128] = {};	
			size_t cpu_name_size = 128;
			if (sysctlbyname("machdep.cpu.brand_string", &cpu_name, &cpu_name_size, nullptr, 0) == 0) {
				generic = false;
				gb_printf("%s\n", (char *)&cpu_name[0]);
			}
		#endif

		if (generic) {
			/*
				TODO(Jeroen): On *nix, perhaps query `/proc/cpuinfo`.
			*/
			#if defined(GB_ARCH_64_BIT)
				gb_printf("ARM64\n");
			#else
				gb_printf("ARM\n");
			#endif
		}
	#elif defined(GB_CPU_RISCV)
		#if defined(GB_ARCH_64_BIT)
			gb_printf("RISCV64\n");
		#else
			gb_printf("RISCV32\n");
		#endif
	#else
		gb_printf("Unknown\n");
	#endif
}

/*
	Report the amount of installed RAM.
*/
gb_internal void report_ram_info() {
	gb_printf("\tRAM:     ");

	#if defined(GB_SYSTEM_WINDOWS)
		MEMORYSTATUSEX statex;
		statex.dwLength = sizeof(statex);
		GlobalMemoryStatusEx (&statex);

		gb_printf("%lld MiB\n", statex.ullTotalPhys / gb_megabytes(1));

	#elif defined(GB_SYSTEM_LINUX)
		/*
			Retrieve RAM info using `sysinfo()`, 
		*/
		struct sysinfo info;
		int result = sysinfo(&info);

		if (result == 0x0) {
			gb_printf("%lu MiB\n", (unsigned long)(info.totalram * info.mem_unit / gb_megabytes(1)));
		} else {
			gb_printf("Unknown.\n");
		}
	#elif defined(GB_SYSTEM_OSX)
		uint64_t ram_amount;
		size_t   val_size = sizeof(ram_amount);

		int mibs[] = { CTL_HW, HW_MEMSIZE };
		if (sysctl(mibs, 2, &ram_amount, &val_size, NULL, 0) != -1) {
			gb_printf("%lld MiB\n", ram_amount / gb_megabytes(1));
		}
	#elif defined(GB_SYSTEM_NETBSD)
		uint64_t ram_amount;
		size_t   val_size = sizeof(ram_amount);

		int mibs[] = { CTL_HW, HW_PHYSMEM64 };
		if (sysctl(mibs, 2, &ram_amount, &val_size, NULL, 0) != -1) {
			gb_printf("%lu MiB\n", ram_amount / gb_megabytes(1));
		}
	#elif defined(GB_SYSTEM_OPENBSD)
		uint64_t ram_amount;
		size_t   val_size = sizeof(ram_amount);

		int mibs[] = { CTL_HW, HW_PHYSMEM64 };
		if (sysctl(mibs, 2, &ram_amount, &val_size, NULL, 0) != -1) {
			gb_printf("%lld MiB\n", ram_amount / gb_megabytes(1));
		}
	#elif defined(GB_SYSTEM_FREEBSD)
		uint64_t ram_amount;
		size_t   val_size = sizeof(ram_amount);

		int mibs[] = { CTL_HW, HW_PHYSMEM };
		if (sysctl(mibs, 2, &ram_amount, &val_size, NULL, 0) != -1) {
			gb_printf("%lu MiB\n", ram_amount / gb_megabytes(1));
		}
	#else
		gb_printf("Unknown.\n");
	#endif
}

gb_internal void report_os_info() {
	gb_printf("\tOS:      ");

	#if defined(GB_SYSTEM_WINDOWS)
	/*
		NOTE(Jeroen): 
			`GetVersionEx`  will return 6.2 for Windows 10 unless the program is manifested for Windows 10.
			`RtlGetVersion` will return the true version.

			Rather than include the WinDDK, we ask the kernel directly.

			`HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion` is for the minor build version (Update Build Release)

	*/
	OSVERSIONINFOEXW osvi;
	ZeroMemory(&osvi, sizeof(OSVERSIONINFOEXW));
	osvi.dwOSVersionInfoSize = sizeof(OSVERSIONINFOEXW);

	typedef NTSTATUS (WINAPI* RtlGetVersionPtr)(OSVERSIONINFOW*);
	typedef BOOL (WINAPI* GetProductInfoPtr)(DWORD dwOSMajorVersion, DWORD dwOSMinorVersion, DWORD dwSpMajorVersion, DWORD dwSpMinorVersion, PDWORD pdwReturnedProductType);

	// https://docs.microsoft.com/en-us/windows-hardware/drivers/ddi/wdm/nf-wdm-rtlgetversion
	RtlGetVersionPtr  RtlGetVersion  =  (RtlGetVersionPtr)GetProcAddress(GetModuleHandle(TEXT("ntdll.dll")), "RtlGetVersion");
	// https://docs.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getproductinfo
	GetProductInfoPtr GetProductInfo = (GetProductInfoPtr)GetProcAddress(GetModuleHandle(TEXT("kernel32.dll")), "GetProductInfo");

	NTSTATUS status  = {};
	DWORD ProductType = {};
	if (RtlGetVersion != nullptr) {
		status = RtlGetVersion((OSVERSIONINFOW*)&osvi);
	}

	if (RtlGetVersion == nullptr || status != 0x0) {
		gb_printf("Windows (Unknown Version)");
	} else {
		if (GetProductInfo != nullptr) {
			GetProductInfo(osvi.dwMajorVersion, osvi.dwMinorVersion, osvi.wServicePackMajor, osvi.wServicePackMinor, &ProductType);
		}

		if (false) {
			gb_printf("dwMajorVersion:    %u\n", cast(unsigned)osvi.dwMajorVersion);
			gb_printf("dwMinorVersion:    %u\n", cast(unsigned)osvi.dwMinorVersion);
			gb_printf("dwBuildNumber:     %u\n", cast(unsigned)osvi.dwBuildNumber);
			gb_printf("dwPlatformId:      %u\n", cast(unsigned)osvi.dwPlatformId);
			gb_printf("wServicePackMajor: %u\n", cast(unsigned)osvi.wServicePackMajor);
			gb_printf("wServicePackMinor: %u\n", cast(unsigned)osvi.wServicePackMinor);
			gb_printf("wSuiteMask:        %u\n", cast(unsigned)osvi.wSuiteMask);
			gb_printf("wProductType:      %u\n", cast(unsigned)osvi.wProductType);
		}

		gb_printf("Windows ");

		switch (osvi.dwMajorVersion) {
		case 10:
			/*
				Windows 10 (Pro), Windows 2016 Server, Windows 2019 Server, Windows 2022 Server
			*/
			switch (osvi.wProductType) {
			case VER_NT_WORKSTATION: // Workstation
				if (osvi.dwBuildNumber < 22000) {
					gb_printf("10 ");
				} else {
					gb_printf("11 ");
				}
				
				report_windows_product_type(ProductType);

				break;
			default: // Server or Domain Controller
				switch(osvi.dwBuildNumber) {
				case 14393:
					gb_printf("2016 Server");
					break;
				case 17763:
					gb_printf("2019 Server");
					break;
				case 20348:
					gb_printf("2022 Server");
					break;
				default:
					gb_printf("Unknown Server");
					break;
				}
			}
			break;
		case 6:
			switch (osvi.dwMinorVersion) {
				case 0:
					switch (osvi.wProductType) {
						case VER_NT_WORKSTATION:
							gb_printf("Windows Vista ");
							report_windows_product_type(ProductType);
							break;
						case 3:
							gb_printf("Windows Server 2008");
							break;
					}
					break;

				case 1:
					switch (osvi.wProductType) {
						case VER_NT_WORKSTATION:
							gb_printf("Windows 7 ");
							report_windows_product_type(ProductType);
							break;
						case 3:
							gb_printf("Windows Server 2008 R2");
							break;
					}
					break;
				case 2:
					switch (osvi.wProductType) {
						case VER_NT_WORKSTATION:
							gb_printf("Windows 8 ");
							report_windows_product_type(ProductType);
							break;
						case 3:
							gb_printf("Windows Server 2012");
							break;
					}
					break;
				case 3:
					switch (osvi.wProductType) {
						case VER_NT_WORKSTATION:
							gb_printf("Windows 8.1 ");
							report_windows_product_type(ProductType);
							break;
						case 3:
							gb_printf("Windows Server 2012 R2");
							break;
					}
					break;
			}
			break;
		case 5:
			switch (osvi.dwMinorVersion) {
				case 0:
					gb_printf("Windows 2000");
					break;
				case 1:
					gb_printf("Windows XP");
					break;
				case 2:
					gb_printf("Windows Server 2003");
					break;
			}
			break;
		default:
			break;
		}

		/*
			Grab Windows DisplayVersion (like 20H02)
		*/
		LPDWORD ValueType = {};
		DWORD   UBR;
		char    DisplayVersion[256];
		DWORD   ValueSize = 256;

		status = RegGetValue(
			HKEY_LOCAL_MACHINE,
			TEXT("SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion"),
			TEXT("DisplayVersion"),
			RRF_RT_REG_SZ,
			ValueType,
			DisplayVersion,
			&ValueSize
		);

		if (status == 0x0) {
			gb_printf(" (version: %s)", DisplayVersion);
		}

		/*
			Now print build number.
		*/
		gb_printf(", build %u", cast(unsigned)osvi.dwBuildNumber);

		ValueSize = sizeof(UBR);
		status = RegGetValue(
			HKEY_LOCAL_MACHINE,
			TEXT("SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion"),
			TEXT("UBR"),
			RRF_RT_REG_DWORD,
			ValueType,
			&UBR,
			&ValueSize
		);

		if (status == 0x0) {
			gb_printf(".%u", cast(unsigned)UBR);
		}
		gb_printf("\n");
	}
	#elif defined(GB_SYSTEM_LINUX)
		/*
			Try to parse `/etc/os-release` for `PRETTY_NAME="Ubuntu 20.04.3 LTS`
		*/
		gbAllocator a = heap_allocator();

		gbFileContents release = gb_file_read_contents(a, 1, "/etc/os-release");
		defer (gb_file_free_contents(&release));

		b32 found = 0;
		if (release.size) {
			char *start        = (char *)release.data;
			char *end          = (char *)release.data + release.size;
			const char *needle = "PRETTY_NAME=\"";
			isize needle_len   = gb_strlen((needle));
		
			char *c = start;
			for (; c < end; c++) {
				if (gb_strncmp(c, needle, needle_len) == 0) {
					found = 1;
					start = c + needle_len;
					break;
				}
			}

			if (found) {
				for (c = start; c < end; c++) {
					if (*c == '"') {
						// Found the closing quote. Replace it with \0
						*c = 0;
						gb_printf("%s", (char *)start);
						break;
					} else if (*c == '\n') {
						found = 0;
					}
				}
			}
		}

		if (!found) {
			gb_printf("Unknown Linux Distro");
		}

		/*
			Print kernel info using `uname()` syscall, https://linux.die.net/man/2/uname
		*/
		char buffer[1024];
		uname((struct utsname *)&buffer[0]);

		struct utsname *info;
		info = (struct utsname *)&buffer[0];

		gb_printf(", %s %s\n", info->sysname, info->release);

	#elif defined(GB_SYSTEM_OSX)
		gbString sw_vers = gb_string_make(heap_allocator(), "");
		if (!system_exec_command_line_app_output("sw_vers --productVersion", &sw_vers)) {
			gb_printf("macOS Unknown\n");
			return;
		}

		uint32_t major, minor, patch = 0;

		if (sscanf(cast(const char *)sw_vers, "%u.%u.%u", &major, &minor, &patch) < 1) {
			gb_printf("macOS Unknown\n");
			return;
		}

		switch (major) {
		case 15: gb_printf("macOS Sequoia"); break;
		case 14: gb_printf("macOS Sonoma"); break;
		case 13: gb_printf("macOS Ventura"); break;
		case 12: gb_printf("macOS Monterey"); break;
		case 11: gb_printf("macOS Big Sur"); break;
		case 10:
			{
				switch (minor) {
				case 15: gb_printf("macOS Catalina"); break;
				case 14: gb_printf("macOS Mojave"); break;
				case 13: gb_printf("macOS High Sierra"); break;
				case 12: gb_printf("macOS Sierra"); break;
				case 11: gb_printf("OS X El Capitan"); break;
				case 10: gb_printf("OS X Yosemite"); break;
				default: gb_printf("macOS Unknown");
				};
				break;
			}
		default:
			gb_printf("macOS Unknown");
		};

		gb_printf(" %d.%d.%d (build ", major, minor, patch);

		b32 build_found  = 1;
		b32 darwin_found = 1;

		#define MACOS_VERSION_BUFFER_SIZE 100
		char build_buffer[MACOS_VERSION_BUFFER_SIZE];
		char darwin_buffer[MACOS_VERSION_BUFFER_SIZE];
		size_t build_buffer_size  = MACOS_VERSION_BUFFER_SIZE - 1;
		size_t darwin_buffer_size = MACOS_VERSION_BUFFER_SIZE - 1;
		#undef MACOS_VERSION_BUFFER_SIZE

		int build_mibs[] = { CTL_KERN, KERN_OSVERSION };
		if (sysctl(build_mibs, 2, build_buffer, &build_buffer_size, NULL, 0) == -1) {
			build_found = 0;
		}

		int darwin_mibs[] = { CTL_KERN, KERN_OSRELEASE };
		if (sysctl(darwin_mibs, 2, darwin_buffer, &darwin_buffer_size, NULL, 0) == -1) {
			darwin_found = 0;
		} else {
			if (sscanf(darwin_buffer, "%u.%u.%u", &major, &minor, &patch) != 3) {
				darwin_found = 0;
			}
		}

		if (build_found) {
			gb_printf("%s, kernel ", build_buffer);
		} else {
			gb_printf("Unknown, kernel ");
		}

		if (darwin_found) {
			gb_printf("%s)\n", darwin_buffer);
		} else {
			gb_printf("Unknown)\n");
		}

	#elif defined(GB_SYSTEM_OPENBSD) || defined(GB_SYSTEM_NETBSD)
		struct utsname un;
		
		if (uname(&un) != -1) {
			gb_printf("%s %s %s %s\n", un.sysname, un.release, un.version, un.machine);
		} else {
			#if defined(GB_SYSTEM_NETBSD)
				gb_printf("NetBSD: Unknown\n");
			#else
				gb_printf("OpenBSD: Unknown\n");    
			#endif
		}
	#elif defined(GB_SYSTEM_FREEBSD)
		#define freebsd_version_buffer 129
		char buffer[freebsd_version_buffer];
		size_t buffer_size = freebsd_version_buffer - 1;
		#undef freebsd_version_buffer

		int mibs[] = { CTL_KERN, KERN_VERSION };
		if (sysctl(mibs, 2, buffer, &buffer_size, NULL, 0) == -1) {
			gb_printf("FreeBSD: Unknown\n");
		} else {
			// KERN_VERSION can end in a \n, replace it with a \0
			for (int i = 0; i < buffer_size; i += 1) {
				if (buffer[i] == '\n') buffer[i] = 0;
			}
			gb_printf("%s", &buffer[0]);

			// Retrieve kernel revision using `sysctl`, e.g. 199506
			mibs[1] = KERN_OSREV;
			uint64_t revision;
			size_t revision_size = sizeof(revision);

			if (sysctl(mibs, 2, &revision, &revision_size, NULL, 0) == -1) {
				gb_printf("\n");
			} else {
				gb_printf(", revision %ld\n", revision);
			}
		}
	#else
		gb_printf("Unknown");
	#endif
}

gb_internal void report_backend_info() {
	gb_printf("\tBackend: LLVM %s\n", LLVM_VERSION_STRING);
}

// NOTE(Jeroen): `odin report` prints some system information for easier bug reporting.
gb_internal void print_bug_report_help() {
	gb_printf("Where to find more information and get into contact when you encounter a bug:\n\n");
	gb_printf("\tWebsite: https://odin-lang.org\n");
	gb_printf("\tGitHub:  https://github.com/odin-lang/Odin/issues\n");
	/*
		Uncomment and update URL once we have a Discord vanity URL. For now people can get here from the site.
		gb_printf("\tDiscord: https://discord.com/invite/sVBPHEv\n");
	*/
	gb_printf("\n\n");

	gb_printf("Useful information to add to a bug report:\n\n");

	gb_printf("\tOdin:    %.*s", LIT(ODIN_VERSION));

	#ifdef NIGHTLY
	gb_printf("-nightly");
	#endif

	#ifdef GIT_SHA
	gb_printf(":%s", GIT_SHA);
	#endif

	gb_printf("\n");

	/*
		Print OS information.
	*/
	report_os_info();

	/*
		Now print CPU info.
	*/
	report_cpu_info();

	/*
		And RAM info.
	*/
	report_ram_info();

	report_backend_info();
}
