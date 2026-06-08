precision mediump float;

varying vec2 v_texcoord;
uniform sampler2D tex;

const float vibrance = 0.75;

void main() {
    vec4 color = texture2D(tex, v_texcoord);

    float average = (color.r + color.g + color.b) / 3.0;
    vec3 diff = color.rgb - vec3(average);

    color.rgb += diff * vibrance;

    gl_FragColor = color;
}
