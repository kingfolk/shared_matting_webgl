#ifdef GL_ES
precision mediump float;
#endif

uniform sampler2D state;
uniform vec2 scale;
uniform vec2 offset;


void main() {
    if (gl_FragCoord.y < offset.y || gl_FragCoord.x < offset.x
      || gl_FragCoord.y > scale.y - offset.y || gl_FragCoord.x > scale.x - offset.x) {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
    }
    else {
        vec2 coord = vec2((gl_FragCoord.x - offset.x)/(scale.x - 2.0*offset.x),
          1.0 - (gl_FragCoord.y - offset.y)/(scale.y - 2.0*offset.y));
        gl_FragColor = texture2D(state, coord);
    }
}
