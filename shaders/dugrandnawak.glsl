// https://www.shadertoy.com/view/ft2XDz

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

#define lim 5.
#define fGlobalTime iTime
#define qq mod(fGlobalTime,10.)<5.
mat2 rot(float a){float c=cos(a),s=sin(a);return mat2(c,-s,s,c);}
float box(vec3 p,vec3 b){
       vec3 q = abs(p)-b;
       return length(max(vec3(0.),q))+min(0.,max(q.x,max(q.y,q.z)));
}
float bbox(vec3 p){
    //p.xz *=rot(sin(fGlobalTime)*-.785);
    float h = box(p,vec3(1.));
    h = max(abs(p.z)-.1,abs(h)-.1);
  return h;
}
vec2 sdf(vec3 p){
  
  vec3 op ;
  
  if(qq){
    
     p.xy *=rot(p.z*.1);
   p.yz *= rot(-atan(1./sqrt(2.)));
    p.xz *= rot(3.1415/4.);
    op=p;
     p.y+=mix(0.,1.,fract(iTime));
      p.xy = asin(sin(p.xy)*(.8));
  } else {
    op=p;
      p.z+=mod(fGlobalTime,100.);;
    p.z /=1.;
   
   
     p.z = asin(sin(p.z)*.8);
    
    p.z*=1.;
     
    
    }

   
    vec2 h;
  //h.x= mix(box(p,vec3(1.)),length(p)-1.,sin(p.x*(1.+texture(texFFT,abs(p.y)*.1).r*10.)+fGlobalTime));
  h.x = bbox(p);
       float a=.25*abs(floor(fract(iTime*1.)*10.)/10.);
     float rto = dot(vec2(1,1),vec2(1,0)*rot(3.1415*a));
  
   vec4 pp = vec4(p,1.);
 
      h.y = 1.;
   for(float i=0.;i<=lim;i++){
          pp.xy*=rot(a*3.1415);
          pp*=rto;
          vec2 t;
          t.x = bbox(pp.xyz)/pp.a;
          t.y = 1.+i/lim;
          h = t.x < h.x ? t:h;
     }
     vec2 t;
     vec3 oop = op;
     oop.xy =- abs(oop.xy)+1.2;
      oop.x+=(sin(oop.z+fGlobalTime));
     oop.y += (cos(oop.z+fGlobalTime*.1));
       oop.xy =- abs(oop.xy)+1.2;
      t.x = abs(length(oop.xy)-.1)-.1;
      t.y = 2.; 
      h = t.x < h.x ? t:h;
      op.xy *=rot(fGlobalTime*.2);
         op = abs(op)-1.1;
     op.xz *=rot(fGlobalTime);
      
    
     
  return h;
  
}
#define q(s) s*sdf(p+s).x
vec2 e=vec2(.0003,-.0003);
vec3 norm(vec3 p){return normalize(q(e.xyy)+q(e.yxy)+q(e.yyx)+q(e.xxx));}
vec3 pal(float t){return .5+.5*cos(6.28*(1.*t+vec3(.1,.2,.3)));}
void main()
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-.5*iResolution.xy)/iResolution.y;

   
  bool bounce = false;
  vec3 col = vec3(.1);//sqrt(vec3(texture(texFFT,abs(uv.x)).r));
 
  vec3 ro = vec3(0.,0.,-5.);
  vec3 rd = normalize(vec3(uv,1.));
   if(qq) {
     
     ro = vec3(uv*7.,-10.);
     rd = vec3(0,0,1);
     }
  vec3 light = vec3(1.,2.,-3.);
  vec3 rp =ro;
     vec3 acc = vec3(.0);
     float tt =mod(iTime*.1,10.);
     float ttt =mod(iTime*.07,10.);
     float tq = 0.;
  for(float i=0.;i<=69.;i++){
      vec2 d = sdf(rp);
    
         if(d.y == 1.+floor(fract(tt*4.)*10.)/lim) { 
           tq+= exp(-abs(d.x))/10.;
           acc += pal(ttt)*1.5*exp(-abs(d.x))/(10.+sin(length(rp.xy)*10.)*5.);
           d.x = max(abs(d.x),.001);
           
           } 
            if(d.y ==2.) { 
           tq+= exp(-abs(d.x))/10.;
           acc += pal(rp.z*.1+ttt)*exp(-abs(d.x))/(60.-fract(fGlobalTime*.5+rp.z)*30.);
           d.x = max(abs(d.x),.01);
           
           } 
       rp +=rd * d.x;
       if(length(rp)>100.) break;
       
       if(d.x <.001){
          vec3 n = norm(rp);
          if(d.y >= 1.){
             float angle = max(dot(reflect(normalize(light), n), rd), 0.0);
  float specular = pow(angle, 10.0);
            vec3 c = pal(d.y+texture(iChannel0,rp.xy*.1+fGlobalTime).r*.01);
          col = specular*c+c*max(0.,dot(normalize(light-rp),n));; 
         break;
          } else {
               rd = reflect(rd,n+texture(iChannel0,rp.xy).r*.01);
             rp+=rd*.01;
            acc += pal(d.y)*.1;
            bounce = true;
            }
          
         }
    
  }
  col+= +acc;
  if(bounce) col = 1.-col;
    fragColor = vec4(col,1.0);
}
