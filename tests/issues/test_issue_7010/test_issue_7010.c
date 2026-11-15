// Tests issue: https://github.com/odin-lang/Odin/issues/7010

// #include <simd/types.h>
// #ifdef __APPLE__
// #include <simd/simd.h>
// #else
typedef __attribute__((__ext_vector_type__(2))) float simd_float2;
typedef __attribute__((__ext_vector_type__(4))) float simd_float4;
typedef __attribute__((__ext_vector_type__(2))) unsigned int simd_uint2;
typedef struct { simd_float4 columns[4]; } simd_float4x4;
typedef struct { simd_float2 columns[4]; } simd_float4x2;
// typedef simd_float4x4 matrix_float4x4;
// #endif

typedef struct { simd_float4 columns[5]; } simd_float5x4;

simd_float4 c_add_vec4f32(simd_float4 a, simd_float4 b) {
  	return a + b;
}

simd_uint2 c_add_vec2u32(simd_uint2 a, simd_uint2 b) {
    return a + b;
}

simd_float4x4 c_add_matrix4x4(simd_float4x4 a, simd_float4x4 b) {
  simd_float4x4 copy_mat = a;
  copy_mat.columns[0] += b.columns[0];
  copy_mat.columns[1] += b.columns[1];
  copy_mat.columns[2] += b.columns[2];
  copy_mat.columns[3] += b.columns[3];
  return copy_mat;
}

simd_float5x4 c_add_matrix5x4(simd_float5x4 a, simd_float5x4 b) {
  simd_float5x4 copy_mat = a;
  copy_mat.columns[0] += b.columns[0];
  copy_mat.columns[1] += b.columns[1];
  copy_mat.columns[2] += b.columns[2];
  copy_mat.columns[3] += b.columns[3];
  copy_mat.columns[4] += b.columns[4];
  return copy_mat;
}

simd_float4x2 c_add_matrix4x2(simd_float4x2 a, simd_float4x2 b) {
  simd_float4x2 copy_mat = a;
  copy_mat.columns[0] += b.columns[0];
  copy_mat.columns[1] += b.columns[1];
  copy_mat.columns[2] += b.columns[2];
  copy_mat.columns[3] += b.columns[3];
  return copy_mat;
}
