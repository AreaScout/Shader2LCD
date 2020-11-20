#ifdef GL_ES
precision highp float;
#endif

uniform vec2 resolution;
uniform float time;
uniform sampler2D tex0;
uniform sampler2D tex1;
uniform vec4 iDate;

out vec4 fragColor;

#define iResolution resolution
#define iTime time

float segment(vec2 uv)
{
    uv = abs(uv);
	return (1.0-smoothstep(0.07,0.10,uv.x))
         * (1.0-smoothstep(0.46,0.49,uv.y+uv.x))
         * (1.25 - length(uv*vec2(3.8,1.3)));
}

float sevenSegment(vec2 uv,int num)
{
	float seg= 0.0;
    
    if (num>=2 && num!=7 || num==-2)
        seg = max(seg,segment(uv.yx));
        
    if (num==0 || 
            (uv.y<0.?((num==2)==(uv.x<0.) || num==6 || num==8):
            (uv.x>0.?(num!=5 && num!=6):(num>=4 && num!=7) )))
        seg = max(seg,segment(abs(uv)-0.5)); 
	
    if (num>=0 && num!=1 && num!=4 && (num!=7 || uv.y>0.))
        seg = max(seg,segment(vec2(abs(uv.y)-1.0,uv.x)));
    
	return seg;
}

float showNum(vec2 uv,float nr, bool zeroTrim)
{
    if (uv.x>-3.0 && uv.x<0.0)
    {
        float digit = floor(-uv.x / 1.5);
		nr /= pow(10.,digit);
        nr = mod(floor(nr+0.000001),10.0);
        if (nr==0.0 && zeroTrim && digit!=0.0)
            return 0.;
		return sevenSegment(uv+vec2( 0.75 + digit*1.5,0.0),int(nr));
    }
	return 0.;
}

float dots(vec2 uv)
{
	uv.y = abs(uv.y)-0.5;
	float l = length(uv);
	return (1.0-smoothstep(0.11,0.13,l)) * (1.0-l*2.0);
}

void main()
{
	vec2 uv = (gl_FragCoord.xy-0.5*iResolution.xy) / iResolution.x;
    
    uv *= 11.0;
    uv.x -= 5.+uv.y*.07;

    if (uv.x<-10.0 || uv.x>0.0 || abs(uv.y)>1.2) {
        fragColor = vec4(0.);
    	return;
    }
    
    float p = floor(abs(uv.x/3.5));
    uv.x = mod(uv.x,3.5)-3.5;
    
	float seg = 0.0;
    if (uv.x>-3.)
	    seg = showNum(uv,mod(iDate.w/pow(60.0,p),60.0),p==2.0);
    else
    {
        uv.x += 3.25;
		seg = dots(uv);
    }
	
    fragColor = vec4(seg,0.,0.,1.);
}