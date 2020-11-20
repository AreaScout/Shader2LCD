#ifdef GL_ES
precision highp float;
#endif

uniform vec2 resolution;
uniform float time;
uniform sampler2D tex0;
uniform sampler2D tex1;

out vec4 fragColor;

void main()
{
	vec2 fragCoord;
	vec4 fragColor;
    float
        T = time,
        r = length(fragCoord += gl_FragCoord.xy - (fragColor.xy = (resolution.xy/2.))) / fragColor.y * 4. - 2.8,
        a = atan(fragCoord.y, fragCoord.x),
        B = mod( a+T + sin(a-=T) * sin(T) * 3.14, 1.57 )  - 2.;
    
    r -= T = sin( B += r > cos(B) ? 1.6 : 0.);
    B = cos(B)- T;   

    fragColor =  vec4(5, 9, 9, 0)*B - vec4(-5, 3, 9, 0) * r;
    fragColor *= smoothstep(.45, .4, T = abs(r/B-.5) ) + .5;
  
    fragColor *= T<.5 ? sin(r/B * 13.) * cos(a * 16.) < 0. ? .04 : .05 : 0.;
	fragColor = fragColor;
}