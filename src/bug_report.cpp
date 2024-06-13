/*
	Gather and print platform and version info to help with reporting Odin bugs.
*/

#if !defined(GB_COMPILER_MSVC)
	#if defined(GB_CPU_X86)
		#include <cpuid.h>
	#endif
#endif

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

gb_internal void odin_cpuid(int leaf, int result[]) {
	#if defined(GB_CPU_ARM)
		return;

	#elif defined(GB_CPU_X86)
	
		#if defined(GB_COMPILER_MSVC)
			__cpuid(result, leaf);
		#else
			__get_cpuid(leaf, (unsigned int*)&result[0], (unsigned int*)&result[1], (unsigned int*)&result[2], (unsigned int*)&result[3]);
		#endif

	#endif
}

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
		struct Darwin_To_Release {
			const char* build;    // 21G83
			int   darwin[3];      // Darwin kernel triplet
			const char* os_name;  // OS X, MacOS
			struct {
				const char* name; // Monterey, Mojave, etc.
				int version[3];   // 12.4, etc.
			} release;
		};

		Darwin_To_Release macos_release_map[] = {
			{"8A428",    { 8,  0,  0}, "macOS", {"Tiger",         {10,  4,  0}}},
			{"8A432",    { 8,  0,  0}, "macOS", {"Tiger",         {10,  4,  0}}},
			{"8B15",     { 8,  1,  0}, "macOS", {"Tiger",         {10,  4,  1}}},
			{"8B17",     { 8,  1,  0}, "macOS", {"Tiger",         {10,  4,  1}}},
			{"8C46",     { 8,  2,  0}, "macOS", {"Tiger",         {10,  4,  2}}},
			{"8C47",     { 8,  2,  0}, "macOS", {"Tiger",         {10,  4,  2}}},
			{"8E102",    { 8,  2,  0}, "macOS", {"Tiger",         {10,  4,  2}}},
			{"8E45",     { 8,  2,  0}, "macOS", {"Tiger",         {10,  4,  2}}},
			{"8E90",     { 8,  2,  0}, "macOS", {"Tiger",         {10,  4,  2}}},
			{"8F46",     { 8,  3,  0}, "macOS", {"Tiger",         {10,  4,  3}}},
			{"8G32",     { 8,  4,  0}, "macOS", {"Tiger",         {10,  4,  4}}},
			{"8G1165",   { 8,  4,  0}, "macOS", {"Tiger",         {10,  4,  4}}},
			{"8H14",     { 8,  5,  0}, "macOS", {"Tiger",         {10,  4,  5}}},
			{"8G1454",   { 8,  5,  0}, "macOS", {"Tiger",         {10,  4,  5}}},
			{"8I127",    { 8,  6,  0}, "macOS", {"Tiger",         {10,  4,  6}}},
			{"8I1119",   { 8,  6,  0}, "macOS", {"Tiger",         {10,  4,  6}}},
			{"8J135",    { 8,  7,  0}, "macOS", {"Tiger",         {10,  4,  7}}},
			{"8J2135a",  { 8,  7,  0}, "macOS", {"Tiger",         {10,  4,  7}}},
			{"8K1079",   { 8,  7,  0}, "macOS", {"Tiger",         {10,  4,  7}}},
			{"8N5107",   { 8,  7,  0}, "macOS", {"Tiger",         {10,  4,  7}}},
			{"8L127",    { 8,  8,  0}, "macOS", {"Tiger",         {10,  4,  8}}},
			{"8L2127",   { 8,  8,  0}, "macOS", {"Tiger",         {10,  4,  8}}},
			{"8P135",    { 8,  9,  0}, "macOS", {"Tiger",         {10,  4,  9}}},
			{"8P2137",   { 8,  9,  0}, "macOS", {"Tiger",         {10,  4,  9}}},
			{"8R218",    { 8, 10,  0}, "macOS", {"Tiger",         {10,  4, 10}}},
			{"8R2218",   { 8, 10,  0}, "macOS", {"Tiger",         {10,  4, 10}}},
			{"8R2232",   { 8, 10,  0}, "macOS", {"Tiger",         {10,  4, 10}}},
			{"8S165",    { 8, 11,  0}, "macOS", {"Tiger",         {10,  4, 11}}},
			{"8S2167",   { 8, 11,  0}, "macOS", {"Tiger",         {10,  4, 11}}},
			{"9A581",    { 9,  0,  0}, "macOS", {"Leopard",       {10,  5,  0}}},
			{"9B18",     { 9,  1,  0}, "macOS", {"Leopard",       {10,  5,  1}}},
			{"9B2117",   { 9,  1,  1}, "macOS", {"Leopard",       {10,  5,  1}}},
			{"9C31",     { 9,  2,  0}, "macOS", {"Leopard",       {10,  5,  2}}},
			{"9C7010",   { 9,  2,  0}, "macOS", {"Leopard",       {10,  5,  2}}},
			{"9D34",     { 9,  3,  0}, "macOS", {"Leopard",       {10,  5,  3}}},
			{"9E17",     { 9,  4,  0}, "macOS", {"Leopard",       {10,  5,  4}}},
			{"9F33",     { 9,  5,  0}, "macOS", {"Leopard",       {10,  5,  5}}},
			{"9G55",     { 9,  6,  0}, "macOS", {"Leopard",       {10,  5,  6}}},
			{"9G66",     { 9,  6,  0}, "macOS", {"Leopard",       {10,  5,  6}}},
			{"9G71",     { 9,  6,  0}, "macOS", {"Leopard",       {10,  5,  6}}},
			{"9J61",     { 9,  7,  0}, "macOS", {"Leopard",       {10,  5,  7}}},
			{"9L30",     { 9,  8,  0}, "macOS", {"Leopard",       {10,  5,  8}}},
			{"9L34",     { 9,  8,  0}, "macOS", {"Leopard",       {10,  5,  8}}},
			{"10A432",   {10,  0,  0}, "macOS", {"Snow Leopard",  {10,  6,  0}}},
			{"10A433",   {10,  0,  0}, "macOS", {"Snow Leopard",  {10,  6,  0}}},
			{"10B504",   {10,  1,  0}, "macOS", {"Snow Leopard",  {10,  6,  1}}},
			{"10C540",   {10,  2,  0}, "macOS", {"Snow Leopard",  {10,  6,  2}}},
			{"10D573",   {10,  3,  0}, "macOS", {"Snow Leopard",  {10,  6,  3}}},
			{"10D575",   {10,  3,  0}, "macOS", {"Snow Leopard",  {10,  6,  3}}},
			{"10D578",   {10,  3,  0}, "macOS", {"Snow Leopard",  {10,  6,  3}}},
			{"10F569",   {10,  4,  0}, "macOS", {"Snow Leopard",  {10,  6,  4}}},
			{"10H574",   {10,  5,  0}, "macOS", {"Snow Leopard",  {10,  6,  5}}},
			{"10J567",   {10,  6,  0}, "macOS", {"Snow Leopard",  {10,  6,  6}}},
			{"10J869",   {10,  7,  0}, "macOS", {"Snow Leopard",  {10,  6,  7}}},
			{"10J3250",  {10,  7,  0}, "macOS", {"Snow Leopard",  {10,  6,  7}}},
			{"10J4138",  {10,  7,  0}, "macOS", {"Snow Leopard",  {10,  6,  7}}},
			{"10K540",   {10,  8,  0}, "macOS", {"Snow Leopard",  {10,  6,  8}}},
			{"10K549",   {10,  8,  0}, "macOS", {"Snow Leopard",  {10,  6,  8}}},
			{"11A511",   {11,  0,  0}, "macOS", {"Lion",          {10,  7,  0}}},
			{"11A511s",  {11,  0,  0}, "macOS", {"Lion",          {10,  7,  0}}},
			{"11A2061",  {11,  0,  2}, "macOS", {"Lion",          {10,  7,  0}}},
			{"11A2063",  {11,  0,  2}, "macOS", {"Lion",          {10,  7,  0}}},
			{"11B26",    {11,  1,  0}, "macOS", {"Lion",          {10,  7,  1}}},
			{"11B2118",  {11,  1,  0}, "macOS", {"Lion",          {10,  7,  1}}},
			{"11C74",    {11,  2,  0}, "macOS", {"Lion",          {10,  7,  2}}},
			{"11D50",    {11,  3,  0}, "macOS", {"Lion",          {10,  7,  3}}},
			{"11E53",    {11,  4,  0}, "macOS", {"Lion",          {10,  7,  4}}},
			{"11G56",    {11,  4,  2}, "macOS", {"Lion",          {10,  7,  5}}},
			{"11G63",    {11,  4,  2}, "macOS", {"Lion",          {10,  7,  5}}},
			{"12A269",   {12,  0,  0}, "macOS", {"Mountain Lion", {10,  8,  0}}},
			{"12B19",    {12,  1,  0}, "macOS", {"Mountain Lion", {10,  8,  1}}},
			{"12C54",    {12,  2,  0}, "macOS", {"Mountain Lion", {10,  8,  2}}},
			{"12C60",    {12,  2,  0}, "macOS", {"Mountain Lion", {10,  8,  2}}},
			{"12C2034",  {12,  2,  0}, "macOS", {"Mountain Lion", {10,  8,  2}}},
			{"12C3104",  {12,  2,  0}, "macOS", {"Mountain Lion", {10,  8,  2}}},
			{"12D78",    {12,  3,  0}, "macOS", {"Mountain Lion", {10,  8,  3}}},
			{"12E55",    {12,  4,  0}, "macOS", {"Mountain Lion", {10,  8,  4}}},
			{"12E3067",  {12,  4,  0}, "macOS", {"Mountain Lion", {10,  8,  4}}},
			{"12E4022",  {12,  4,  0}, "macOS", {"Mountain Lion", {10,  8,  4}}},
			{"12F37",    {12,  5,  0}, "macOS", {"Mountain Lion", {10,  8,  5}}},
			{"12F45",    {12,  5,  0}, "macOS", {"Mountain Lion", {10,  8,  5}}},
			{"12F2501",  {12,  5,  0}, "macOS", {"Mountain Lion", {10,  8,  5}}},
			{"12F2518",  {12,  5,  0}, "macOS", {"Mountain Lion", {10,  8,  5}}},
			{"12F2542",  {12,  5,  0}, "macOS", {"Mountain Lion", {10,  8,  5}}},
			{"12F2560",  {12,  5,  0}, "macOS", {"Mountain Lion", {10,  8,  5}}},
			{"13A603",   {13,  0,  0}, "macOS", {"Mavericks",     {10,  9,  0}}},
			{"13B42",    {13,  0,  0}, "macOS", {"Mavericks",     {10,  9,  1}}},
			{"13C64",    {13,  1,  0}, "macOS", {"Mavericks",     {10,  9,  2}}},
			{"13C1021",  {13,  1,  0}, "macOS", {"Mavericks",     {10,  9,  2}}},
			{"13D65",    {13,  2,  0}, "macOS", {"Mavericks",     {10,  9,  3}}},
			{"13E28",    {13,  3,  0}, "macOS", {"Mavericks",     {10,  9,  4}}},
			{"13F34",    {13,  4,  0}, "macOS", {"Mavericks",     {10,  9,  5}}},
			{"13F1066",  {13,  4,  0}, "macOS", {"Mavericks",     {10,  9,  5}}},
			{"13F1077",  {13,  4,  0}, "macOS", {"Mavericks",     {10,  9,  5}}},
			{"13F1096",  {13,  4,  0}, "macOS", {"Mavericks",     {10,  9,  5}}},
			{"13F1112",  {13,  4,  0}, "macOS", {"Mavericks",     {10,  9,  5}}},
			{"13F1134",  {13,  4,  0}, "macOS", {"Mavericks",     {10,  9,  5}}},
			{"13F1507",  {13,  4,  0}, "macOS", {"Mavericks",     {10,  9,  5}}},
			{"13F1603",  {13,  4,  0}, "macOS", {"Mavericks",     {10,  9,  5}}},
			{"13F1712",  {13,  4,  0}, "macOS", {"Mavericks",     {10,  9,  5}}},
			{"13F1808",  {13,  4,  0}, "macOS", {"Mavericks",     {10,  9,  5}}},
			{"13F1911",  {13,  4,  0}, "macOS", {"Mavericks",     {10,  9,  5}}},
			{"14A389",   {14,  0,  0}, "macOS", {"Yosemite",      {10, 10,  0}}},
			{"14B25",    {14,  0,  0}, "macOS", {"Yosemite",      {10, 10,  1}}},
			{"14C109",   {14,  1,  0}, "macOS", {"Yosemite",      {10, 10,  2}}},
			{"14C1510",  {14,  1,  0}, "macOS", {"Yosemite",      {10, 10,  2}}},
			{"14C2043",  {14,  1,  0}, "macOS", {"Yosemite",      {10, 10,  2}}},
			{"14C1514",  {14,  1,  0}, "macOS", {"Yosemite",      {10, 10,  2}}},
			{"14C2513",  {14,  1,  0}, "macOS", {"Yosemite",      {10, 10,  2}}},
			{"14D131",   {14,  3,  0}, "macOS", {"Yosemite",      {10, 10,  3}}},
			{"14D136",   {14,  3,  0}, "macOS", {"Yosemite",      {10, 10,  3}}},
			{"14E46",    {14,  4,  0}, "macOS", {"Yosemite",      {10, 10,  4}}},
			{"14F27",    {14,  5,  0}, "macOS", {"Yosemite",      {10, 10,  5}}},
			{"14F1021",  {14,  5,  0}, "macOS", {"Yosemite",      {10, 10,  5}}},
			{"14F1505",  {14,  5,  0}, "macOS", {"Yosemite",      {10, 10,  5}}},
			{"14F1509",  {14,  5,  0}, "macOS", {"Yosemite",      {10, 10,  5}}},
			{"14F1605",  {14,  5,  0}, "macOS", {"Yosemite",      {10, 10,  5}}},
			{"14F1713",  {14,  5,  0}, "macOS", {"Yosemite",      {10, 10,  5}}},
			{"14F1808",  {14,  5,  0}, "macOS", {"Yosemite",      {10, 10,  5}}},
			{"14F1909",  {14,  5,  0}, "macOS", {"Yosemite",      {10, 10,  5}}},
			{"14F1912",  {14,  5,  0}, "macOS", {"Yosemite",      {10, 10,  5}}},
			{"14F2009",  {14,  5,  0}, "macOS", {"Yosemite",      {10, 10,  5}}},
			{"14F2109",  {14,  5,  0}, "macOS", {"Yosemite",      {10, 10,  5}}},
			{"14F2315",  {14,  5,  0}, "macOS", {"Yosemite",      {10, 10,  5}}},
			{"14F2411",  {14,  5,  0}, "macOS", {"Yosemite",      {10, 10,  5}}},
			{"14F2511",  {14,  5,  0}, "macOS", {"Yosemite",      {10, 10,  5}}},
			{"15A284",   {15,  0,  0}, "macOS", {"El Capitan",    {10, 11,  0}}},
			{"15B42",    {15,  0,  0}, "macOS", {"El Capitan",    {10, 11,  1}}},
			{"15C50",    {15,  2,  0}, "macOS", {"El Capitan",    {10, 11,  2}}},
			{"15D21",    {15,  3,  0}, "macOS", {"El Capitan",    {10, 11,  3}}},
			{"15E65",    {15,  4,  0}, "macOS", {"El Capitan",    {10, 11,  4}}},
			{"15F34",    {15,  5,  0}, "macOS", {"El Capitan",    {10, 11,  5}}},
			{"15G31",    {15,  6,  0}, "macOS", {"El Capitan",    {10, 11,  6}}},
			{"15G1004",  {15,  6,  0}, "macOS", {"El Capitan",    {10, 11,  6}}},
			{"15G1011",  {15,  6,  0}, "macOS", {"El Capitan",    {10, 11,  6}}},
			{"15G1108",  {15,  6,  0}, "macOS", {"El Capitan",    {10, 11,  6}}},
			{"15G1212",  {15,  6,  0}, "macOS", {"El Capitan",    {10, 11,  6}}},
			{"15G1217",  {15,  6,  0}, "macOS", {"El Capitan",    {10, 11,  6}}},
			{"15G1421",  {15,  6,  0}, "macOS", {"El Capitan",    {10, 11,  6}}},
			{"15G1510",  {15,  6,  0}, "macOS", {"El Capitan",    {10, 11,  6}}},
			{"15G1611",  {15,  6,  0}, "macOS", {"El Capitan",    {10, 11,  6}}},
			{"15G17023", {15,  6,  0}, "macOS", {"El Capitan",    {10, 11,  6}}},
			{"15G18013", {15,  6,  0}, "macOS", {"El Capitan",    {10, 11,  6}}},
			{"15G19009", {15,  6,  0}, "macOS", {"El Capitan",    {10, 11,  6}}},
			{"15G20015", {15,  6,  0}, "macOS", {"El Capitan",    {10, 11,  6}}},
			{"15G21013", {15,  6,  0}, "macOS", {"El Capitan",    {10, 11,  6}}},
			{"15G22010", {15,  6,  0}, "macOS", {"El Capitan",    {10, 11,  6}}},
			{"16A323",   {16,  0,  0}, "macOS", {"Sierra",        {10, 12,  0}}},
			{"16B2555",  {16,  1,  0}, "macOS", {"Sierra",        {10, 12,  1}}},
			{"16B2657",  {16,  1,  0}, "macOS", {"Sierra",        {10, 12,  1}}},
			{"16C67",    {16,  3,  0}, "macOS", {"Sierra",        {10, 12,  2}}},
			{"16C68",    {16,  3,  0}, "macOS", {"Sierra",        {10, 12,  2}}},
			{"16D32",    {16,  4,  0}, "macOS", {"Sierra",        {10, 12,  3}}},
			{"16E195",   {16,  5,  0}, "macOS", {"Sierra",        {10, 12,  4}}},
			{"16F73",    {16,  6,  0}, "macOS", {"Sierra",        {10, 12,  5}}},
			{"16F2073",  {16,  6,  0}, "macOS", {"Sierra",        {10, 12,  5}}},
			{"16G29",    {16,  7,  0}, "macOS", {"Sierra",        {10, 12,  6}}},
			{"16G1036",  {16,  7,  0}, "macOS", {"Sierra",        {10, 12,  6}}},
			{"16G1114",  {16,  7,  0}, "macOS", {"Sierra",        {10, 12,  6}}},
			{"16G1212",  {16,  7,  0}, "macOS", {"Sierra",        {10, 12,  6}}},
			{"16G1314",  {16,  7,  0}, "macOS", {"Sierra",        {10, 12,  6}}},
			{"16G1408",  {16,  7,  0}, "macOS", {"Sierra",        {10, 12,  6}}},
			{"16G1510",  {16,  7,  0}, "macOS", {"Sierra",        {10, 12,  6}}},
			{"16G1618",  {16,  7,  0}, "macOS", {"Sierra",        {10, 12,  6}}},
			{"16G1710",  {16,  7,  0}, "macOS", {"Sierra",        {10, 12,  6}}},
			{"16G1815",  {16,  7,  0}, "macOS", {"Sierra",        {10, 12,  6}}},
			{"16G1917",  {16,  7,  0}, "macOS", {"Sierra",        {10, 12,  6}}},
			{"16G1918",  {16,  7,  0}, "macOS", {"Sierra",        {10, 12,  6}}},
			{"16G2016",  {16,  7,  0}, "macOS", {"Sierra",        {10, 12,  6}}},
			{"16G2127",  {16,  7,  0}, "macOS", {"Sierra",        {10, 12,  6}}},
			{"16G2128",  {16,  7,  0}, "macOS", {"Sierra",        {10, 12,  6}}},
			{"16G2136",  {16,  7,  0}, "macOS", {"Sierra",        {10, 12,  6}}},
			{"17A365",   {17,  0,  0}, "macOS", {"High Sierra",   {10, 13,  0}}},
			{"17A405",   {17,  0,  0}, "macOS", {"High Sierra",   {10, 13,  0}}},
			{"17B48",    {17,  2,  0}, "macOS", {"High Sierra",   {10, 13,  1}}},
			{"17B1002",  {17,  2,  0}, "macOS", {"High Sierra",   {10, 13,  1}}},
			{"17B1003",  {17,  2,  0}, "macOS", {"High Sierra",   {10, 13,  1}}},
			{"17C88",    {17,  3,  0}, "macOS", {"High Sierra",   {10, 13,  2}}},
			{"17C89",    {17,  3,  0}, "macOS", {"High Sierra",   {10, 13,  2}}},
			{"17C205",   {17,  3,  0}, "macOS", {"High Sierra",   {10, 13,  2}}},
			{"17C2205",  {17,  3,  0}, "macOS", {"High Sierra",   {10, 13,  2}}},
			{"17D47",    {17,  4,  0}, "macOS", {"High Sierra",   {10, 13,  3}}},
			{"17D2047",  {17,  4,  0}, "macOS", {"High Sierra",   {10, 13,  3}}},
			{"17D102",   {17,  4,  0}, "macOS", {"High Sierra",   {10, 13,  3}}},
			{"17D2102",  {17,  4,  0}, "macOS", {"High Sierra",   {10, 13,  3}}},
			{"17E199",   {17,  5,  0}, "macOS", {"High Sierra",   {10, 13,  4}}},
			{"17E202",   {17,  5,  0}, "macOS", {"High Sierra",   {10, 13,  4}}},
			{"17F77",    {17,  6,  0}, "macOS", {"High Sierra",   {10, 13,  5}}},
			{"17G65",    {17,  7,  0}, "macOS", {"High Sierra",   {10, 13,  6}}},
			{"17G2208",  {17,  7,  0}, "macOS", {"High Sierra",   {10, 13,  6}}},
			{"17G2307",  {17,  7,  0}, "macOS", {"High Sierra",   {10, 13,  6}}},
			{"17G3025",  {17,  7,  0}, "macOS", {"High Sierra",   {10, 13,  6}}},
			{"17G4015",  {17,  7,  0}, "macOS", {"High Sierra",   {10, 13,  6}}},
			{"17G5019",  {17,  7,  0}, "macOS", {"High Sierra",   {10, 13,  6}}},
			{"17G6029",  {17,  7,  0}, "macOS", {"High Sierra",   {10, 13,  6}}},
			{"17G6030",  {17,  7,  0}, "macOS", {"High Sierra",   {10, 13,  6}}},
			{"17G7024",  {17,  7,  0}, "macOS", {"High Sierra",   {10, 13,  6}}},
			{"17G8029",  {17,  7,  0}, "macOS", {"High Sierra",   {10, 13,  6}}},
			{"17G8030",  {17,  7,  0}, "macOS", {"High Sierra",   {10, 13,  6}}},
			{"17G8037",  {17,  7,  0}, "macOS", {"High Sierra",   {10, 13,  6}}},
			{"17G9016",  {17,  7,  0}, "macOS", {"High Sierra",   {10, 13,  6}}},
			{"17G10021", {17,  7,  0}, "macOS", {"High Sierra",   {10, 13,  6}}},
			{"17G11023", {17,  7,  0}, "macOS", {"High Sierra",   {10, 13,  6}}},
			{"17G12034", {17,  7,  0}, "macOS", {"High Sierra",   {10, 13,  6}}},
			{"17G13033", {17,  7,  0}, "macOS", {"High Sierra",   {10, 13,  6}}},
			{"17G13035", {17,  7,  0}, "macOS", {"High Sierra",   {10, 13,  6}}},
			{"17G14019", {17,  7,  0}, "macOS", {"High Sierra",   {10, 13,  6}}},
			{"17G14033", {17,  7,  0}, "macOS", {"High Sierra",   {10, 13,  6}}},
			{"17G14042", {17,  7,  0}, "macOS", {"High Sierra",   {10, 13,  6}}},
			{"18A391",   {18,  0,  0}, "macOS", {"Mojave",        {10, 14,  0}}},
			{"18B75",    {18,  2,  0}, "macOS", {"Mojave",        {10, 14,  1}}},
			{"18B2107",  {18,  2,  0}, "macOS", {"Mojave",        {10, 14,  1}}},
			{"18B3094",  {18,  2,  0}, "macOS", {"Mojave",        {10, 14,  1}}},
			{"18C54",    {18,  2,  0}, "macOS", {"Mojave",        {10, 14,  2}}},
			{"18D42",    {18,  2,  0}, "macOS", {"Mojave",        {10, 14,  3}}},
			{"18D43",    {18,  2,  0}, "macOS", {"Mojave",        {10, 14,  3}}},
			{"18D109",   {18,  2,  0}, "macOS", {"Mojave",        {10, 14,  3}}},
			{"18E226",   {18,  5,  0}, "macOS", {"Mojave",        {10, 14,  4}}},
			{"18E227",   {18,  5,  0}, "macOS", {"Mojave",        {10, 14,  4}}},
			{"18F132",   {18,  6,  0}, "macOS", {"Mojave",        {10, 14,  5}}},
			{"18G84",    {18,  7,  0}, "macOS", {"Mojave",        {10, 14,  6}}},
			{"18G87",    {18,  7,  0}, "macOS", {"Mojave",        {10, 14,  6}}},
			{"18G95",    {18,  7,  0}, "macOS", {"Mojave",        {10, 14,  6}}},
			{"18G103",   {18,  7,  0}, "macOS", {"Mojave",        {10, 14,  6}}},
			{"18G1012",  {18,  7,  0}, "macOS", {"Mojave",        {10, 14,  6}}},
			{"18G2022",  {18,  7,  0}, "macOS", {"Mojave",        {10, 14,  6}}},
			{"18G3020",  {18,  7,  0}, "macOS", {"Mojave",        {10, 14,  6}}},
			{"18G4032",  {18,  7,  0}, "macOS", {"Mojave",        {10, 14,  6}}},
			{"18G5033",  {18,  7,  0}, "macOS", {"Mojave",        {10, 14,  6}}},
			{"18G6020",  {18,  7,  0}, "macOS", {"Mojave",        {10, 14,  6}}},
			{"18G6032",  {18,  7,  0}, "macOS", {"Mojave",        {10, 14,  6}}},
			{"18G6042",  {18,  7,  0}, "macOS", {"Mojave",        {10, 14,  6}}},
			{"18G7016",  {18,  7,  0}, "macOS", {"Mojave",        {10, 14,  6}}},
			{"18G8012",  {18,  7,  0}, "macOS", {"Mojave",        {10, 14,  6}}},
			{"18G8022",  {18,  7,  0}, "macOS", {"Mojave",        {10, 14,  6}}},
			{"18G9028",  {18,  7,  0}, "macOS", {"Mojave",        {10, 14,  6}}},
			{"18G9216",  {18,  7,  0}, "macOS", {"Mojave",        {10, 14,  6}}},
			{"18G9323",  {18,  7,  0}, "macOS", {"Mojave",        {10, 14,  6}}},
			{"19A583",   {19,  0,  0}, "macOS", {"Catalina",      {10, 15,  0}}},
			{"19A602",   {19,  0,  0}, "macOS", {"Catalina",      {10, 15,  0}}},
			{"19A603",   {19,  0,  0}, "macOS", {"Catalina",      {10, 15,  0}}},
			{"19B88",    {19,  0,  0}, "macOS", {"Catalina",      {10, 15,  1}}},
			{"19C57",    {19,  2,  0}, "macOS", {"Catalina",      {10, 15,  2}}},
			{"19C58",    {19,  2,  0}, "macOS", {"Catalina",      {10, 15,  2}}},
			{"19D76",    {19,  3,  0}, "macOS", {"Catalina",      {10, 15,  3}}},
			{"19E266",   {19,  4,  0}, "macOS", {"Catalina",      {10, 15,  4}}},
			{"19E287",   {19,  4,  0}, "macOS", {"Catalina",      {10, 15,  4}}},
			{"19F96",    {19,  5,  0}, "macOS", {"Catalina",      {10, 15,  5}}},
			{"19F101",   {19,  5,  0}, "macOS", {"Catalina",      {10, 15,  5}}},
			{"19G73",    {19,  6,  0}, "macOS", {"Catalina",      {10, 15,  6}}},
			{"19G2021",  {19,  6,  0}, "macOS", {"Catalina",      {10, 15,  6}}},
			{"19H2",     {19,  6,  0}, "macOS", {"Catalina",      {10, 15,  7}}},
			{"19H4",     {19,  6,  0}, "macOS", {"Catalina",      {10, 15,  7}}},
			{"19H15",    {19,  6,  0}, "macOS", {"Catalina",      {10, 15,  7}}},
			{"19H114",   {19,  6,  0}, "macOS", {"Catalina",      {10, 15,  7}}},
			{"19H512",   {19,  6,  0}, "macOS", {"Catalina",      {10, 15,  7}}},
			{"19H524",   {19,  6,  0}, "macOS", {"Catalina",      {10, 15,  7}}},
			{"19H1030",  {19,  6,  0}, "macOS", {"Catalina",      {10, 15,  7}}},
			{"19H1217",  {19,  6,  0}, "macOS", {"Catalina",      {10, 15,  7}}},
			{"19H1323",  {19,  6,  0}, "macOS", {"Catalina",      {10, 15,  7}}},
			{"19H1417",  {19,  6,  0}, "macOS", {"Catalina",      {10, 15,  7}}},
			{"19H1419",  {19,  6,  0}, "macOS", {"Catalina",      {10, 15,  7}}},
			{"19H1519",  {19,  6,  0}, "macOS", {"Catalina",      {10, 15,  7}}},
			{"19H1615",  {19,  6,  0}, "macOS", {"Catalina",      {10, 15,  7}}},
			{"19H1713",  {19,  6,  0}, "macOS", {"Catalina",      {10, 15,  7}}},
			{"19H1715",  {19,  6,  0}, "macOS", {"Catalina",      {10, 15,  7}}},
			{"19H1824",  {19,  6,  0}, "macOS", {"Catalina",      {10, 15,  7}}},
			{"19H1922",  {19,  6,  0}, "macOS", {"Catalina",      {10, 15,  7}}},
			{"19H2026",  {19,  6,  0}, "macOS", {"Catalina",      {10, 15,  7}}},
			{"20A2411",  {20,  1,  0}, "macOS", {"Big Sur",       {11,  0,  0}}},
			{"20B29",    {20,  1,  0}, "macOS", {"Big Sur",       {11,  0,  1}}},
			{"20B50",    {20,  1,  0}, "macOS", {"Big Sur",       {11,  0,  1}}},
			{"20C69",    {20,  2,  0}, "macOS", {"Big Sur",       {11,  1,  0}}},
			{"20D64",    {20,  3,  0}, "macOS", {"Big Sur",       {11,  2,  0}}},
			{"20D74",    {20,  3,  0}, "macOS", {"Big Sur",       {11,  2,  1}}},
			{"20D75",    {20,  3,  0}, "macOS", {"Big Sur",       {11,  2,  1}}},
			{"20D80",    {20,  3,  0}, "macOS", {"Big Sur",       {11,  2,  2}}},
			{"20D91",    {20,  3,  0}, "macOS", {"Big Sur",       {11,  2,  3}}},
			{"20E232",   {20,  4,  0}, "macOS", {"Big Sur",       {11,  3,  0}}},
			{"20E241",   {20,  4,  0}, "macOS", {"Big Sur",       {11,  3,  1}}},
			{"20F71",    {20,  5,  0}, "macOS", {"Big Sur",       {11,  4,  0}}},
			{"20G71",    {20,  6,  0}, "macOS", {"Big Sur",       {11,  5,  0}}},
			{"20G80",    {20,  6,  0}, "macOS", {"Big Sur",       {11,  5,  1}}},
			{"20G95",    {20,  6,  0}, "macOS", {"Big Sur",       {11,  5,  2}}},
			{"20G165",   {20,  6,  0}, "macOS", {"Big Sur",       {11,  6,  0}}},
			{"20G224",   {20,  6,  0}, "macOS", {"Big Sur",       {11,  6,  1}}},
			{"20G314",   {20,  6,  0}, "macOS", {"Big Sur",       {11,  6,  2}}},
			{"20G415",   {20,  6,  0}, "macOS", {"Big Sur",       {11,  6,  3}}},
			{"20G417",   {20,  6,  0}, "macOS", {"Big Sur",       {11,  6,  4}}},
			{"20G527",   {20,  6,  0}, "macOS", {"Big Sur",       {11,  6,  5}}},
			{"20G624",   {20,  6,  0}, "macOS", {"Big Sur",       {11,  6,  6}}},
			{"20G630",   {20,  6,  0}, "macOS", {"Big Sur",       {11,  6,  7}}},
			{"20G730",   {20,  6,  0}, "macOS", {"Big Sur",       {11,  6,  8}}},
			{"20G817",   {20,  6,  0}, "macOS", {"Big Sur",       {11, 7,   0}}},
			{"20G918",   {20,  6,  0}, "macOS", {"Big Sur",       {11, 7,   1}}},
			{"20G1020",  {20,  6,  0}, "macOS", {"Big Sur",       {11, 7,   2}}},
			{"20G1116",  {20,  6,  0}, "macOS", {"Big Sur",       {11, 7,   3}}},
			{"20G1120",  {20,  6,  0}, "macOS", {"Big Sur",       {11, 7,   4}}},
			{"20G1225",  {20,  6,  0}, "macOS", {"Big Sur",       {11, 7,   5}}},
			{"20G1231",  {20,  6,  0}, "macOS", {"Big Sur",       {11, 7,   6}}},
			{"20G1345",  {20,  6,  0}, "macOS", {"Big Sur",       {11, 7,   7}}},
			{"20G1351",  {20,  6,  0}, "macOS", {"Big Sur",       {11, 7,   8}}},
			{"20G1426",  {20,  6,  0}, "macOS", {"Big Sur",       {11, 7,   9}}},
			{"20G1427",  {20,  6,  0}, "macOS", {"Big Sur",       {11, 7,  10}}},
			{"21A344",   {21,  0,  1}, "macOS", {"Monterey",      {12,  0,  0}}},
			{"21A559",   {21,  1,  0}, "macOS", {"Monterey",      {12,  0,  1}}},
			{"21C52",    {21,  2,  0}, "macOS", {"Monterey",      {12,  1,  0}}},
			{"21D49",    {21,  3,  0}, "macOS", {"Monterey",      {12,  2,  0}}},
			{"21D62",    {21,  3,  0}, "macOS", {"Monterey",      {12,  2,  1}}},
			{"21E230",   {21,  4,  0}, "macOS", {"Monterey",      {12,  3,  0}}},
			{"21E258",   {21,  4,  0}, "macOS", {"Monterey",      {12,  3,  1}}},
			{"21F79",    {21,  5,  0}, "macOS", {"Monterey",      {12,  4,  0}}},
			{"21F2081",  {21,  5,  0}, "macOS", {"Monterey",      {12,  4,  0}}},
			{"21F2092",  {21,  5,  0}, "macOS", {"Monterey",      {12,  4,  0}}},
			{"21G72",    {21,  6,  0}, "macOS", {"Monterey",      {12,  5,  0}}},
			{"21G83",    {21,  6,  0}, "macOS", {"Monterey",      {12,  5,  1}}},
			{"21G115",   {21,  6,  0}, "macOS", {"Monterey",      {12,  6,  0}}},
			{"21G217",   {21,  6,  0}, "macOS", {"Monterey",      {12,  6,  1}}},
			{"21G320",   {21,  6,  0}, "macOS", {"Monterey",      {12,  6,  2}}},
			{"21G419",   {21,  6,  0}, "macOS", {"Monterey",      {12,  6,  3}}},
			{"21G526",   {21,  6,  0}, "macOS", {"Monterey",      {12,  6,  4}}},
			{"21G531",   {21,  6,  0}, "macOS", {"Monterey",      {12,  6,  5}}},
			{"21G646",   {21,  6,  0}, "macOS", {"Monterey",      {12,  6,  6}}},
			{"21G651",   {21,  6,  0}, "macOS", {"Monterey",      {12,  6,  7}}},
			{"21G725",   {21,  6,  0}, "macOS", {"Monterey",      {12,  6,  8}}},
			{"21G726",   {21,  6,  0}, "macOS", {"Monterey",      {12,  6,  9}}},
			{"21G816",   {21,  6,  0}, "macOS", {"Monterey",      {12,  7,  0}}},
			{"21G920",   {21,  6,  0}, "macOS", {"Monterey",      {12,  7,  1}}},
			{"21G1974",  {21,  6,  0}, "macOS", {"Monterey",      {12,  7,  2}}},
			{"22A380",   {13,  0,  0}, "macOS", {"Ventura",       {22,  1,  0}}},
			{"22A400",   {13,  0,  1}, "macOS", {"Ventura",       {22,  1,  0}}},
			{"22C65",    {13,  1,  0}, "macOS", {"Ventura",       {22,  2,  0}}},
			{"22D49",    {13,  2,  0}, "macOS", {"Ventura",       {22,  3,  0}}},
			{"22D68",    {13,  2,  1}, "macOS", {"Ventura",       {22,  3,  0}}},
			{"22E252",   {13,  3,  0}, "macOS", {"Ventura",       {22,  4,  0}}},
			{"22E261",   {13,  3,  1}, "macOS", {"Ventura",       {22,  4,  0}}},
			{"22F66",    {13,  4,  0}, "macOS", {"Ventura",       {22,  5,  0}}},
			{"22F82",    {13,  4,  1}, "macOS", {"Ventura",       {22,  5,  0}}},
			{"22E772610a", {13, 4, 1}, "macOS", {"Ventura",       {22,  5,  0}}},
			{"22F770820d", {13, 4, 1}, "macOS", {"Ventura",       {22,  5,  0}}},
			{"22G74",    {13,  5,  0}, "macOS", {"Ventura",       {22,  6,  0}}},
			{"22G90",    {13,  5,  1}, "macOS", {"Ventura",       {22,  6,  0}}},
			{"22G91",    {13,  5,  2}, "macOS", {"Ventura",       {22,  6,  0}}},
			{"22G120",   {13,  6,  0}, "macOS", {"Ventura",       {22,  6,  0}}},
			{"22G313",   {13,  6,  1}, "macOS", {"Ventura",       {22,  6,  0}}},
			{"22G320",   {13,  6,  2}, "macOS", {"Ventura",       {22,  6,  0}}},
			{"23A344",   {23,  0,  0}, "macOS", {"Sonoma",        {14,  0,  0}}},
			{"23B74",    {23,  1,  0}, "macOS", {"Sonoma",        {14,  1,  0}}},
			{"23B81",    {23,  1,  0}, "macOS", {"Sonoma",        {14,  1,  1}}},
			{"23B2082",  {23,  1,  0}, "macOS", {"Sonoma",        {14,  1,  1}}},
			{"23B92",    {23,  1,  0}, "macOS", {"Sonoma",        {14,  1,  2}}},
			{"23B2091",  {23,  1,  0}, "macOS", {"Sonoma",        {14,  1,  2}}},
			{"23C64",    {23,  2,  0}, "macOS", {"Sonoma",        {14,  2,  0}}},
			{"23C71",    {23,  2,  0}, "macOS", {"Sonoma",        {14,  2,  1}}},
			{"23D56",    {23,  3,  0}, "macOS", {"Sonoma",        {14,  3,  0}}},
			{"23D60",    {23,  3,  0}, "macOS", {"Sonoma",        {14,  3,  1}}},
			{"23E214",   {23,  4,  0}, "macOS", {"Sonoma",        {14,  4,  0}}},
			{"23E224",   {23,  4,  0}, "macOS", {"Sonoma",        {14,  4,  1}}},
			{"23F79",    {23,  5,  0}, "macOS", {"Sonoma",        {14,  5,  0}}},
		};


		b32 build_found  = 1;
		b32 darwin_found = 1;
		uint32_t major, minor, patch;

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
			gb_printf("macOS Unknown\n");
			return;
		} else {
			if (sscanf(darwin_buffer, "%u.%u.%u", &major, &minor, &patch) != 3) {
				darwin_found = 0;
			}
		}

		// Scan table for match on BUILD
		int macos_release_count = sizeof(macos_release_map) / sizeof(macos_release_map[0]);
		Darwin_To_Release build_match = {};
		Darwin_To_Release kernel_match = {};
	
		for (int build = 0; build < macos_release_count; build++) {
			Darwin_To_Release rel = macos_release_map[build];
			
			// Do we have an exact match on the BUILD?
			if (gb_strcmp(rel.build, (const char *)build_buffer) == 0) {
				build_match = rel;
				break;
			}
			
			// Do we have an exact Darwin match?
			if (rel.darwin[0] == major && rel.darwin[1] == minor && rel.darwin[2] == patch) {
				kernel_match = rel;
			}
	
			// Major kernel version needs to match exactly,
			if (rel.darwin[0] == major) {
				// No major version match yet.
				if (!kernel_match.os_name) {
					kernel_match = rel;
				}
				if (minor >= rel.darwin[1]) {
					kernel_match = rel;
					if (patch >= rel.darwin[2]) {
						kernel_match = rel;
					}
				}
			}
		}
	
		Darwin_To_Release match = {};
		if(!build_match.build) {
			match = kernel_match;
		} else {
			match = build_match;
		}

		if (match.os_name) {
			gb_printf("%s %s %d", match.os_name, match.release.name, match.release.version[0]);
			if (match.release.version[1] > 0 || match.release.version[2] > 0) {
				gb_printf(".%d", match.release.version[1]);
			}
			if (match.release.version[2] > 0) {
				gb_printf(".%d", match.release.version[2]);
			}
			if (build_found) {
				gb_printf(" (build: %s, kernel: %d.%d.%d)\n", build_buffer, match.darwin[0], match.darwin[1], match.darwin[2]);
			} else {
				gb_printf(" (build: %s?, kernel: %d.%d.%d)\n", match.build, match.darwin[0], match.darwin[1], match.darwin[2]);				
			}
			return;
		}

		if (build_found && darwin_found) {
			gb_printf("macOS Unknown (build: %s, kernel: %d.%d.%d)\n", build_buffer, major, minor, patch);
			return;
		} else if (build_found) {
			gb_printf("macOS Unknown (build: %s)\n", build_buffer);
			return;
		} else if (darwin_found) {
			gb_printf("macOS Unknown (kernel: %d.%d.%d)\n", major, minor, patch);
			return;
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
