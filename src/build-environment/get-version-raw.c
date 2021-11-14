#include <stdio.h>
#include <time.h>

int main(int argc, char** argv) {
	/*
		For Odin's `build.bat` to set `ODIN_VERSION_RAW`, we need the current year and month.
	*/
	time_t now;
	time(&now);

	/*
		Convert to local time.
	*/
	struct tm *local = localtime(&now);

	printf("dev-%04d-%02d", local->tm_year + 1900, local->tm_mon + 1);
}