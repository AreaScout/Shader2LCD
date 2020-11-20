
//----------------------------------------------------------
// Amiga_Demos_1.glsl
// Collection of Amiga based demos...
//   v0.1  2016-01-31  initial version
//   v1.0  2016-04-19  first release
//      used codes...
// ReadKey:    https://www.shadertoy.com/view/llVSRm
// Scroller:   https://www.shadertoy.com/view/MtySzd
// RGB_Bars:   https://www.shadertoy.com/view/4lVGzc
// Copper:     https://www.shadertoy.com/view/Md3GRl
// RubberCube: https://www.shadertoy.com/view/4lt3R7
// Amigaball:  https://www.shadertoy.com/view/Xd3XWX
// Greetings:  https://www.shadertoy.com/view/ld2yDz
//----------------------------------------------------------

//--- common data ---

#ifdef GL_ES
precision highp float;
#endif

uniform vec2 resolution;
uniform float time;
uniform sampler2D tex0;
uniform sampler2D tex1;

out vec4 fragColor;

float _time = 0.0;
bool mousePressed = false;
vec2 pos = vec2(0);      //  0 .. 1
vec2 uv  = vec2(0);      // -1 .. 1
vec2 aspect = vec2(1.0); // R.xy / R.y

vec2 tp  = vec2(0);      // text position
vec3 aColor = vec3(0);

//== font handling =========================================

//--- font data ---
#define FONT_SIZE1 0.40
#define FONT_SIZE2 0.25
#define FONT_SPACE 0.45

const vec2 vFontSize  = vec2(8.0, 15.0);  // multiples of 4x5 work best

//----- access to the image of ascii code characters ------

#define SPACE tp.x-=FONT_SPACE;

#define S(a) c+=char(a);   tp.x-=FONT_SPACE;

#define _note  S(10);   //
#define _star  S(28);   // *
#define _smily S(29);
#define _ tp.x-=FONT_SPACE;
#define _exc   S(33);   // !
#define _add   S(43);   // +
#define _comma S(44);   // ,
#define _sub   S(45);   // -
#define _dot   S(46);   // .
#define _slash S(47);   // /

#define _0 S(48);
#define _1 S(49);
#define _2 S(50);
#define _3 S(51);
#define _4 S(52);
#define _5 S(53);
#define _6 S(54);
#define _7 S(55);
#define _8 S(56);
#define _9 S(57);
#define _ddot S(58);   // :
#define _sc   S(59);   // ;
#define _less S(60);   // <
#define _eq   S(61);   // =
#define _gr   S(62);   // >
#define _qm   S(63);   // ?
#define _at   S(64);   // at sign

#define _A S(65);
#define _B S(66);
#define _C S(67);
#define _D S(68);
#define _E S(69);
#define _F S(70);
#define _G S(71);
#define _H S(72);
#define _I S(73);
#define _J S(74);
#define _K S(75);
#define _L S(76);
#define _M S(77);
#define _N S(78);
#define _O S(79);
#define _P S(80);
#define _Q S(81);
#define _R S(82);
#define _S S(83);
#define _T S(84);
#define _U S(85);
#define _V S(86);
#define _W S(87);
#define _X S(88);
#define _Y S(89);
#define _Z S(90);

#define _a S(97);
#define _b S(98);
#define _c S(99);
#define _d S(100);
#define _e S(101);
#define _f S(102);
#define _g S(103);
#define _h S(104);
#define _i S(105);
#define _j S(106);
#define _k S(107);
#define _l S(108);
#define _m S(109);
#define _n S(110);
#define _o S(111);
#define _p S(112);
#define _q S(113);
#define _r S(114);
#define _s S(115);
#define _t S(116);
#define _u S(117);
#define _v S(118);
#define _w S(119);
#define _x S(120);
#define _y S(121);
#define _z S(122);

//----------------------------------------------------------
// return font image intensity of character ch at text position tp
//----------------------------------------------------------
float char(int ch)
{
  //vec4 f = texture(iChannel0,clamp(tp,0.,1.)/16.+fract(floor(vec2(ch,15.999-float(ch)/16.))/16.));
  vec4 f = any(lessThan(vec4(tp,1,1), vec4(0,0,tp)))
               ? vec4(0)
               : texture2D(tex0,0.0625*(tp + vec2(ch - ch/16*16,15 - ch/16)));
  if (mousePressed)
    return f.x;   // 2d
  else
    return f.x * (f.y+0.3)*(f.z+0.3)*2.0;   // 3d
}

