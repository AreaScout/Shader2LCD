#ifdef GL_ES
precision highp float;
#endif

uniform vec2 resolution;
uniform float time;
uniform sampler2D tex0;
uniform sampler2D tex1;

out vec4 fragColor;

void main()
#define r resolution.xy
#define t time
{
    vec2 uv = gl_FragCoord.xy/r;
    vec2 d = vec2 (.1*sin(t),.1*cos(t));
    uv-=.5;
    uv.x*=r.x/r.y;
    float l = length(uv+d)*3.0125*(2.0*uv.y+1.0);
    l=l;
    fragColor = vec4(0.25/l,0.4/l,0.5/l,1.0);
}