// License CC0: A battered alien planet
//  Been experimenting with space inspired shaders
// https://www.shadertoy.com/view/wsjBD3
// https://www.shadertoy.com/view/WsjfDt

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

#define PI  3.141592654
#define TAU (2.0*PI)

#define TOLERANCE       0.00001
#define MAX_ITER        65
#define MIN_DISTANCE    0.11
#define MAX_DISTANCE    4.0

const vec3  skyCol1       = vec3(0.35, 0.45, 0.6);
const vec3  skyCol2       = vec3(0.0);
const vec3  skyCol3       = pow(skyCol1, vec3(0.25));
const vec3  sunCol1       = vec3(1.0,0.6,0.4);
const vec3  sunCol2       = vec3(1.0,0.9,0.7);
const vec3  smallSunCol1  = vec3(1.0,0.5,0.25)*0.5;
const vec3  smallSunCol2  = vec3(1.0,0.5,0.25)*0.5;
const vec3  mountainColor = sqrt(vec3(0.95, 0.65, 0.45));
const vec4  planet        = vec4(80.0, -20.0, 100.0, 50.0)*1000.0;
const vec3  ringsNormal   = normalize(vec3(1.0, 1.25, 0.0));
const vec4  rings         = vec4(ringsNormal, -dot(ringsNormal, planet.xyz));

void rot(inout vec2 p, float a) {
  float c = cos(a);
  float s = sin(a);
  p = vec2(p.x*c + p.y*s, -p.x*s + p.y*c);
}

vec2 mod2(inout vec2 p, vec2 size) {
  vec2 c = floor((p + size*0.5)/size);
  p = mod(p + size*0.5,size) - size*0.5;
  return c;
}

vec2 mod2_1(inout vec2 p) {
  vec2 c = floor(p + 0.5);
  p = fract(p + 0.5) - 0.5;
  return c;
}

float circle(vec2 p, float r) {
  return length(p) - r;
}

float egg(vec2 p, float ra, float rb) {
  const float k = sqrt(3.0);
  p.x = abs(p.x);
  float r = ra - rb;
  return ((p.y<0.0)       ? length(vec2(p.x,  p.y    )) - r :
          (k*(p.x+r)<p.y) ? length(vec2(p.x,  p.y-k*r)) :
                              length(vec2(p.x+r,p.y    )) - 2.0*r) - rb;
}

vec2 hash(vec2 p) {
  p = vec2(dot (p, vec2 (127.1, 311.7)), dot (p, vec2 (269.5, 183.3)));
  return -1. + 2.*fract (sin (p)*43758.5453123);
}

float rayPlane(vec3 ro, vec3 rd, vec4 p) {
  return -(dot(ro,p.xyz)+p.w)/dot(rd,p.xyz);
}

vec2 raySphere(vec3 ro, vec3 rd, vec4 sphere) {
  vec3 center = sphere.xyz;
  float radius = sphere.w;
  vec3 m = ro - center.xyz;
  float b = dot(m, rd);
  float c = dot(m, m) - radius*radius;
  if(c > 0.0 && b > 0.0) return vec2(-1.0, -1.0);
  float discr = b * b - c;
  if(discr < 0.0) return vec2(-1.0);
  float normalMultiplier = 1.0;
  float s = sqrt(discr);
  float t0 = -b - s;
  float t1 = -b + s;;
  return vec2(t0, t1);
}

float noise1(vec2 p) {
  vec2 n = mod2_1(p);
  vec2 hh = hash(sqrt(2.0)*(n+1000.0));
  hh.x *= hh.y;

  const float r = 0.225;
 
  float d = circle(p, 2.0*r);

  float h = hh.x*smoothstep(0.0, r, -d);

  return h*0.25;
}

float noise2(vec2 p) {
  vec2 n = mod2_1(p);
  vec2 hh = hash(sqrt(2.0)*(n+1000.0));
  hh.x *= hh.y;

  rot(p, TAU*hh.y);
  const float r = 0.45;
 
//  float d = circle(p, 1.0*r);
  float d = egg(p, 0.75*r, 0.5*r*abs(hh.y));
  
  float h = -abs(hh.x)*(smoothstep(0.0, r, -2.0*d)-0.3*smoothstep(0.0, 0.2*r, -d));

  return h*0.275;
}


float height(vec2 p, float dd, int mx) {
  const float aa   = 0.45;
  const float ff   = 2.03;
  const float tt   = 1.2;
  const float oo   = 3.93;
  const float near = 0.25;
  const float far  = 0.65;

  float a = 1.0;
  float o = 0.2;
  float s = 0.075*sin(p.x+p.y);
  float d = 0.0;

  int i = 0;

  for (; i < 4;++i) {
    float nn = a*noise2(p);
    s += nn;
    d += abs(a);
    p += o;
    a *= aa;
    p *= ff;
    o *= oo;
    rot(p, tt);
  }

  float lod = s/d;

  float rdd = dd/MAX_DISTANCE;
  mx = int(mix(float(4), float(mx), step(rdd, far)));

  for (; i < mx; ++i) {
    float nn = a*noise1(p);
    s += nn;
    d += abs(a);
    p += o;
    a *= aa;
    p *= ff;
    o *= oo;
    rot(p, tt);
  }

  float hid = (s/d);

  return mix(hid, lod, smoothstep(near, far, rdd));
}

