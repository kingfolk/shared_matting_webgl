#extension GL_EXT_draw_buffers : require
#ifdef GL_ES
precision mediump float;
#endif

#define i0_  0
#define i1_  1
#define i2_  2
#define i3_  3

uniform sampler2D oriState;
uniform sampler2D triState;
uniform int isTest;
uniform vec2 scale;
uniform int kG;

vec2 FSamples[%%kG%%];
vec2 BSamples[%%kG%%];

struct FBPair {
  vec3 F;
  vec3 B;
  vec2 FCoord;
  vec2 BCoord;
};

vec2 arrIdx(int which, int idx) {
  vec2 res;
  if (which == 0) {
    if (idx == 0) { res = FSamples[i0_]; }
    else if (idx == 1) { res = FSamples[i1_]; }
    else if (idx == 2) { res = FSamples[i2_]; }
    else if (idx == 3) { res = FSamples[i3_]; }
  }
  else if (which == 1) {
    if (idx == 0) { res = BSamples[i0_]; }
    else if (idx == 1) { res = BSamples[i1_]; }
    else if (idx == 2) { res = BSamples[i2_]; }
    else if (idx == 3) { res = BSamples[i3_]; }
  }

  return res;
}

void arrIdx(int which, int idx, vec2 value) {
  if (which == 0) {
    if (idx == 0) { FSamples[i0_] = value; }
    else if (idx == 1) { FSamples[i1_] = value; }
    else if (idx == 2) { FSamples[i2_] = value; }
    else if (idx == 3) { FSamples[i3_] = value; }
  }
  else if (which == 1) {
    if (idx == 0) { BSamples[i0_] = value; }
    else if (idx == 1) { BSamples[i1_] = value; }
    else if (idx == 2) { BSamples[i2_] = value; }
    else if (idx == 3) { BSamples[i3_] = value; }
  }
}

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

void sample() {
  int fIdx = 0, bIdx = 0;
  float x = gl_FragCoord.x,
    y = gl_FragCoord.y;

  float inc = 360.0 / float(kG);
  float ca = inc / 9.0;
  float angle = (x + y) * ca;
  for (int k = 0; k < %%kG%%; k ++) {
    bool flagF = false;
    bool flagB = false;

    float z  = (angle + float(k) * inc) / 180.0 * 3.1415926;
    float ex = sin(z);
    float ey = cos(z);
    float step = min(1.0 / (abs(ex) + 1e-10), 1.0 / (abs(ey) + 1e-10));

    for (int i = 0; i < %%searchRange%%; i ++) {
      float t = step * float(i);
      float tx = x + ex * t,
        ty = y + ey * t;

      if (tx > 0.0 && tx < scale.x
        && ty > 0.0 && ty < scale.y
        && (!flagF || !flagB) ) {
          vec2 coord = vec2(tx, ty) / scale;
          float triColor = getTri(coord).x;
          if (!flagF && triColor == 1.0) {
            arrIdx(0, fIdx++, coord);
            flagF = true;
          }
          else if (!flagB && triColor == 0.0) {
            arrIdx(1, bIdx++, coord);
            flagB = true;
          }
        }
    }
  }
  for (int i = 0; i < %%kG%%; i ++) {
    if (i >= fIdx) {
      arrIdx(0, i, vec2(-1.0, -1.0));
      // arrIdx(0, i, gl_FragCoord.xy / scale);
    }
  }
  for (int i = 0; i < %%kG%%; i ++) {
    if (i >= bIdx) {
      arrIdx(1, i, vec2(-1.0, -1.0));
      // arrIdx(1, i, gl_FragCoord.xy / scale);
    }
  }
  // FSamples[0] = gl_FragCoord.xy / scale;
  // arrIdx(0, 0, gl_FragCoord.xy / scale);
}


float e_p(vec2 coord) {
  float lx = coord.x * scale.x - gl_FragCoord.x,
    ly = coord.y * scale.y - gl_FragCoord.y,
    l = length(vec2(lx, ly));

  float ex = lx / (l + 1e-10),
    ey = ly / (l + 1e-10),
    step = min(1.0/(abs(ex) + 1e-10), 1.0/(abs(ey) + 1e-10)),
    res = 0.0;
  vec3 color = getOri();

  for (int i = 0; i < %%searchRange%%; i ++) {
    float t = step * float(i);
    if (t < l) {
      float x = gl_FragCoord.x + t * ex,
        y = gl_FragCoord.y + t * ey;
      vec2 coord = vec2(x, y) / scale;
      vec3 color_ = getOri(coord);
      float d = distance(color, color_);
      res += d * d;
    }
  }
  return res;
}

