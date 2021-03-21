#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>


//"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
//"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"

typedef struct big {
  char x[1000];
  char y[1000];
  char z[1000];
} big;

big big0, big1;

extern big process(big);

int main() {
  FILE* f = fopen("random", "rb");
  if (!f) {
    printf("Broken file\n");
    return -1;
  }
  size_t read = fread(&big0, 1, sizeof(big), f);

  if (read != sizeof(big)) {
    printf("Small buff\n");
    return -1;
  }

  big1 = process(big0);

  if (memcmp(&big0, &big1, sizeof(big))) {
    printf("Broken\n");
  } else {
    printf("All good\n");
  }
}

// declare dso_local void @process(%struct.big* sret align 1, %struct.big* byval(%struct.big) align 8) #1

// define void @process(%test.big* sret noalias %agg.result, %test.big* byval %_.0) #0 {
// decls-0:
// 	; AssignStmt
// 	%0 = load %test.big, %test.big* %_.0, align 1
// 	store %test.big %0, %test.big* %agg.result
// 	; ReturnStmt
// 	%1 = load %test.big, %test.big* %agg.result, align 1
// 	store %test.big %1, %test.big* %agg.result
// 	store %test.big %1, %test.big* %agg.result
// 	ret void
// }
