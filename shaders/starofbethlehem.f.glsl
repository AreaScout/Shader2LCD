// https://www.shadertoy.com/view/wldcWr
// Cheap 2D Humanoid SDF for dropping into scenes to add a sense of scale.
// Hazel Quantock 2018
// This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. http://creativecommons.org/licenses/by-nc-sa/4.0/
// https://www.shadertoy.com/view/4scBWN

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

#define PI 3.142
#define saturate(x) clamp(x, 0.0, 1.0)

float RoundMax( float a, float b, float r )
{
    a += r; b += r;

    float f = ( a > 0. && b > 0. ) ? sqrt(a*a+b*b) : max(a,b);

    return f - r;
}

float RoundMin( float a, float b, float r )
{
    return -RoundMax(-a,-b,r);
}

// Humanoid, feet placed at <0,0>, with height of ~1.8 units on y
float Humanoid( in vec2 uv, in float phase )
{
    #define Rand(idx) fract(phase*pow(1.618,float(idx)))
    float n3 = sin((uv.y-uv.x*.7)*11.+phase)*.014; // "pose"
    float n0 = sin((uv.y+uv.x*1.1)*23.+phase*2.)*.007;
    float n1 = sin((uv.y-uv.x*.8)*37.+phase*4.)*.004;
    float n2 = sin((uv.y+uv.x*.9)*71.+phase*8.)*.002;
    //uv.x += n0+n1+n2; uv.y += -n0+n1-n2;

    float head = length((uv-vec2(0,1.65))/vec2(1,1.2))-.15/1.2;
    float neck = length(uv-vec2(0,1.5))-.05;
    float torso = abs(uv.x)-.25;
    //torso += .2*(1.-cos((uv.y-1.)*3.));
    //torso = RoundMax( torso, abs(uv.y-1.1)-.4, .2*(uv.y-.7)/.8 );
    torso = RoundMax( torso, uv.y-1.5, .2 );
    torso = RoundMax( torso, -(uv.y-.5-.4*Rand(3)), .0 );

    float f = RoundMin(head,neck,.04);
    f = RoundMin(f,torso,.02);

    float leg =
        Rand(1) < .3 ?
        abs(uv.x)-.1-.1*uv.y : // legs together
        abs(abs(uv.x+(uv.y-.8)*.1*cos(phase*3.))-.15+.1*uv.y)-.05-.04*Rand(4)-.07*uv.y; // legs apart
    leg = max( leg, uv.y-1. );

    f = RoundMin(f,leg,.2*Rand(2));

    f += (-n0+n1+n2+n3)*(.1+.9*uv.y/1.6);

    float sdf = max( f, -uv.y );
    return .5+.5*sdf/(abs(sdf)+.002);
}

mat2 rotate(float angle)
{
    angle *= PI / 180.0;
    float s = sin(angle), c = cos(angle);
    return mat2( c, -s, s, c );
}



float hash21(vec2 p)
{
    p = fract( p*vec2(123.34, 456.21) );
    p += dot(p, p+45.32);
    return fract(p.x*p.y);
}

vec3 hash23( vec2 co )
{
   vec3 a = fract( cos( co.x*8.3e-3 + co.y )*vec3(1.3e5, 4.7e5, 2.9e5) );
   vec3 b = fract( sin( co.x*0.3e-3 + co.y )*vec3(8.1e5, 1.0e5, 0.1e5) );
   vec3 c = mix(a, b, 0.5);
   return c;
}




float star(vec2 uv, float _time, float flare)
{
    float d = length(uv);
    float m = (max(0.2, abs(sin(_time))) * 0.02) / d;

    float rays = max(0., 1.-abs(uv.x*uv.y*1000.));
    m += rays*flare;
    uv *= rotate(45.0);
    rays = max(0., 1.-abs(uv.x*uv.y*1000.));
    m += rays*0.5*flare;

    m *= smoothstep(1.0, 0.2, d);

    return m;
}



float starFieldMin(vec2 p)
{
    vec3 rnd = hash23(p * iResolution.x);
    float intensity = pow((1.+sin((iTime+27.0)*rnd.x))*.5, 7.) ;
    return max(rnd.x * pow(rnd.y,7.) * intensity, 0.);

}


vec3 starField(vec2 uv)
{
    vec3 col = vec3(0);

    vec2 gv = fract(uv) - 0.5;
    vec2 id = floor(uv);

    for (int x=-1; x<=1; x++){
        for (int y=-1; y<=1; y++)
        {
            vec2 offset = vec2(x, y);

            float n = hash21(id + offset);
            float size = min(0.25, fract(n*1234.567) + 0.1);
            float star = star(gv - offset - (vec2(n, fract(n*100.0)) - 0.5), iTime*fract(n*135.246), smoothstep(.9, 1., size)*.6);

            col += star * size;
        }
    }

    return col;
}




float wave(vec2 p)
{
    return 1.0-abs( p.y+sin(p.x) );
}


float terrain(vec2 uv)
{
    float d = 0.0;
    float x = uv.x*2.0, f = 0.8, a = 0.05;
    for (int p=0; p<5; p++){
        d += sin(x * f) * a;
        f *= 2.0;
        a *= 0.5;
    }
    d = abs(d);
    return sign((uv.y+d)-0.1);
}




const vec3 purple = vec3(0.318,0.192,0.369);
const vec3 green = vec3(0.41, 0.86, 0.6);


void main()
{
    vec2 uv = gl_FragCoord.xy/min(iResolution.x, iResolution.y);
    vec2 uvS = gl_FragCoord.xy/iResolution.xy;

    vec2 uvR = uv * rotate(mod(iTime*0.4, 360.0));
    //uvR.y += iTime*0.01;

    vec3 color;

    color += (starField(uvR*50.0)) + starFieldMin(uv)*2.0;

    float mStar = pow(star(uv-vec2(1.3, 0.7), 1.0, smoothstep(0.2, 1.0, 0.45)*.6), 1.0);
    color += mStar*0.8 * vec3(0.702,1.000,0.941);

    color += purple * pow(
        wave(vec2(-uvS.x*2.0 + 1.8, (uv.y-0.7) * 1.5)),
        3.0
    );

    vec3 sky = pow(
        mix(
            green, purple,
            saturate(pow(uvS.y-0.03, 0.5) * (uvS.x+0.7) * (1.0-uvS.x+0.5))
        ), vec3(3.0)
    ) * 2.0;
    color += sky;


    color *= terrain(uv);

    uv.x -= 0.5;
    uv.y -= 0.03;
    color *= Humanoid(uv*9.0, 1.0);

    // Output to screen
    fragColor = vec4(color, 1.0);
}



