#version 330

uniform sampler2DRect audioTex;
uniform vec2 audioTexSize;

uniform float time;

uniform float rms;
uniform float rmsDelta;
uniform float rmsDeltaCumul;
uniform float rmsCumul;

uniform float slider00;
uniform float slider01;
uniform float slider02;
uniform float slider03;
uniform float slider04;
uniform float slider05;
uniform float slider06;
uniform float slider07;
uniform float knob00;
uniform float knob01;
uniform float knob02;
uniform float knob03;
uniform float knob04;
uniform float knob05;
uniform float knob06;
uniform float knob07;

uniform vec2 resolution;

in vec2 uv;
out vec4 outColor;

mat4 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

vec3 hsv2rgb( in vec3 c ){
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z * mix( vec3(1.0), rgb, c.y);
}

vec3 rgb2hsv(vec3 c){
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 0.000000000001;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 modColor(vec3 rgb, float adj) {
    vec3 c = rgb2hsv(rgb);
    c.x += adj;
    c = mod(c, vec3(1.0));
    return hsv2rgb(c);
}

void main()
{
    vec2 uv2 = uv;
    uv2.y = (uv2.y - 0.5) / (resolution.x / resolution.y) + 0.5;

    mat4 rot = rotationMatrix(vec3(0,0,1), sin(rmsCumul / 100.0) / 5.0);
    vec2 uv3 = (rot * vec4(uv2 - vec2(1.0, 0.5), 0.0, 0.0)).xy + vec2(1.0, 0.5);
    uv3 += vec2(sqrt(rms) / 2.0 - 0.2);

    float gridSize = 100.0 + 300.0 * slider04;

    float distFromGrid = length(vec2(sin(uv3.x * gridSize), cos(uv3.y * gridSize)));
    float distFromGridStp = smoothstep(rms + 0.5 + slider03, (rms+0.1)*1.0, distFromGrid);

    float audioVal = texture(audioTex, vec2(pow(uv3.x, 2.0) * audioTexSize.x, 0)).r;
    float audioValAmt = audioVal + knob03;
    float audioHeight = rms * 1.0;
    float audioHeightAmt = (pow(1.0 - abs(0.5 - uv3.y), 10.0 * (1.0-0.8*knob04)) * audioHeight);
//    float sqAudioVal = texture(audioTex, vec2(sin(distFromCenter) * audioTexSize.x, 0)).r;
//
//    vec3 grad1, grad2, grad3;
//    float rand1 = snoise(vec3(uv2.x, uv2.y, (rmsCumul / 100.0) + rms / 30.0) * 3.0, grad1) * 3.0;
//    float rand2 = snoise(vec3(uv2.x, uv2.y, rmsCumul / 300.0 + 50) * 3.0, grad2) * 5.0;
//    float rand3 = snoise(vec3(uv2.x, uv2.y, rmsCumul / 500.0 + 100) * 3.0, grad3) * 5.0;
//    float stepped1 = smoothstep(0.25 * distFromCenter, max(rms, 0.3) * distFromCenter, rand1);
//    float stepped2 = smoothstep(0.75, max(rms, 0.8), rand2);
//    float stepped3 = smoothstep(0.75, max(rms, 0.8), rand3);

    vec3 color1 = modColor(vec3(181, 248, 54) / 255.0, slider00);
    vec3 color2 = modColor( vec3(47, 218, 200) / 255.0, slider01);
    vec3 color3 = modColor(vec3(93, 72, 225) / 255.0, slider02);
//
    vec3 color1Amt = distFromGridStp * color1;// * min(rms + 0.5, 1.0);
//    vec3 color2Amt = stepped2 * color2;
//    vec3 color3Amt = stepped3 * color3;
//
//    float audioFac1 = smoothstep(0.5, 1.0, min(pow(audioVal, 0.5), 1.0));
//    float audioFac2 = 0;min(pow(audioVal, 0.) + 0.1, 1.0);
//    float audioFac3 = min(rms, 1.0);
//    float audioFac = min(audioFac1 + audioFac2 + audioFac3, 1.0);
//
    vec3 out3 = color1Amt * min(audioValAmt * audioHeightAmt, 0.3) *5.0;
    outColor = vec4(out3, 1.0);
}
