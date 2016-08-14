#ifdef GL_ES
precision mediump float;
#endif

uniform sampler2D oriState;
uniform sampler2D triState;
uniform sampler2D foreState;
uniform sampler2D backState;
uniform sampler2D acState;
uniform vec2 scale;

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

vec3 getTri(vec2 coord) {
  return texture2D(triState, coord).xyz;
}

float getAlpha(vec2 coord) {
  return texture2D(acState, coord).x;
}

float getConfidence(vec2 coord) {
  return texture2D(acState, coord).y;
}

vec3 getFore(vec2 coord) {
  return texture2D(foreState, coord).xyz;
}

vec3 getBack(vec2 coord) {
  return texture2D(backState, coord).xyz;
}

float estimAlpha(vec3 color, vec3 fColor, vec3 bColor) {
  float d = distance(fColor, bColor);
  return dot((color - bColor), (fColor - bColor)) / (d * d);
}

float m_p(vec2 coord, vec3 fColor, vec3 bColor) {
  vec3 color = getOri(coord);
  float alpha = estimAlpha(color, fColor, bColor);
  return length(color - alpha * fColor - (1.0 - alpha) * bColor);
}

float smooth() {
  float sigma2 = 100.0 / (9.0 * 3.1415926);
  vec3 accumWcUpF = vec3(0.0, 0.0, 0.0), accumWcUpB = vec3(0.0, 0.0, 0.0);
  float accumWcDownF = 0.0, accumWcDownB = 0.0;
  float accumWfbUp = 0.0, accumWfbDown = 0.0;
  float confidence00 = getConfidence(gl_FragCoord.xy / scale);
  float alpha00 = getAlpha(gl_FragCoord.xy / scale);
  float accumWaUp = 0.0, accumWaDown = 0.0;
  for (int i = -10; i < 11; i ++) {
    for (int j = -10; j < 11; j ++) {
      vec2 offset = vec2(float(i), float(j));
      vec2 coord = (gl_FragCoord.xy + offset) / scale;
      float d = distance(offset, vec2(0.0, 0.0));
      if (coord.x > 0.0 && coord.x < 1.0
          && coord.y > 0.0 && coord.y < 1.0
          && d <= 3.0 * sigma2) {
        // aqr
        float alpha = getAlpha(coord),
        // fqr
          confidence = getConfidence(coord);
        float g = exp(- d*d / 2.0 / sigma2);
        float wc = 0.0;
        if (i == 0 && j == 0) {
          wc = g * confidence;
        }
        else {
          wc = g * confidence * abs(alpha - alpha00);
        }
        vec3 foreColor = getFore(coord),
          backColor = getBack(coord);
        float wca = wc * alpha;
        accumWcUpF += wca * foreColor;
        accumWcUpB += (wc - wca) * backColor;
        accumWcDownF += wc * alpha;
        accumWcDownB += wc - wca;

        float wfbq = confidence * alpha * (1.0 - alpha);
        accumWfbUp += wfbq * distance(foreColor, backColor);
        accumWfbDown += wfbq;

        float theta = 0.0;
        if (getTri(coord).x == 0.0 || getTri(coord).x == 1.0) {
          theta = 1.0;
        }
        float wa = confidence * g + theta;
        accumWaUp += wa * alpha;
        accumWaDown += wa;
      }
    }
  }
  vec3 fp = accumWcUpF / (accumWcDownF + 1e-10),
    bp = accumWcUpB / (accumWcDownB + 1e-10);
  float dfb = accumWfbUp / (accumWfbDown + 1e-10);
  float confidenceP = min(1.0, distance(fp, bp) / dfb) * exp(-10.0 * m_p(gl_FragCoord.xy/scale, fp, bp));
  float alphaP = accumWaUp / (accumWaDown + 1e-10);
  alphaP = max(0.0, min(1.0, alphaP));
  float alphaFinal = confidenceP * estimAlpha(getOri(), fp, bp) + (1.0 - confidenceP) * alphaP;

  return alphaFinal;
}

void getAlpha() {
  if (getTri().x == 0.0 || getTri().x == 1.0) {
    gl_FragColor = vec4(getTri(), 1.0);
  }
  else {
    float alpha = smooth();
    gl_FragColor = vec4(alpha, alpha, alpha, 1.0);
    // gl_FragColor = vec4(getBack(gl_FragCoord.xy / scale), 1.0);
  }
  // gl_FragColor = vec4(getBack(gl_FragCoord.xy / scale), 1.0);
}

void main() {
  getAlpha();
}
