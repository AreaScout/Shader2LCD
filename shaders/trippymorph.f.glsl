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
    float t = iTime;
    float tiling = 15.;
    float r = .5;
    float rm = mix(.078,.5,sin(t*3.)*.5+.5); // mix(min,max,change amount)

    // Normalized pixel coordinates (from 0 to 1) with 0,0 moved to center
    vec2 uv = (gl_FragCoord.xy-.5*iResolution.xy)/iResolution.y;

    //make grid
    vec2 gv = fract(uv*tiling)-.5;

    //make id for each tile on grid(?)
    vec2 id = floor(uv*tiling);

    //Make Circles
    float d = length(uv);
    float d2 = length(gv);
    float d3 = length (gv - id)*3.;


     rm = mix(.078,.5,sin(t*d3/9.)*.5+.5); // mix(min,max,change amount)
     
    //Smooth/Animate Circles
    float c = smoothstep(rm,rm*.9,d);
    float c2 = smoothstep(rm,rm*.9,d2);



    //visualize here
    vec3 col =vec3(c2);
       col.r *= sin(t+d);
       col.g *= cos(t+d3);


    // Output to screen
    fragColor = vec4(col,1.0);
}