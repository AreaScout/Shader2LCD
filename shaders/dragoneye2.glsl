// License CC0: DragonEye II
// A year or so ago I played with quasi crystals and I found they looked like "dragon eyes" with certain parameters
// This is an evolution of that idea.
// https://www.shadertoy.com/view/NlSSDG

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

#define TIME        iTime
#define TTIME       (TAU*TIME)
#define RESOLUTION  iResolution
#define PI          3.141592654
#define TAU         (2.0*PI)
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))
#define LAYERS      6
#define FBM         3
#define DISTORT     1.4
#define PCOS(x)     (0.5+0.5*cos(x))

// https://stackoverflow.com/a/17897228/418488
const vec4 hsv2rgb_K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
  return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}
// Macro version of above to enable compile-time constants
#define HSV2RGB(c)  (c.z * mix(hsv2rgb_K.xxx, clamp(abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www) - hsv2rgb_K.xxx, 0.0, 1.0), c.y))

const float eyeAngle = 0.8;
const mat2  eyeRot = ROT(eyeAngle);
const vec2  eyeRef = vec2(cos(eyeAngle), sin(eyeAngle));

float g_psy_th = 0.0;
float g_psy_hf = 0.0;

vec2 g_psy_vx = vec2(0.0);
vec2 g_psy_vy = vec2(0.0);

vec2 g_psy_wx = vec2(0.0);
vec2 g_psy_wy = vec2(0.0);

const vec3 lightPos1 = 100.0*vec3(-1.3, 1.9, 2.0);
const vec3 lightPos2 = 100.0*vec3(9.0,  3.2, 1.0);
const vec3 lightDir1 = normalize(lightPos1);
const vec3 lightDir2 = normalize(lightPos2);
const vec3 lightCol1 = vec3(8.0/8.0,7.0/8.0,6.0/8.0);
const vec3 lightCol2 = vec3(8.0/8.0,6.0/8.0,7.0/8.0);
const vec3 skinCol1  = vec3(0.6, 0.2, 0.2);
const vec3 skinCol2  = vec3(0.6);

vec3 saturate(in vec3 a) { return clamp(a, 0.0, 1.0); }
vec2 saturate(in vec2 a) { return clamp(a, 0.0, 1.0); }
float saturate(in float a) { return clamp(a, 0.0, 1.0); }