//== display values ========================================

//--- display number fraction with leading zeros ---
float drawFract(int digits, float fn)
{
  float c = 0.0;
  fn = fract(fn) * 10.0;
  for (int i = 1; i < 60; i++)
  {
    c += char(48 + int(fn)); // add 0..9
    tp.x -= FONT_SPACE;
    digits -= 1;
    fn = fract(fn) * 10.0;
    if (digits <= 0 || fn == 0.0) break;
  }
  tp.x -= FONT_SPACE*float(digits);
  return c;
}

//--- display integer value ---
float drawInt(int val, int minDigits)
{
  float c = 0.;
  int fn = val;
  int digits = 1;
  if (val < 0)
  { val = -val;
    if (minDigits < 1) minDigits = 1;
    else minDigits--;
    _sub                   // add minus char
  }
  for (int n=0; n<10; n++)
  {
    fn /= 10;
    if (fn == 0) break;
    digits++;
  }
  digits = int(max(float(minDigits), float(digits)));
  tp.x -= FONT_SPACE * float(digits);
  for (int n=1; n < 11; n++)
  {
    tp.x += FONT_SPACE; // space
    c += char(48 + (val-((val/=10)*10))); // add 0..9
    if (n >= digits) break;
  }
  tp.x -= FONT_SPACE * float(digits);
  return c;
}

//--- display float value ---
float drawFloat(float fn, int prec, int maxDigits)
{
  float tpx = tp.x-FONT_SPACE*float(maxDigits);
  float c = 0.;
  if (fn < 0.0)
  {
    c = char(45); // write minus sign
    fn = -fn;
  }
  tp.x -= FONT_SPACE;
  c += drawInt(int(fn),1);
  c += char(46); SPACE; // add dot
  c += drawFract(prec, fract(fn));
  tp.x = min(tp.x, tpx);
  return c;
}

float drawFloat(float value)           {return drawFloat(value,2,5);}

float drawFloat(float value, int prec) {return drawFloat(value,prec,2);}

float drawInt(int value)               {return drawInt(value,1);}

//----------------------------------------------------------
// javascript keycodes: http://keycode.info/
// key testing:    https://www.shadertoy.com/view/llVSRm
//----------------------------------------------------------
const int KEY_SPACE = 32;

const int KEY_0  = 48;
const int KEY_1  = 49;
const int KEY_2  = 50;
const int KEY_3  = 51;
const int KEY_4  = 52;
const int KEY_5  = 53;
const int KEY_6  = 54;
const int KEY_7  = 55;
const int KEY_8  = 56;
const int KEY_9  = 57;

const int KEY_F1 = 112;
const int KEY_F2 = 113;
const int KEY_F3 = 114;
const int KEY_F4 = 115;

//----------------------------------------------------------
// get javascript keycode: http://keycode.info/
//----------------------------------------------------------
bool ReadKey(int key, bool toggle)
{
  return 0.5 < texture2D(tex0,vec2((float(key)+0.5) / 256.0, toggle ? 0.75 : 0.25)).x;
}

//----------------------------------------------------------
// render scroll text, mouse.y = sinus height
//----------------------------------------------------------

#define SCROLL_SPEED 2.0
#define SCROLL_LEN 40.
#define SIN_FREQ 0.75
#define SIN_SPEED 3.0