float pf_p() {
  float fMin = 1e10,
    bMin = 1e10;
  for (int i = 0; i < %%kG%%; i ++) {
    float f = e_p(arrIdx(0, i)),
      b = e_p(arrIdx(1, i));
    if (f < fMin) {
      fMin = f;
    }
    if (b < bMin) {
      bMin = b;
    }
  }

  return bMin / (fMin + bMin + 1e-10);
}

float estimAlpha(vec3 color, vec3 fColor, vec3 bColor) {
  float d = distance(fColor, bColor);
  return dot((color - bColor), (fColor - bColor)) / (d * d);
}

float a_p(vec2 FCoord, vec2 BCoord, float pfp) {
  vec3 color = getOri();
  float alpha = estimAlpha(color, getOri(FCoord), getOri(BCoord));

  return pfp + (1.0 - 2.0 * pfp) * alpha;
}

float d_p(vec2 coord) {
  return distance(gl_FragCoord.xy, coord);
}

float m_p(vec2 coord, vec2 FCoord, vec2 BCoord) {
  vec3 color = getOri(coord),
    fColor = getOri(FCoord),
    bColor = getOri(BCoord);
  float alpha = estimAlpha(color, fColor, bColor);
  return length(color - alpha * fColor - (1.0 - alpha) * bColor);
}

float n_p(vec2 FCoord, vec2 BCoord) {
  float res = 0.0;
  for (int i = -1; i < 2; i ++) {
    for (int j = -1; j < 2; j ++) {
      float m = m_p((gl_FragCoord.xy + vec2(float(i), float(j)))/scale, FCoord, BCoord);
      res += m * m;
    }
  }

  return res;
}

float g_p(vec2 FCoord, vec2 BCoord, float pfp) {
  float np = pow(n_p(FCoord, BCoord), 3.0),
    ap = pow(a_p(FCoord, BCoord, pfp), 2.0),
    dpf = d_p(FCoord),
    dpb = pow(d_p(BCoord), 4.0);

  return np * ap * dpf * dpb;
}

FBPair gathering() {
  float gpMin = 1.0e10;
  float pfp = pf_p();
  int idxI = 0, idxJ = 0;
  for (int i = 0; i < %%kG%%; i ++) {
    for (int j = 0; j < %%kG%%; j ++) {
      vec2 fs = arrIdx(0, i),
        bs = arrIdx(1, j);
      if (fs.x != -1.0 && bs.x != -1.0) {
        float gp = g_p(fs, bs, pfp);
        if (gp < gpMin) {
          gpMin = gp;
          idxI = i;
          idxJ = j;
        }
      }
    }
  }

  FBPair p;
  p.FCoord = arrIdx(0,idxI); p.BCoord = arrIdx(1,idxJ);
  p.F = getOri(p.FCoord); p.B = getOri(p.BCoord);

  return p;
}

void testAlpha() {
  if (getTri().x > 0.0 && getTri().x < 1.0) {
    sample();
    FBPair p = gathering();
    float alpha = estimAlpha(getOri(), p.F, p.B);
    // float alpha = estimAlpha(getOri(), getOri(FSamples[3]), getOri(BSamples[3]));
    gl_FragColor = vec4(alpha, alpha, alpha, 1.0);
    // gl_FragData[0] = vec4(p.F, 1.0);
    // gl_FragColor = vec4(alpha, alpha, alpha, 1.0);
  }
  else {
    gl_FragColor = vec4(getTri(), 1.0);
    // gl_FragData[0] = vec4(0.0, 0.0, 0.0, 1.0);
    // gl_FragColor = vec4(getTri(), 1.0);
  }
}

void writeFB() {
  if (getTri().x > 0.0 && getTri().x < 1.0) {
    vec2 FSamples[%%kG%%];
    vec2 BSamples[%%kG%%];
    sample();
    FBPair p = gathering();
    // F B component
    gl_FragColor = vec4(p.FCoord, p.BCoord);
  }
  else {
    gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
  }
}

void main() {
  if (isTest == 0) {
    writeFB();
  }
  else {
    testAlpha();
  }
}
