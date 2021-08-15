//https://www.shadertoy.com/view/NlSSRy

uniform vec2 resolution;
uniform float time;
uniform sampler2D tex0;
uniform sampler2D tex1;
uniform vec4 iDate;
uniform vec4 iMouse;

out vec4 fragColor;

#define iResolution resolution
#define iTime time
#define iChannel0 tex0
#define iChannel1 tex1

#define PI 3.14159265359
mat2 rotate(float angle) {
	return mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
}

float quadrant(in vec2 p, in int qi) {
	vec2 q[4] = vec2[4](vec2(1., -1.), vec2(2., 1.), vec2(1.), vec2(2., -1.));

	p *= rotate(PI / q[qi].x);
	return dot(vec2(-abs(p.x), p.y), vec2(1., q[qi].y * 1.));
}

float _4seg(in vec2 p, in float s, in float seg_t, in float seg_l,
            in vec4 quadrants) {
	vec2 _p = p;
	p = abs(p) - s;
	float l = min(-dot(p, vec2(1., 1.)), abs(dot(p, vec2(1., -1.)))) - seg_l;
	float segs = min(seg_t - abs(max(p.x, p.y) * -1.), l);

	float all_segs = min(min(segs, quadrant(_p, 0)), quadrants[0]);
	all_segs = max(all_segs, min(min(segs, quadrant(_p, 1)), quadrants[1]));
	all_segs = max(all_segs, min(min(segs, quadrant(_p, 2)), quadrants[2]));
	all_segs = max(all_segs, min(min(segs, quadrant(_p, 3)), quadrants[3]));

	return all_segs;
}

float _7seg(in vec2 p, in float s, in float seg_t, in float seg_l, vec4 bb,
            vec4 bt) {
	return max(
	    _4seg(p - vec2(0., .5), s, seg_t, seg_l, vec4(bt.x, bt.y, bt.z, bt.w)),
	    _4seg(p - vec2(0., -.5), s, seg_t, seg_l,
	          vec4(bb.x, bb.y, bb.z, bb.w)));
}

void main() {
	vec2 p = (2. * gl_FragCoord.xy - iResolution.xy) / iResolution.y;

	p *= 1.75;

	vec4[10] bt_brightness = vec4[10](
	    vec4(1., 1., 0., 1.), vec4(0., 1., 0., 0.), vec4(1., 1., 1., 0.),
	    vec4(1., 1., 1., 0.), vec4(0., 1., 1., 1.), vec4(1., 0., 1., 1.),
	    vec4(1., 0., 1., 1.), vec4(1., 1., 0., 0.), vec4(1., 1., 1., 1.),
	    vec4(1., 1., 1., 1.));

	vec4[10] bb_brightness = vec4[10](
	    vec4(0., 1., 1., 1.), vec4(0., 1., 0., 0.), vec4(1., 0., 1., 1.),
	    vec4(1., 1., 1., 0.), vec4(1., 1., 0., 0.), vec4(1., 1., 1., 0.),
	    vec4(1., 1., 1., 1.), vec4(0., 1., 0., 0.), vec4(1., 1., 1., 1.),
	    vec4(1., 1., 1., 0.));

	int index = int(mod(iTime, 10.));

	float scale = .5;
	float _time = .75-sin(iTime/2.)*.65;
	float seg_thickness = .2 * _time;
	float seg_length = .1 * _time;

	float seg_bg = _7seg(p, scale, seg_thickness, seg_length, bb_brightness[8],
	                     bt_brightness[8]);
	float seg = _7seg(p, scale, seg_thickness, seg_length, bb_brightness[index],
	                  bt_brightness[index]);

	seg = smoothstep(0., .01, seg);
	float bg = smoothstep(0., .01, seg_bg) * .1;

	fragColor = vec4(vec3(max(seg, bg)), 1.);
}
