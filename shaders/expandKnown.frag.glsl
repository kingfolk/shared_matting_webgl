#ifdef GL_ES
precision mediump float;
#endif

uniform sampler2D oriState;
uniform sampler2D triState;
uniform vec2 scale;
uniform float kC;

vec3 getOri() {
  vec4 color = texture2D(oriState, (gl_FragCoord.xy) / scale);
  return color.xyz;
}

vec3 getOri(vec2 coord) {
  vec4 color = texture2D(oriState, coord);
  return color.xyz;
}

vec3 getTri() {
  vec4 color = texture2D(triState, (gl_FragCoord.xy) / scale);
  return color.xyz;
}

vec4 getTri(vec2 coord) {
  return texture2D(triState, coord);
}

void main() {
  float tri = getTri().x;
  gl_FragColor = texture2D(triState, (gl_FragCoord.xy) / scale);

  // unknown region
  if (tri > 0.0 && tri < 1.0) {
    float x = gl_FragCoord.x,
      y = gl_FragCoord.y;

    const float kI = float( %%kI%% );

    vec3 curColor = getOri();
    for (float i = -kI; i < kI; i += 1.0) {
      for (float j = -kI; j < kI; j += 1.0) {
        float w = gl_FragCoord.x + i;
        float h = gl_FragCoord.y + j;
        if (w > 0.0 && w < scale.x
          && h > 0.0 && h < scale.y) {
            vec2 coord = vec2(w, h);
            vec3 color = getOri(coord / scale);
            vec4 triColor = getTri(coord / scale);
            if ((triColor.x == 0.0 || triColor.x == 1.0)
              && distance(coord, gl_FragCoord.xy) < kI
              && distance(color, curColor) < kC) {
                gl_FragColor = triColor;
              }
            }
      }
    }
  }

}