//----------------------------------------------------------
vec3 ScrollText1()
{
  tp = uv / FONT_SIZE1;  // set font size
  tp.x = 2.0*(tp.x -4.0 +mod(_time*SCROLL_SPEED, SCROLL_LEN));
  float SIN_AMP = 1.5 * 0.  / resolution.y - 0.5;
  tp.y += 1.0 +SIN_AMP*sin(tp.x*SIN_FREQ +_time*SIN_SPEED);

  float c = 0.0;

  _A _n _ _A _m _i _g _a _ _l _i _k _e _ _d _e _m _o _ _c _o _l _l _e _c _t _i _o _n 
      
  _ _w _i _t _h _ _3 _d _ _a _n _t _i _a _l _i _a _s _e _d _  _s _i _n _u _s 
      
  _ _s _c _r _o _l _l _e _r _ _u _s _i _n _g
     
  _ _s _h _a _d _e _r _t _o _y _ _f _o _n _t _ _t _e _x _t _u _r _e 
    
  _ _smily _

  _ _H _o _l _d _ _k _e _y _ _1 _dot _dot _4 _ _t _o 

  _ _w _a _t _c _h _ _o _n _l _y _ _s _e _l _e _c _t _e _d _ _d _e _m _o _ _dot _dot _dot _dot

  vec3 fcol = c * vec3(pos, 0.5+0.5*sin(2.0*_time));    
  if (c >= 0.5) return fcol; 
  return mix (aColor, fcol, c);
}
//----------------------------------------------------------
vec3 ScrollText2()
{
  tp = uv / FONT_SIZE2;  // set font size
  tp.x = 1.8*(tp.x -4.0 +mod(_time*SCROLL_SPEED, SCROLL_LEN));
  tp.y = (uv.y + 0.88) / 0.2;  // set position & font size

  float c = 0.0;
  _ _star _ _star _ _star _ _star _ _note _note _note _note _
  _p _l _a _y _i _n _g _  _s _o _u _n _d _c _l _o _u _d _
  _m _u _s _i _c _  _note _D _i _v _i _s _i _o _n  _ _R _u _i _n _e _note _
  _f _r _o _m _  _C _a _r _p _e _n _t _e _r _  _B _r _u _t _
  _note _note _note _note _ _star _ _star _ _star _ _star
  // _1 _2 _3 _4 _5 _6 _7 _8 _9 _0
      
  vec3 fcol = c * vec3(pos, 0.5+0.5*sin(_time));    
  if (c >= 0.5) return fcol; 
  return mix (aColor, fcol, c);
}
//----------------------------------------------------------
// render Amiga Copper Bars
//----------------------------------------------------------
float barsize = 0.04;
float r=0., g=0.0, b=0.0;
vec3 barColor = vec3(0.0);

vec3 Copper()
{
  float df = _time * 0.8;
  r = 0.5 + 0.5 * sin(df + 3.1415);
  g = 0.5 + 0.5 * cos(df);
  b = 0.5 + 0.5 * sin(df);
  for(float i=0.0; i<0.9; i+=0.08)
  {
    float p = 0.7 + 0.2 * cos(1.8*_time+160.*i);
    if ((pos.y <= p + barsize) && (pos.y >= p - barsize))
    {
      barColor = (1.0 - abs(p - pos.y) / barsize) * vec3(r+i,g+i,b+i);
    }
  }
  return barColor;
}
//----------------------------------------------------------
// render red green blue sinus bars
//----------------------------------------------------------
vec3 calcSine(float frequency, float amplitude, float shift, float yOffset
             ,vec3 color, float height)
{
  float y = sin(_time * frequency + shift + uv.x) * amplitude + yOffset;
  return color * smoothstep(height, 0.0, distance(y, uv.y));;
}

vec3 RGB_Bars()
{
  return calcSine(2.0, 0.25, 0.0, 0.5, vec3(0.0, 0.0, 1.0), 0.10)
       + calcSine(2.6, 0.15, 0.2, 0.5, vec3(0.0, 1.0, 0.0), 0.10)
       + calcSine(0.9, 0.35, 0.5, 0.5, vec3(1.0, 0.0, 0.0), 0.10);
}
//------------------------------------------- 
// render transparent rubber cube
//------------------------------------------- 
// Hold LMB to disable transparency

vec3 cubevec;

// Classic iq twist function
vec3 Twist(vec3 p)
{
  float f = sin(_time/3.)*1.45;
  float c = cos(f*p.y);
  float s = sin(f/2.*p.y);
  mat2  m = mat2(c,-s,s,c);
  return vec3(m*p.xz,p.y);
}

// The distance function which generate a rotating twisted rounded cube 
// and we save its pos into cubevec
float Cube( vec3 p )
{
  p = Twist(p);
  cubevec.x = sin(_time);
  cubevec.y = cos(_time);
  mat2 m = mat2( cubevec.y, -cubevec.x, cubevec.x, cubevec.y );
  p.xy *= m;p.xy *= m;p.yz *= m;p.zx *= m;p.zx *= m;p.zx *= m;
  cubevec = p;
  return length(max(abs(p)-vec3(0.4),0.0))-0.08;
}

