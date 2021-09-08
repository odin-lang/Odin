package raylib

import "core:math"

EaseLinearNone  :: proc(t, b, c, d: f32) -> f32 { return (c*t/d + b) }
EaseLinearIn    :: proc(t, b, c, d: f32) -> f32 { return (c*t/d + b) }
EaseLinearOut   :: proc(t, b, c, d: f32) -> f32 { return (c*t/d + b) }
EaseLinearInOut :: proc(t, b, c, d: f32) -> f32 { return (c*t/d + b) }

// Sine Easing functions
EaseSineIn    :: proc(t, b, c, d: f32) -> f32 { return (-c*math.cos(t/d*(PI/2.0)) + c + b) }
EaseSineOut   :: proc(t, b, c, d: f32) -> f32 { return (c*math.sin(t/d*(PI/2.0)) + b) }
EaseSineInOut :: proc(t, b, c, d: f32) -> f32 { return (-c/2.0*(math.cos(PI*t/d) - 1.0) + b) }

// Circular Easing functions
EaseCircIn  :: proc(t, b, c, d: f32) -> f32 { 
	t := t
	t /= d 
	return -c*(math.sqrt(1.0 - t*t) - 1.0) + b
}
EaseCircOut :: proc(t, b, c, d: f32) -> f32 { 
	t := t
	t = t/d - 1.0 
	return c*math.sqrt(1.0 - t*t) + b
}
EaseCircInOut :: proc(t, b, c, d: f32) -> f32  {
	t := t
	t /= d/2.0
	if t < 1.0 {
		return -c/2.0*(math.sqrt(1.0 - t*t) - 1.0) + b
	}
	t -= 2.0
	return c/2.0*(math.sqrt(1.0 - t*t) + 1.0) + b
}

// Cubic Easing functions
EaseCubicIn :: proc(t, b, c, d: f32) -> f32 { 
	t := t
	t /= d
	return c*t*t*t + b
}
EaseCubicOut :: proc(t, b, c, d: f32) -> f32 { 
	t := t
	t = t/d - 1.0
	return c*(t*t*t + 1.0) + b
}
EaseCubicInOut :: proc(t, b, c, d: f32) -> f32 {
	t := t
	t /= d/2.0
	if t < 1.0 {
		return c/2.0*t*t*t + b
	}
	t -= 2.0
	return c/2.0*(t*t*t + 2.0) + b
}

// Quadratic Easing functions
EaseQuadIn :: proc(t, b, c, d: f32) -> f32 { 
	t := t
	t /= d
	return c*t*t + b
}
EaseQuadOut :: proc(t, b, c, d: f32) -> f32 { 
	t := t
	t /= d
	return -c*t*(t - 2.0) + b
}
EaseQuadInOut :: proc(t, b, c, d: f32) -> f32 {
	t := t
	t /= d/2.0
	if t < 1 {
		return ((c/2)*(t*t)) + b
	}
	return -c/2.0*(((t - 1.0)*(t - 3.0)) - 1.0) + b
}

// Exponential Easing functions
EaseExpoIn :: proc(t, b, c, d: f32) -> f32 { 
	return (t == 0.0) ? b : (c*math.pow(2.0, 10.0*(t/d - 1.0)) + b)
}
EaseExpoOut :: proc(t, b, c, d: f32) -> f32 { 
	return (t == d) ? (b + c) : (c*(-math.pow(2.0, -10.0*t/d) + 1.0) + b)
}
EaseExpoInOut :: proc(t, b, c, d: f32) -> f32 {
	if t == 0.0 {
		return b
	}
	if t == d {
		return b + c
	}
	t := t
	t /= d/2.0
	if t < 1.0 {
		return c/2.0*math.pow(2.0, 10.0*(t - 1.0)) + b
	}

	return c/2.0*(-math.pow(2.0, -10.0*(t - 1.0)) + 2.0) + b
}

// Back Easing functions
EaseBackIn :: proc(t, b, c, d: f32) -> f32 {
	s :: 1.70158
	t := t
	t /= d
	postFix := t
	return (c*(postFix)*t*((s + 1.0)*t - s) + b)
}

EaseBackOut :: proc(t, b, c, d: f32) -> f32 {
	t := t
	s :: 1.70158
	t = t/d - 1.0
	return (c*(t*t*((s + 1.0)*t + s) + 1.0) + b)
}

EaseBackInOut :: proc(t, b, c, d: f32) -> f32 {
	t := t
	s := f32(1.70158)
	t /= d/2
	if t < 1.0 {
		s *= 1.525
		return (c/2.0*(t*t*((s + 1.0)*t - s)) + b)
	}

	t -= 2
	postFix := t
	s *= 1.525
	return (c/2.0*((postFix)*t*((s + 1.0)*t + s) + 2.0) + b)
}

// Bounce Easing functions
EaseBounceOut :: proc(t, b, c, d: f32) -> f32 {
	t := t
	t /= d
	switch {
	case t < 1.0/2.75:
		return (c*(7.5625*t*t) + b)
	case t < 2.0/2.75:
		t -= 1.5/2.75
		postFix := t
		return (c*(7.5625*(postFix)*t + 0.75) + b)
	case t < 2.5/2.75:
		t -= 2.25/2.75
		postFix := t
		return (c*(7.5625*(postFix)*t + 0.9375) + b)
	case:
		t -= 2.625/2.75
		postFix := t
		return (c*(7.5625*(postFix)*t + 0.984375) + b)
	}
}

EaseBounceIn :: proc(t, b, c, d: f32) -> f32 { 
	return c - EaseBounceOut(d - t, 0.0, c, d) + b 
}
EaseBounceInOut :: proc(t, b, c, d: f32) -> f32 {
	if t < d/2.0 {
		return EaseBounceIn(t*2.0, 0.0, c, d)*0.5 + b
	} else {
		return EaseBounceOut(t*2.0 - d, 0.0, c, d)*0.5 + c*0.5 + b
	}
}

// Elastic Easing functions
EaseElasticIn :: proc(t, b, c, d: f32) -> f32 {
	if t == 0.0 {
		return b
	}
	t := t
	t /= d
	if t == 1.0 {
		return b + c
	}

	p := d*0.3
	a := c
	s := p/4.0
	t -= 1
	postFix := a*math.pow(2.0, 10.0*t)

	return -(postFix*math.sin((t*d-s)*(2.0*PI)/p )) + b
}

EaseElasticOut :: proc(t, b, c, d: f32) -> f32 {
	if t == 0.0 {
		return b
	}
	t := t
	t /= d
	if t == 1.0 {
		return b + c
	}

	p := d*0.3
	a := c
	s := p/4.0

	return a*math.pow(2.0,-10.0*t)*math.sin((t*d-s)*(2.0*PI)/p) + c + b
}

EaseElasticInOut :: proc(t, b, c, d: f32) -> f32 {
	if t == 0.0 {
		return b
	}
	t := t
	t /= d/2.0
	if t == 2.0 {
		return b + c
	}

	p := d*(0.3*1.5)
	a := c
	s := p/4.0

	t -= 1
	if t < 1.0 {
		postFix := a*math.pow(2.0, 10.0*t)
		return -0.5*(postFix*math.sin((t*d-s)*(2.0*PI)/p)) + b
	}

	postFix := a*math.pow(2.0, -10.0*t)
	return (postFix*math.sin((t*d-s)*(2.0*PI)/p)*0.5 + c + b)
}