/*
	Prints the current date as YYYYMMDD

	e.g. 2024-12-25
*/
#include <stdio.h>
#include <time.h>

int main(int arg_count, char const **arg_ptr) {
	time_t t = time(NULL);
	struct tm* now = localtime(&t);
	printf("%04d%02d%02d", now->tm_year + 1900, now->tm_mon + 1, now->tm_mday);
}