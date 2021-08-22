// Generations (4K)
//
// The result of an ultra-quick coding session.
//
// Thanks to Evvvvil, Flopine, Nusan, BigWings, Iq, Shane
// and a bunch of others for sharing their knowledge!
//
// Processed by 'GLSL Shader Shrinker' (Shrunk by 123 characters)
// (https://github.com/deanthecoder/GLSLShaderShrinker)
// https://www.shadertoy.com/view/WscBzB

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

struct MarchData {
	float d;
	vec3 mat; // RGB
	float spe; // 0: None, 30.0: Shiny
};

float smin(float a, float b, float k) {
	float h = clamp(.5 + .5 * (b - a) / k, 0., 1.);
	return mix(b, a, h) - k * h * (1. - h);
}

mat2 rot(float a) {
	float c = cos(a),
	      s = sin(a);
	return mat2(c, s, -s, c);
}

float sdBox(vec3 p, vec3 b) {
	vec3 q = abs(p) - b;
	return length(max(q, 0.)) + min(max(q.x, max(q.y, q.z)), 0.);
}

float sdCappedCylinder(vec3 p, float h, float r) {
	vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(h, r);
	return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}

vec3 getRayDir(vec3 ro, vec2 uv) {
	vec3 forward = normalize(vec3(2, 4, 0) - ro),
	     right = normalize(cross(vec3(0, 1, 0), forward));
	return normalize(forward + right * uv.x + cross(forward, right) * uv.y);
}

float sdPawn(vec3 p) {
	p.y -= 3.2;
	float d = max(length(p.xz) - .3, p.y);
	d = smin(d, length(p) - .8, .1);
	p.y += 1.05;
	d = smin(d, sdCappedCylinder(p, .75, .07), .5);
	p.y += 1.5;
	d = smin(d, sdCappedCylinder(p, .75, .12), .5);
	p.y += .4;
	return smin(d, sdCappedCylinder(p, .9, .2), .4);
}

float sdKing(vec3 p) {
	p.y -= 1.85;
	float d = sdCappedCylinder(p, .4 - .14 * cos(p.y * 1.4 - .8), 2.);
	p.y--;
	d = smin(d, sdCappedCylinder(p, .7, .1), .2);
	p.y += 2.;
	d = smin(d, sdCappedCylinder(p, .7, .1), .2);
	p.y += .5;
	d = smin(d, sdCappedCylinder(p, 1., .3), .1);
	p.xz *= rot(-.7);
	p.y -= 4.;
	return min(min(d, sdBox(p, vec3(.5, .2, .1))), sdBox(p, vec3(.2, .5, .1)));
}

// Map the scene using SDF functions.
MarchData map(vec3 p) {
	MarchData result = MarchData(sdPawn(p * 1.2), vec3(.8), 20.);
	float gnd = length(p.y);
	if (gnd < result.d) {
		result.d = gnd;
		result.mat = vec3(.2);
	}

	return result;
}

vec3 calcNormal(vec3 p, float t) {
	vec2 e = vec2(.5773, -.5773) * t * .003;
	return normalize(e.xyy * map(p + e.xyy).d + e.yyx * map(p + e.yyx).d + e.yxy * map(p + e.yxy).d + e.xxx * map(p + e.xxx).d);
}

float calcShadow(vec3 p, vec3 lightPos) {
	// Thanks iq.
	vec3 rd = normalize(lightPos - p);
	float res = 1.,
	      t = .5;
	for (float i = 0.; i < 32.; i++) {
		float h = sdKing(p + rd * t);
		res = min(res, 150. * h / t);
		t += h;
		if (res < .01 || t > 20.) break;
	}

	return clamp(res, 0., 1.);
}

// Quick ambient occlusion.
float ao(vec3 p, vec3 n, float h) { return map(p + h * n).d / h; }

/**********************************************************************************/
vec3 vignette(vec3 col, vec2 fc) {
	vec2 q = fc.xy / iResolution.xy;
	col *= .5 + .5 * pow(16. * q.x * q.y * (1. - q.x) * (1. - q.y), .4);
	return col;
}

vec3 applyLighting(vec3 p, vec3 rd, float d, MarchData data) {
	vec3 sunDir = normalize(vec3(-8, 8, -8) - p),
	     n = calcNormal(p, d);
	float ao = dot(vec3(ao(p, n, .2), ao(p, n, .5), ao(p, n, 2.)), vec3(.2, .3, .5)),
	      primary = max(0., dot(sunDir, n)),
	      bounce = max(0., dot(sunDir * vec3(-1, 0, -1), n)) * .1,
	      spe = smoothstep(0., 1., pow(max(0., dot(rd, reflect(sunDir, n))), data.spe));

	// Combine.
	primary *= mix(.4, 1., calcShadow(p, vec3(-8, 8, -8)));
	return data.mat * ((primary + bounce) * ao + spe) * vec3(2, 1.6, 1.4) * exp(-length(p) * .1);
}

vec3 getSceneColor(vec3 ro, vec3 rd) {
	// Raymarch.
	vec3 p;
	float d = .01;
	MarchData h;
	for (float steps = 0.; steps < 45.; steps++) {
		p = ro + rd * d;
		h = map(p);
		if (abs(h.d) < .0015) break;
		if (d > 64.) return vec3(0); // Distance limit reached - Stop.
		d += h.d; // No hit, so keep marching.
	}

	// Lighting.
	return applyLighting(p, rd, d, h);
}

void main() {
	// Camera.
	vec3 ro = vec3(iMouse.x/64., iMouse.y/50.+2., -10.),
	     col = vec3(0);
	ro.yz *= rot(-.2);
	for (float dx = 0.; dx <= 1.; dx++) {
		for (float dy = 0.; dy <= 1.; dy++) {
			vec2 uv = ((gl_FragCoord.xy + vec2(dx, dy) * .5) - .5 * iResolution.xy) / iResolution.y;
			col += getSceneColor(ro, getRayDir(ro, uv));
		}
	}

	col /= 4.;

	// Output to screen.
	fragColor = vec4(vignette(pow(col, vec3(.45)), gl_FragCoord.xy), 1);
}
