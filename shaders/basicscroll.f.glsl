#ifdef GL_ES
precision highp float;
#endif

uniform vec2 resolution;
uniform float time;
uniform sampler2D tex0;
uniform sampler2D tex1;

out vec4 fragColor;

#define SCROLL_SPEED 7.0
#define FONT_SIZE 0.40
#define SIN_AMP 1.5
#define SIN_FREQ 0.75
#define SIN_SPEED 3.5
#define SCROLL_LEN 70.
#define COLOR vec4(0., 0., 1., 0.)
#define S(a) c+=char(u,a); u.x-=0.5;

vec4 char(vec2 pos, float c)
{
	vec4 o = texture2D(tex0,clamp(pos, 0., 1.) / 16.+fract(floor(vec2(c, 15.999 - c / 16.)) / 16.));
    return((o.r > 0.) ? COLOR : vec4(0));
}

vec4 Scroll(vec2 u)
{
    vec4 c = vec4(0);
    S(32.);S(32.);S(32.);S(32.);S(32.);S(32.);S(72.);S(101.);S(108.);S(108.);S(111.);S(32.);
    S(115.);S(104.);S(97.);S(100.);S(101.);S(114.);S(116.);S(111.);S(121.);S(32.);S(33.);S(33.);
    S(32.);S(84.);S(104.);S(105.);S(115.);S(32.);S(105.);S(115.);S(32.);S(97.);S(32.);S(98.);
    S(97.);S(115.);S(105.);S(99.);S(32.);S(101.);S(120.);S(97.);S(109.);S(112.);S(108.);S(101.);
    S(32.);S(111.);S(102.);S(32.);S(97.);S(32.);S(98.);S(105.);S(116.);S(109.);S(97.);S(112.);
    S(32.);S(115.);S(105.);S(110.);S(117.);S(115.);S(32.);S(115.);S(99.);S(114.);S(111.);S(108.);
    S(108.);S(32.);S(43.);S(32.);S(108.);S(97.);S(109.);S(101.);S(32.);S(114.);S(97.);S(105.);
    S(110.);S(98.);S(111.);S(119.);S(32.);S(46.);S(46.);S(46.);S(46.);S(32.);S(117.);S(115.);
    S(101.);S(32.);S(105.);S(116.);S(32.);S(97.);S(116.);S(32.);S(121.);S(111.);S(117.);S(114.);
    S(32.);S(111.);S(119.);S(110.);S(32.);S(114.);S(105.);S(115.);S(107.);S(32.);S(46.);S(46.);
    S(46.);S(46.);return c;
}

void main()
{
	vec2 uv = (gl_FragCoord.xy / resolution.y*2.-1.) / FONT_SIZE;
    uv.x+=-4.+mod(time*SCROLL_SPEED,SCROLL_LEN);
    uv.y+=0.5+SIN_AMP*sin(uv.x*SIN_FREQ+time*SIN_SPEED);
    fragColor = (Scroll(uv)==COLOR) ? vec4(gl_FragCoord.xy/resolution.xy,0.5+0.5*sin(time),1.0) : vec4(0);
}