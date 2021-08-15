// https://www.shadertoy.com/view/3dVczw

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

void main()
{
    float time2 = (iTime+29.) * 60.0;

    float s = 0.0, v = 0.0;
    vec2 uv = (-iResolution.xy + 2.0 * gl_FragCoord.xy ) / iResolution.y;
	float t = time2*0.005;
	uv.x += sin(t) * 0.5;
	float si = sin(t + 2.17); // ...Squiffy rotation matrix!
	float co = cos(t);
	uv *= mat2(co, si, -si, co);
	vec3 col = vec3(0.0);
	vec3 init = vec3(0.25, 0.25 + sin(time2 * 0.001) * 0.4, floor(time2) * 0.0008);
	for (int r = 0; r < 100; r++) 
	{
		vec3 p = init + s * vec3(uv, 0.143);
		p.z = mod(p.z, 2.0);
		for (int i=0; i < 10; i++)	p = abs(p * 2.04) / dot(p, p) - 0.75;
		v += length(p * p) * smoothstep(0.0, 0.5, 0.9 - s) * .002;
		// Get a purple and cyan effect by biasing the RGB in different ways...
		col +=  vec3(v * 0.8, 1.1 - s * 0.5, .7 + v * 0.5) * v * 0.013;
		s += .01;
	}
	fragColor = vec4(col, 1.0);
}

/** SHADERDATA
{
	"title": "DT",
	"description": "Description here",
	"model": "person"
}
*/