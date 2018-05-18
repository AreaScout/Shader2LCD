#ifdef GL_ES
precision highp float;
#endif

uniform vec2 resolution;
uniform float time;
uniform sampler2D tex0;
uniform sampler2D tex1;

const vec3 top = vec3(0.318, 0.831, 1.0);
const vec3 bottom = vec3(0.094, 0.141, 0.424);
const float widthFactor = 1.5;

vec3 calcSine(vec2 uv, float speed, 
              float frequency, float amplitude, float shift, float offset,
              vec3 color, float width, float exponent, bool dir)
{
    float angle = time * speed * frequency * -1.0 + (shift + uv.x) * 2.0;
    
    float y = sin(angle) * amplitude + offset;
    float clampY = clamp(0.0, y, y);
    float diffY = y - uv.y;
    
    float dsqr = distance(y, uv.y);
    float scale = 1.0;
    
    if(dir && diffY > 0.0)
    {
        dsqr = dsqr * 4.0;
    }
    else if(!dir && diffY < 0.0)
    {
        dsqr = dsqr * 4.0;
    }
    
    scale = pow(smoothstep(width * widthFactor, 0.0, dsqr), exponent);
    
    return min(color * scale, color);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec3 color = vec3(mix(bottom, top, uv.y));

    color += calcSine(uv, 0.4, 0.20, 0.2, 0.0, 0.5,  vec3(0.3, 0.3, 0.3), 0.1, 15.0,false);
    color += calcSine(uv, 0.8, 0.40, 0.15, 0.0, 0.5, vec3(0.3, 0.3, 0.3), 0.1, 17.0,false);
    color += calcSine(uv, 0.6, 0.60, 0.15, 0.0, 0.5, vec3(0.3, 0.3, 0.3), 0.05, 23.0,false);

    color += calcSine(uv, 0.2, 0.26, 0.07, 0.0, 0.3, vec3(0.3, 0.3, 0.3), 0.1, 17.0,true);
    color += calcSine(uv, 0.6, 0.36, 0.07, 0.0, 0.3, vec3(0.3, 0.3, 0.3), 0.1, 17.0,true);
    color += calcSine(uv, 1.0, 0.46, 0.07, 0.0, 0.3, vec3(0.3, 0.3, 0.3), 0.05, 23.0,true);
    color += calcSine(uv, 0.4, 0.58, 0.05, 0.0, 0.3, vec3(0.3, 0.3, 0.3), 0.2, 15.0,true);

    gl_FragColor = vec4(color,1.0);
}