float loheight(vec2 p, float d) {
  return height(p, d, 0);
}

float height(vec2 p, float d) {
  return height(p, d, 6);
}

float hiheight(vec2 p, float d) {
  return height(p, d, 8);
}

vec3 normal(vec2 p, float d) {
  vec2 eps = vec2(0.00125, 0.0);

  vec3 n;

  n.x = (hiheight(p - eps.xy, d) - hiheight(p + eps.xy, d));
  n.y = 2.0*eps.x;
  n.z = (hiheight(p - eps.yx, d) - hiheight(p + eps.yx, d));

  return normalize(n);
}

const float stepLength[] = float[](0.9, 0.25);


float march(vec3 ro, vec3 rd, float id, out int max_iter) {
  float dt = 0.1;
  float d = id;
  int currentStep = 0;
  float lastd = d;
  for (int i = 0; i < MAX_ITER; ++i)
  {
    vec3 p = ro + d*rd;
    float h = height(p.xz, d);

    if (d > MAX_DISTANCE) {
      max_iter = i;
      return MAX_DISTANCE;
    }

    float hd = p.y - h;

    if (hd < TOLERANCE) {
      ++currentStep;
      if (currentStep >= stepLength.length()) {
        max_iter = i;
        return d;
      }

      d = lastd;
      continue;
    }

    float sl = stepLength[currentStep];

    dt = max(hd, TOLERANCE)*sl + 0.0025*d;
    lastd = d;
    d += dt;
  }

  max_iter = MAX_ITER;
  return MAX_DISTANCE;
}

vec3 sunDirection() {
  return normalize(vec3(-0.5, 0.085, 1.0));
}

vec3 smallSunDirection() {
  return normalize(vec3(-0.2, -0.05, 1.0));
}

vec3 rocketDirection() {
  return normalize(vec3(0.0, -0.2+mod(iTime, 90.0)*0.0125, 1.0));
}

float psin(float f) {
  return 0.5 + 0.5*sin(f);
}

vec3 skyColor(vec3 ro, vec3 rd) {
  vec3 sunDir = sunDirection();
  vec3 smallSunDir = smallSunDirection();

  float sunDot = max(dot(rd, sunDir), 0.0);
  float smallSunDot = max(dot(rd, smallSunDir), 0.0);

  float angle = atan(rd.y, length(rd.xz))*2.0/PI;

  vec3 skyCol = mix(mix(skyCol1, skyCol2, smoothstep(0.0 , 1.0, 5.0*angle)), skyCol3, smoothstep(0.0, 1.0, -5.0*angle));

  vec3 sunCol = 0.5*sunCol1*pow(sunDot, 20.0) + 8.0*sunCol2*pow(sunDot, 2000.0);
  vec3 smallSunCol = 0.5*smallSunCol1*pow(smallSunDot, 200.0) + 8.0*smallSunCol2*pow(smallSunDot, 20000.0);

  vec3 dust = pow(sunCol2*mountainColor, vec3(1.75))*smoothstep(0.05, -0.1, rd.y)*0.5;

  vec2 si = raySphere(ro, rd, planet);
  float pi = rayPlane(ro, rd, rings);

  float dustTransparency = smoothstep(-0.075, 0.0, rd.y);

  vec3 planetSurface = ro + si.x*rd;
  vec3 planetNormal = normalize(planetSurface - planet.xyz);
  float planetDiff = max(dot(planetNormal, sunDir), 0.0);
  float planetBorder = max(dot(planetNormal, -rd), 0.0);
  float planetLat = (planetSurface.x+planetSurface.y)*0.0005;
  vec3 planetCol = mix(1.3*vec3(0.9, 0.8, 0.7), 0.3*vec3(0.9, 0.8, 0.7), pow(psin(planetLat+1.0)*psin(sqrt(2.0)*planetLat+2.0)*psin(sqrt(3.5)*planetLat+3.0), 0.5));

  vec3 ringsSurface = ro + pi*rd;

  vec3 rocketDir = rocketDirection();
  float rocketDot = max(dot(rd, rocketDir), 0.0);
  float rocketDot2 = max(dot(normalize(rd.xz), normalize(rocketDir.xz)), 0.0);
  vec3 rocketCol = vec3(0.25)*(3.0*smoothstep(-1.0, 1.0, psin(iTime*15.0*TAU))*pow(rocketDot, 70000.0) + smoothstep(-0.25, 0.0, rd.y - rocketDir.y)*step(rd.y, rocketDir.y)*pow(rocketDot2, 1000000.0))*dustTransparency;

  float borderTransparency = smoothstep(0.0, 0.1, planetBorder);

  float ringsDist = length(ringsSurface - planet.xyz)*1.0;
  float ringsPeriod = ringsDist*0.001;
  const float ringsMax = 150000.0*0.655;
  const float ringsMin = 100000.0*0.666;
  float ringsMul = pow(psin(ringsPeriod+1.0)*psin(sqrt(0.5)*ringsPeriod+2.0)*psin(sqrt(0.45)*ringsPeriod+4.0)*psin(sqrt(0.35)*ringsPeriod+5.0), 0.25);
  float ringsMix = psin(ringsPeriod*10.0)*psin(ringsPeriod*10.0*sqrt(2.0))*(1.0 - smoothstep(50000.0, 200000.0, pi));
//  float ringsDiff = max(-dot(rings.xyz, sunDir), 0.0);

  vec3 ringsCol = mix(vec3(0.125), 0.75*mountainColor, ringsMix)*step(-pi, 0.0)*step(ringsDist, ringsMax)*step(-ringsDist, -ringsMin)*ringsMul;

  vec3 final = vec3(0.0);

  final += ringsCol*(step(pi, si.x) + step(si.x, 0.0));

  final += step(0.0, si.x)*pow(planetDiff, 0.75)*mix(planetCol, ringsCol, 0.0)*dustTransparency*borderTransparency + ringsCol*(1.0 - borderTransparency);

  final += skyCol + sunCol + smallSunCol + dust + rocketCol;

  return final;
}