// Split the face in 4 triangles zones, return color index 0 or 1
float Face( vec2 uv )
{
  uv.y = mod(uv.y, 1.0);
  return ((uv.y < uv.x) != (1.0 - uv.y < uv.x)) ? 1.0 : 0.0;
}

// Classic iq normal
vec3 getNormal( in vec3 p )
{
  vec2 e = vec2(0.005, -0.005);
  return normalize(
    e.xyy * Cube(p + e.xyy) +
    e.yyx * Cube(p + e.yyx) +
    e.yxy * Cube(p + e.yxy) +
    e.xxx * Cube(p + e.xxx));
}

vec3 RubberCube()
{
  const vec3 lightPos = vec3(1.5, 0, 0);
  vec3 cubeColor = aColor;
  float rDist = 0.0,   near = -1.0;
  float rStep = 1.0,   far = -1.0;
  float hd = -1.;
  vec3 ro = vec3 (0.0, 0.0, 2.1);
  vec3 rd = normalize (vec3(uv * aspect, -2.0));
  for(int i = 0; i < 256; i++)
  {
    rStep = Cube (ro +rd*rDist);
    rDist += rStep*0.5;
    if (rDist > 4.0) break;
    if (rStep < 0.001)
    {
      far = Face( cubevec.yx) +Face(-cubevec.yx) +Face( cubevec.xz) 
          + Face(-cubevec.xz) +Face( cubevec.zy) +Face(-cubevec.zy);
    	if(hd < 0.0) hd = rDist;
      if (near < 0.0) near = far;
    	if (!mousePressed) rDist += 0.05;  // 0.05 is a magic number 
      else break; 
    }
  }
  if (near > 0.0)
  {
    vec3 sp = ro + rd*hd;
    vec3 ld = lightPos - sp;
    float lDist = max(length(ld), 0.001);
    ld /= lDist;
    float atten = 1. / (1. + lDist*0.2 + lDist*0.1); 
    float ambience = 0.7;
    vec3 sn = getNormal( sp);
    float diff = min(0.3,max( dot(sn, ld), 0.0));
    float spec = pow(max( dot( reflect(-ld, sn), -rd ), 0.0 ), 32.);
    float mv = near*0.45 +far*far*0.04;  
    const vec3 color1  = vec3(0.2, 0.0, 1.0);
    const vec3 color2  = vec3(1.0, 1.0, 1.0);
    const vec3 specCol = vec3(0.8, 0.5, 1.0);  
    cubeColor = mix(color1, color2, mv);
    if(!mousePressed) 
         cubeColor += aColor / 3.0;   // add some back color
    cubeColor *= diff +ambience +specCol*spec/1.5;
  }
  return cubeColor;
}
//------------------------------------------- 
// render famous amiga ball
//------------------------------------------- 
vec3 AmigaBall()
{
  vec3 backColor = vec3(0.03);
  vec3 ballColor1 = vec3(1);      // white
  vec3 ballColor2 = vec3(1,0,0);  // red

  float a = 0.3,   c = cos(a),   s = sin(a);
  vec2 p, 
    off = vec2(1./4.0, 1./3.24),
    R = resolution.xy,  
    U = pos * aspect;
    p.x = mod(_time+1.25, 5.)/2.5, 
    p.y = mod(_time,     5.2)/2.6;
    p = min(p,2.0 - p); 
    p.y *= p.y;
    p = off + p*(aspect -2.0*off);
  vec2 
    gh = 4.0*(p - vec2(U.x,1.-U.y)),
    xy = mat2(c,-s,s,c) * gh;
  float 
    f = xy.y, 
    rad = length(gh),
    r = min(U, aspect-U).x,
    val = floor( 2.*(9.+5.*p.x/aspect.x + xy.x/sqrt(1.-f*f)) )
        + floor( 9.*(2.+f*.2) );
    if (rad < 1.0)
      return (1.4-rad) * (mod(val,2.0)<0.5 ? ballColor1: ballColor2);
    return aColor;
}
//----------------------------------------------------------
// render 2d starfield
//----------------------------------------------------------
float rand (in vec2 uv)
{
  return fract(sin(dot(uv,vec2(12.4124,48.4124)))*48512.41241);
}

