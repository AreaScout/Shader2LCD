uniform vec2 resolution;
out vec4 fragColor;

void main(void) {
  fragColor[0] = gl_FragCoord.x / resolution.x;
  fragColor[1] = gl_FragCoord.y / resolution.y;
  fragColor[2] = 0.5;
  fragColor[3] = 1.0;
}