float tanh_approx(float x) {
//  return tanh(x);
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

// IQ's smooth min: https://www.iquilezles.org/www/articles/smin/smin.htm
float pmin(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

float pmax(float a, float b, float k) {
  return -pmin(-a, -b, k);
}

float pabs(float a, float k) {
  return pmax(a, -a, k);
}

vec2 toPolar(vec2 p) {
  return vec2(length(p), atan(p.y, p.x));
}

vec2 toRect(vec2 p) {
  return vec2(p.x*cos(p.y), p.x*sin(p.y));
}

// https://mercury.sexy/hg_sdf/
float modMirror1(inout float p, float size) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  p = mod(p + halfsize,size) - halfsize;
  p *= mod(c, 2.0)*2.0 - 1.0;
  return c;
}

float smoothKaleidoscope(inout vec2 p, float sm, float rep) {
  vec2 hp = p;

  vec2 hpp = toPolar(hp);
  float rn = modMirror1(hpp.y, TAU/rep);

  float sa = PI/rep - pabs(PI/rep - abs(hpp.y), sm);
  hpp.y = sign(hpp.y)*(sa);

  hp = toRect(hpp);

  p = hp;

  return rn;
}

float vesica(vec2 p, vec2 sz) {
  if (sz.x < sz.y) {
    sz = sz.yx;
  } else {
    p  = p.yx; 
  }
  vec2 sz2 = sz*sz;
  float d  = (sz2.x-sz2.y)/(2.0*sz.y);
  float r  = sqrt(sz2.x+d*d);
  float b  = sz.x;
  p = abs(p);
  return ((p.y-b)*d>p.x*b) ? length(p-vec2(0.0,b))
                           : length(p-vec2(-d,0.0))-r;
}

// https://www.iquilezles.org/www/articles/spherefunctions/spherefunctions.htm
float raySphere(vec3 ro, vec3 rd, vec4 sph) {
    vec3 oc = ro - sph.xyz;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - sph.w*sph.w;
    float h = b*b - c;
    if( h<0.0 ) return -1.0;
    h = sqrt( h );
    return -b - h;
}

float outer(vec2 p) {
  p *= eyeRot;
  return vesica(p, 1.0*vec2(0.5, 0.25))-0.15;
}

float inner(vec2 p) {
  p *= eyeRot;
  return vesica(p, 1.0*vec2(0.125, 0.35));
}


float qc_wave(float theta, vec2 p) {
  return (cos(dot(p,vec2(cos(theta),sin(theta)))));
}

float qc_noise(vec2 p) {
  float sum = 0.;
  float a = 1.0;
  for(int i = 0; i < LAYERS; ++i)  {
    float theta = float(i)*PI/float(LAYERS);
    sum += qc_wave(theta, p)*a;
    a*=DISTORT;
  }

  return abs(tanh_approx(sum));
}

float qc_fbm(vec2 p, float _time) {
  float sum = 0.;
  float a = 1.0;
  float f = 1.0;
  for(int i = 0; i < FBM; ++i)  {
    sum += a*qc_noise(p*f);
    a *= 2.0/3.0;
    f *= 2.31;
  }

  return 0.45*(sum);
}

float qc_height(vec2 p) {
  float od = outer(p);
  float l = length(p);
  const float s = 5.0;
  p *= s;
//  return -5.0*pmin(fbm(p), 0.75, 2.5)*exp(-5.0*l);
  float sm = 0.05;
  float oh = smoothstep(0.0, sm, od); 
  
  float h =  -5.0*qc_fbm(p, TIME)*exp(-4.0*l)*oh;
  return h;
}

vec3 qc_normal(vec2 p) {
  vec2 v;
  vec2 w;
  vec2 e = vec2(4.0/RESOLUTION.y, 0);
  
  vec3 n;
  n.x = qc_height(p + e.xy) - qc_height(p - e.xy);
  n.y = 2.0*e.x;
  n.z = qc_height(p + e.yx) - qc_height(p - e.yx);
  
  return normalize(n);
}

float psy_noise(vec2 p) {
  float a = sin(p.x);
  float b = sin(p.y);
  float c = 0.5 + 0.5*cos(p.x + p.y);
  float d = mix(a, b, c);
  return d;
}

float psy_fbm(vec2 p, float aa) {
  const mat2 frot = mat2(0.80, 0.60, -0.60, 0.80);

  float f = 0.0;
  float a = 1.0;
  float s = 0.0;
  float m = 2.0;
  for (int x = 0; x < 4; ++x) {
    f += a*psy_noise(p); 
    p = frot*p*m;
    m += 0.01;
    s += a;
    a *= aa;
  }
  return f/s;
}

float psy_warp(vec2 p, out vec2 v, out vec2 w) {
  float id = inner(p); 
  
  const float r  = 0.5;
  const float rr = 0.25;
  float l2 = length(p);
  float f  = 1.0;

  p   -= eyeRef*pmax(0.0, dot(p, eyeRef), 0.25)*2.0;
  p   -= 0.25*eyeRef;

  f = smoothstep(-0.1, 0.15, id);
  const float rep = 50.0;
  const float sm = 0.125*0.5*60.0/rep;
  float  n = smoothKaleidoscope(p, sm, rep);
  p.y += TIME*0.125+1.5*g_psy_th;

  g_psy_hf = f;
  vec2 pp = p;

  vec2 vx = g_psy_vx;
  vec2 vy = g_psy_vy;

  vec2 wx = g_psy_wx;
  vec2 wy = g_psy_wy;

  //float aa = mix(0.95, 0.25, tanh_approx(pp.x));
  float aa = 0.5;

  v = vec2(psy_fbm(p + vx, aa), psy_fbm(p + vy, aa))*f;
  w = vec2(psy_fbm(p + 3.0*v + wx, aa), psy_fbm(p + 3.0*v + wy, aa))*f;
  
  return -tanh_approx(psy_fbm(p + 2.25*w, aa)*f);
}

vec3 psy_normal(vec2 p) {
  vec2 v;
  vec2 w;
  vec2 e = vec2(4.0/RESOLUTION.y, 0);
  
  vec3 n;
  n.x = psy_warp(p + e.xy, v, w) - psy_warp(p - e.xy, v, w);
  n.y = 2.0*e.x;
  n.z = psy_warp(p + e.yx, v, w) - psy_warp(p - e.yx, v, w);
  
  return normalize(n);
}

vec3 psy_weird(vec2 p) {
  vec3 ro = vec3(0.0, 10.0, 0.0);
  vec3 pp = vec3(p.x, 0.0, p.y);

  vec2 v;
  vec2 w;
 
  float h  = psy_warp(p, v, w);
  float hf = g_psy_hf;
  vec3  n  = psy_normal(p);

  vec3 lcol1 = lightCol1;
  vec3 lcol2 = lightCol2;
  vec3 po  = vec3(p.x, 0.0, p.y);
  vec3 rd  = normalize(po - ro);
  
  float diff1 = max(dot(n, lightDir1), 0.0);
  float diff2 = max(dot(n, lightDir2), 0.0);

  vec3  ref   = reflect(rd, n);
  float ref1  = max(dot(ref, lightDir1), 0.0);
  float ref2  = max(dot(ref, lightDir2), 0.0);

  const vec3 col1 = vec3(0.1, 0.7, 0.8).xzy;
  const vec3 col2 = vec3(0.7, 0.3, 0.5).zyx;
  
  float a = length(p);
  vec3 col = vec3(0.0);
//  col -= 0.5*hsv2rgb(vec3(fract(0.3*TIME+0.25*a+0.5*v.x), 0.85, abs(tanh_approx(v.y))));
//  col -= 0.5*hsv2rgb(vec3(fract(sqrt(0.5)*TIME+0.25*a+0.125*w.x), 0.85, abs(tanh_approx(w.y))));
  col += hsv2rgb(vec3(fract(-0.1*TIME+0.125*a+0.5*v.x+0.125*w.x), abs(0.5+tanh_approx(v.y*w.y)), tanh_approx(0.1+abs(v.y-w.y))));
  col -= 0.5*(length(v)*col1 + length(w)*col2*1.0);
   /*
  col += 0.25*diff1;
  col += 0.25*diff2;
  */
  col += 0.5*lcol1*pow(ref1, 20.0);
  col += 0.5*lcol2*pow(ref2, 10.0);
  col *= hf;

  return max(col, 0.0);
}

float vmax(vec2 v) {
  return max(v.x, v.y);
}

float corner(vec2 p) {
  return length(max(p, vec2(0))) + vmax(min(p, vec2(0)));
}

vec3 skyColor(vec3 ro, vec3 rd) {
  float ld1      = max(dot(lightDir1, rd), 0.0);
  float ld2      = max(dot(lightDir2, rd), 0.0);
  vec3 final     = vec3(0.0);

  rd.xy *= ROT(-1.);
  vec2 bp = rd.xz/max(0.0,rd.y);
  float bd = corner(-bp);
  final += 0.3*exp(-5.0*max(bd, 0.0)); 
  final += 0.20*smoothstep(0.025, 0.0, bd); 
  
  final += 8.0*lightCol1*pow(ld1, 100.0);
  final += 8.0*lightCol2*pow(ld2, 100.0);
  
  return final;
}

vec3 eyeColor(vec2 p, vec3 ro, vec3 rd, vec3 po, float od) {
  float aa = 2.0/RESOLUTION.y;
  vec3 sc    = vec3(0.0);
  float sd   = raySphere(ro, rd, vec4(sc, 0.75));
  vec3 spos  = ro + sd*rd;
  vec3 snor  = normalize(spos - sc);
  vec3 refl  = reflect(rd, snor);
  vec3 scol  = skyColor(spos, refl);
  float dif1 = max(dot(snor, lightDir1), 0.0);
  float dif2 = max(dot(snor, lightDir2), 0.0);


  vec3 pcol = psy_weird(p);
  vec3 col1 = vec3(0.0);
  col1 += pcol;
  col1 += scol;
  col1 += 0.025*(dif1*dif1+dif2*dif2);

  vec3 col2 = 0.125*(skinCol1)*(dif1 + dif2)+0.125*sqrt(scol);
 
  snor.xz *= ROT(-0.5*eyeAngle);
  snor.xy *= ROT(-2.4*smoothstep(0.99, 1.0, sin(TTIME/12.0)));
  float a = atan(snor.y, snor.x);

  vec3 col = mix(col1, col2, step(a, 0.0));

  col *= smoothstep(0.0, -0.1, od);
  
  return col;
}

vec3 skinColor(vec2 p, vec3 ro, vec3 rd, vec3 po, float od) {
  float lp = length(p);
  float aa = 2.0/RESOLUTION.y;

  float qch = qc_height(p);
  vec3  qcn = qc_normal(p);

  float diff1 = max(dot(qcn, lightDir1), 0.0);
  float diff2 = max(dot(qcn, lightDir2), 0.0);

  vec3  ref   = reflect(rd, qcn);
  vec3  scol  = skyColor(po, ref);

  vec3 lcol1 = lightCol1;
  vec3 lcol2 = lightCol2;
  vec3 lpow1 = 0.25*lcol1;
  vec3 lpow2 = 0.5*lcol2;
  vec3 dm = mix(1.0*skinCol1, skinCol2, 1.0+tanh_approx(2.0*qch))*tanh_approx(-qch*10.0+0.125);
  vec3 col = vec3(0.0);
  col += dm*sqrt(diff1)*lpow1;
  col += dm*sqrt(diff2)*lpow2;

  const float ff = 0.6;
  float f = ff*exp(-2.0*od);

  col *= f;
  col += 0.5*ff*sqrt(scol);
  col -= (1.0-tanh_approx(10.0*-qch))*f;
  col *= smoothstep(0.0, 0.025, od);
  return col;
}

void compute_globals() {

  vec2 vx = vec2(0.0, 0.0);
  vec2 vy = vec2(3.2, 1.3);

  vec2 wx = vec2(1.7, 9.2);
  vec2 wy = vec2(8.3, 2.8);

  vx *= ROT(TTIME/1000.0);
  vy *= ROT(TTIME/900.0);

  wx *= ROT(TTIME/800.0);
  wy *= ROT(TTIME/700.0);
  
  g_psy_vx = vx;
  g_psy_vy = vy;
  
  g_psy_wx = wx;
  g_psy_wy = wy;
}

vec3 color(vec2 p) {
  compute_globals();
  
  float aa = 2.0/RESOLUTION.y;
  float od = outer(p);


  vec3 ro = vec3(0.0, 10.0, 0.0);
  vec3 pp = vec3(p.x, 0.0, p.y);

  vec3 po = vec3(p.x, 0.0, p.y);
  vec3 rd = normalize(po-ro);


  vec3 col = od > 0.0 ? skinColor(p, ro, rd, po, od) : eyeColor(p, ro, rd, po, od); 
  
  return col;
}

vec3 postProcess(vec3 col, vec2 q) {
  col = clamp(col, 0.0, 1.0);
  col = pow(col, 1.0/vec3(2.2));
  col = col*0.6+0.4*col*col*(3.0-2.0*col);
  col = mix(col, vec3(dot(col, vec3(0.33))), -0.4);
  col *=0.5+0.5*pow(19.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7);
  return col;
}

void main() {
  vec2 q = gl_FragCoord.xy/RESOLUTION.xy;
  vec2 p = -1. + 2. * q;
  p.x *= RESOLUTION.x/RESOLUTION.y;
  float a = PCOS(TTIME/60.0);
  p *= mix(0.8, 1.2, 1.0-a);
  vec3 col = color(p);

  col = postProcess(col, q);
  fragColor = vec4(col, 1.0);
}