float noise (in vec2 uv)
{
  vec2 b = floor(uv);
  return mix(mix(rand(b),rand(b+1.),.5),mix(rand(b+0.1),rand(b+1.),.5),.5);
}

vec3 Starfield2d()
{
  float stars = 0.;
  for (float layer = 0.; layer < 4.; layer++)
  {
    float s = 320. +20.*layer;
    float n = noise(mod(vec2(uv.x*s +18. * _time - layer*444., uv.y*s),resolution.x));
    stars += step(0.1, pow(n,18.)) * (layer / float(6.));
  }
  return vec3(stars);
}
//----------------------------------------------------------
// render plasma background
//----------------------------------------------------------
vec3 Plasma()
{
  float fScale = 2.1;
  float t1 = _time * 0.01;
  float t2 = _time * 0.8;
  vec2 p = pos*5.0;  
  for(int i=1; i<33; i++) 
  {
    vec2 newp = p;
    newp.x += 0.25/float(i)*cos(float(i)*p.y+t1*cos(t2)*0.3/40.0+0.03*float(i))*fScale-t1;		
    newp.y += 0.50/float(i)*cos(float(i)*p.x+t1*t2*0.3/50.0+0.03*float(i+10))*fScale+12.34;
    p = newp;
  }
  vec3 col = 0.2 * vec3(0.5*sin(3.0*p.x)+0.5, 0.5*sin(3.0*p.y)+0.5, sin(p.x+p.y)) + 0.2;
  return col;
}

//----------------------------------------------------------
#define BACK_DEMOS 4.
#define MAIN_DEMOS 5.

int backDemo = 0;   
int mainDemo = 0;  

vec3 frameDrawing()   // frame and background drawing
{
  float rep = 128.;   // try 8 16 32 64 128 256 ...
  float df = gl_FragCoord.x / rep + _time * 5.0;
  if (pos.y < 0.5) df *= -1.0;
  vec3 color = vec3(0.5 + 0.5 * sin(df + 3.1415)
                   ,0.5 + 0.5 * cos(df)
                   ,0.5 + 0.5 * sin(df));
  if (pos.y > 0.945 && pos.y<0.95)  return color;
  if (pos.y > 0.05  && pos.y<0.055) return color;
  if (pos.y < 0.05  || pos.y>0.95)  return vec3 (0.0, 0.15, 0.25);
 
  if      (backDemo == 1) return vec3(0);
  else if (backDemo == 2) return Starfield2d();
  else if (backDemo == 3) return Plasma();
  return vec3(0);
}
//----------------------------------------------------------
void main()
{
  _time = time;
  mousePressed = false; //(iMouse.z > 0.5);
  pos = gl_FragCoord.xy / resolution.xy; //  0 .. 1
  uv = pos * 2.0 - 1.0;                // -1 .. 1
  aspect = resolution.xy / resolution.y;

  mainDemo = 0;
  if      (ReadKey(KEY_1, false)) mainDemo = 1;
  else if (ReadKey(KEY_2, false)) mainDemo = 2;
  else if (ReadKey(KEY_3, false)) mainDemo = 3;
  else if (ReadKey(KEY_4, false)) mainDemo = 4;

  backDemo = 0;
  if      (ReadKey(KEY_F1, false)) backDemo = 1;
  else if (ReadKey(KEY_F2, false)) backDemo = 2;
  else if (ReadKey(KEY_F3, false)) backDemo = 3;
  else if (ReadKey(KEY_F4, false)) backDemo = 4;

  if (mainDemo == 0)      
    mainDemo = int(mod(_time*0.08, MAIN_DEMOS));

  if (backDemo == 0)      
    backDemo = int(mod(_time*0.1, BACK_DEMOS));
      
  aColor = frameDrawing();
    
  if      (mainDemo == 1) aColor += RGB_Bars();
  else if (mainDemo == 2) aColor += Copper();
  else if (mainDemo == 3) aColor = RubberCube();
  else if (mainDemo == 4) aColor = AmigaBall();

  aColor = ScrollText1();
  aColor = ScrollText2();

  fragColor = vec4(aColor, 1.0);
}