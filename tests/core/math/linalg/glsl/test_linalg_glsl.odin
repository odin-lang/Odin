package test_core_math_linalg_glsl_math

import glsl "core:math/linalg/glsl"

import "core:testing"

@test
test_normalize_scalar :: proc(t: ^testing.T) {
	for v in ([]f64{-1000, -10, -0.5, 0.5, 3, 1000}) {
		e := f64(1) if v > 0 else -1
		d := glsl.normalize(v)
		testing.expectf(t, d == e, "normalize(%v) = %v, want %v", v, d, e)
		f := glsl.normalize(f32(v))
		testing.expectf(t, f == f32(e), "normalize(f32(%v)) = %v, want %v", v, f, e)
	}
}

@test
test_refract :: proc(t: ^testing.T) {
	i := glsl.normalize(glsl.dvec4{1, -1, 0.5, 0.25})
	n := glsl.dvec4{0, 1, 0, 0}
	ni := glsl.dot(n, i)

	for eta in ([]f64{0.5, 0.75, 1, 1.25, 1.5, 2}) {
		k := 1 - eta*eta*(1 - ni*ni)
		e: glsl.dvec4
		if k > 0 {
			e = eta*i - (eta*ni + glsl.sqrt(k))*n
		}

		d4 := glsl.refract(i, n, eta)
		testing.expectf(t, glsl.length(d4 - e) < 1e-12, "refract(%v, %v, %v) = %v, want %v", i, n, eta, d4, e)
		d3 := glsl.refract(i.xyz, n.xyz, eta)
		testing.expectf(t, glsl.length(d3 - e.xyz) < 1e-12, "refract(%v, %v, %v) = %v, want %v", i.xyz, n.xyz, eta, d3, e.xyz)
		d2 := glsl.refract(i.xy, n.xy, eta)
		testing.expectf(t, glsl.length(d2 - e.xy) < 1e-12, "refract(%v, %v, %v) = %v, want %v", i.xy, n.xy, eta, d2, e.xy)

		f4 := glsl.refract(glsl.vec4(i), glsl.vec4(n), f32(eta))
		testing.expectf(t, glsl.length(f4 - glsl.vec4(e)) < 1e-6, "refract(%v, %v, %v) = %v, want %v", i, n, eta, f4, e)
		f3 := glsl.refract(glsl.vec3(i.xyz), glsl.vec3(n.xyz), f32(eta))
		testing.expectf(t, glsl.length(f3 - glsl.vec3(e.xyz)) < 1e-6, "refract(%v, %v, %v) = %v, want %v", i.xyz, n.xyz, eta, f3, e.xyz)
		f2 := glsl.refract(glsl.vec2(i.xy), glsl.vec2(n.xy), f32(eta))
		testing.expectf(t, glsl.length(f2 - glsl.vec2(e.xy)) < 1e-6, "refract(%v, %v, %v) = %v, want %v", i.xy, n.xy, eta, f2, e.xy)
	}
}

@test
test_orientation :: proc(t: ^testing.T) {
	ups := [?]glsl.dvec3{{0, 1, 0}, {1, 0, 0}, {0, 0, 1}, {0, -1, 0}, glsl.normalize(glsl.dvec3{1, 2, 3})}
	for up in ups {
		normals := [?]glsl.dvec3{
			up,
			-up,
			glsl.normalize(up + {1e-9, 0, 0}),
			glsl.normalize(-up + {1e-9, 0, 0}),
			up + {1e-30, 0, 0},
			-up + {1e-30, 0, 0},
			glsl.normalize(up + {0.5, -0.25, 1}),
		}
		for normal in normals {
			d := glsl.dmat4Orientation(normal, up)
			r := (d * glsl.dvec4{up.x, up.y, up.z, 0}).xyz
			testing.expectf(t, glsl.length(r - normal) < 1e-6, "dmat4Orientation(%v, %v) * up = %v, want %v", normal, up, r, normal)

			f := glsl.mat4Orientation(glsl.vec3(normal), glsl.vec3(up))
			rf := (f * glsl.vec4{f32(up.x), f32(up.y), f32(up.z), 0}).xyz
			testing.expectf(t, glsl.length(rf - glsl.vec3(normal)) < 1e-3, "mat4Orientation(%v, %v) * up = %v, want %v", normal, up, rf, normal)
		}
	}
}

@test
test_quat_nlerp_shortest_path :: proc(t: ^testing.T) {
	q := glsl.quat(1)
	n := glsl.nlerp(q, -q, 0.5)
	testing.expectf(t, n == q, "nlerp(q, -q, 0.5) = %v, want %v", n, q)
	d := glsl.dquat(1)
	dn := glsl.nlerp(d, -d, 0.5)
	testing.expectf(t, dn == d, "nlerp(d, -d, 0.5) = %v, want %v", dn, d)
}
