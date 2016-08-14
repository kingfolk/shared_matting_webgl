#ifdef GL_ES
precision mediump float;
#endif

uniform sampler2D state;
uniform vec2 scale;


void main() {
    vec2 coord = vec2(gl_FragCoord.x/scale.x, 1.0 - gl_FragCoord.y/scale.y);
    gl_FragColor = texture2D(state, coord);
}
