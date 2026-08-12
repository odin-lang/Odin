// Support file for test_issue_sysv_abi.odin
//
// Each callee returns its second argument, so the value that comes back says
// where the struct before it went. If the aggregate consumes the wrong number or
// the wrong file of registers, the following argument is read from the wrong
// place deterministically rather than by scratch-register coincidence.

typedef struct { long  a; float  b; } Pad_Int_Float;
typedef struct { float a; double b; } Pad_Float_Double;
typedef struct { float a, b;        } No_Pad;
typedef struct { struct { float x; } a; double b; } Nested;
typedef union  { float x; float y;  } Union_Float;
typedef struct { union { float x; float y; } u; double b; } Union_In_Struct;

double c_pad_int_float   (Pad_Int_Float s,    double next) { (void)s; return next; }
double c_pad_float_double(Pad_Float_Double s, double next) { (void)s; return next; }
double c_no_pad          (No_Pad s,           double next) { (void)s; return next; }
double c_nested          (Nested s,           double next) { (void)s; return next; }
double c_union_float     (Union_Float s,      double next) { (void)s; return next; }
double c_union_in_struct (Union_In_Struct s,  double next) { (void)s; return next; }

Pad_Int_Float c_make_pad_int_float(void)    { Pad_Int_Float s    = {11, 2.5f};   return s; }
Union_Float   c_make_union_float(void)      { Union_Float s;     s.x = 2.5f;     return s; }
