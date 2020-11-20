// by iq (2009)
#ifdef GL_ES
precision highp float;
#endif

uniform vec2 resolution;
uniform float time;
uniform sampler2D tex0;
uniform sampler2D tex1;

out vec4 fragColor;

void main(void)
{
    vec2 p = -1.0 + 2.0 * gl_FragCoord.xy / resolution.xy;
    vec2 uv;
   
    float a = atan(p.y,p.x);
    float r = sqrt(dot(p,p));

    uv.x = r - .25*time;
    uv.y = cos(a*5.0 + 2.0*sin(time+7.0*r)) ;

    vec3 col =  (.5+.5*uv.y)*texture2D(tex0,uv).xyz;

    fragColor = vec4(col,1.0);
}

