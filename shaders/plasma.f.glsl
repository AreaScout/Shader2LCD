#ifdef GL_ES
precision highp float;
#endif

uniform vec2 resolution;
uniform float time;
uniform sampler2D tex0;
uniform sampler2D tex1;

out vec4 fragColor;

const float PI = 3.14159265;


void main(void ) {

    //time = time * 0.02;
	float color1, color2, color;
	
	color1 = (sin(dot(gl_FragCoord.xy,vec2(sin(time*3.0),cos(time*3.0)))*0.02+time*3.0)+1.0)/2.0;
	
	vec2 center = vec2(resolution.x/2.0, resolution.y/2.0) + vec2(resolution.x/2.0*sin(-time*3.0),resolution.y/2.0*cos(-time*3.0));
	
	color2 = (cos(length(gl_FragCoord.xy - center)*0.03)+1.0)/2.0;
	
	color = (color1+ color2)/2.0;

	float red	= (cos(PI*color/0.5+time*3.0)+1.0)/2.0;
	float green	= (sin(PI*color/0.5+time*3.0)+1.0)/2.0;
	float blue	= (sin(+time*3.0)+1.0)/2.0;
	
    fragColor = vec4(red, green, blue, 1.0);
}