vec3 getColor(vec3 ro, vec3 rd) {
  int max_iter = 0;
  vec3 skyCol = skyColor(ro, rd);
  vec3 col = vec3(0);

  float id = (0.125 - ro.y)/rd.y;

  if (id > 0.0)   {
    float d = march(ro, rd, id, max_iter);
    vec3 sunDir = sunDirection();
    vec3 osunDir = sunDir*vec3(-1.0, .0, -1.0);
    vec3 p = ro + d*rd;

    vec3 normal = normal(p.xz, d);

    float amb = 0.2;

    float dif1 = max(0.0, dot(sunDir, normal));
    vec3 shd1 = sunCol2*mix(amb, 1.0, pow(dif1, 0.75));

    float dif2 = max(0.0, dot(osunDir, normal));
    vec3 shd2 = sunCol1*mix(amb, 1.0, pow(dif2, 0.75));

    vec3 ref = reflect(rd, normal);
    vec3 rcol = skyColor(p, ref);

    col = mountainColor*amb*skyCol3;
    col += mix(shd1, shd2, -0.5)*mountainColor;   
    float fre = max(dot(normal, -rd), 0.0);
    fre = pow(1.0 - fre, 5.0);
    col += rcol*fre*0.5;
    col += (1.0*p.y);
    col = tanh(col);
    col = mix(col, skyCol, smoothstep(0.5*MAX_DISTANCE, 1.*MAX_DISTANCE, d));

  } else {
    col = skyCol;
  }
//  col += vec3(1.1, 0.0, 0.0)* smoothstep(0.25, 1.0,(float(max_iter)/float(MAX_ITER)));
  return col;
}

vec3 getSample1(vec2 p, float time) {
  float off = 0.5*iTime;

  vec3 ro  = vec3(0.5, 1.0-0.25, -2.0 + off);
  vec3 la  = ro + vec3(0.0, -0.00,  2.0);

  vec3 ww = normalize(la - ro);
  vec3 uu = normalize(cross(vec3(0.0,1.0,0.0), ww));
  vec3 vv = normalize(cross(ww, uu));
  vec3 rd = normalize(p.x*uu + p.y*vv + 2.0*ww);

  vec3 col = getColor(ro, rd)  ;

  return col;

}

vec3 getSample2(vec2 p, float time) {
  p.y-=time*0.25;
  float h = height(p, 0.0);
  vec3 n = normal(p, 0.0);

  vec3 lp = vec3(10.0, -1.2, 0.0);

  vec3 ld = normalize(vec3(p.x, h, p.y)- lp);

  float d = max(dot(ld, n), 0.0);

  vec3 col = vec3(0.0);

  col = vec3(1.0)*(h+0.1);
  col += vec3(1.5)*pow(d, 0.75);

  return col;

}

void main() {
  vec2 q = gl_FragCoord.xy/iResolution.xy;
  vec2 p = -1.0 + 2.0*q;
  p.x *= iResolution.x/iResolution.y;

  vec3 col = getSample1(p, iTime);

  fragColor = vec4(col, 1.0);
}
