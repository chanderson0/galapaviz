#version 330

uniform sampler2DRect audioTex;
uniform vec2 audioTexSize;

uniform float time;

uniform float rms;
uniform float rmsDelta;
uniform float rmsDeltaCumul;
uniform float rmsCumul;

uniform vec2 resolution;

in vec2 uv;
out vec4 outColor;
//
//mat4 rotationMatrix(vec3 axis, float angle)
//{
//    axis = normalize(axis);
//    float s = sin(angle);
//    float c = cos(angle);
//    float oc = 1.0 - c;
//
//    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
//                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
//                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
//                0.0,                                0.0,                                0.0,                                1.0);
//}
//
//void main()
//{
//    vec2 uv2 = uv;
//    uv2.y = (uv2.y - 0.5) / (resolution.x / resolution.y) + 0.5;
//
//    mat4 rot = rotationMatrix(vec3(0,0,1), sin(rmsCumul / 100.0) / 5.0);
//    vec2 uv3 = (rot * vec4(uv2 - vec2(1.0, 0.5), 0.0, 0.0)).xy + vec2(1.0, 0.5);
//    uv3 += vec2(rms / 2.0 - 0.2);
//
//    const float gridSize = 300.0;
//
//    float distFromGrid = length(vec2(sin(uv3.x * gridSize), cos(uv3.y * gridSize)));
//    float distFromGridStp = smoothstep(rms + 0.5, (rms+0.1)*1.0, distFromGrid);
//
//    float audioVal = texture(audioTex, vec2(pow(uv3.x, 2.0) * audioTexSize.x, 0)).r;
//    float audioValAmt = audioVal + 0.3;
//    float audioHeight = rms;
//    float audioHeightAmt = (pow(1.0 - abs(0.5 - uv3.y), 10.0) * audioHeight);
//    //    float sqAudioVal = texture(audioTex, vec2(sin(distFromCenter) * audioTexSize.x, 0)).r;
//    //
//    //    vec3 grad1, grad2, grad3;
//    //    float rand1 = snoise(vec3(uv2.x, uv2.y, (rmsCumul / 100.0) + rms / 30.0) * 3.0, grad1) * 3.0;
//    //    float rand2 = snoise(vec3(uv2.x, uv2.y, rmsCumul / 300.0 + 50) * 3.0, grad2) * 5.0;
//    //    float rand3 = snoise(vec3(uv2.x, uv2.y, rmsCumul / 500.0 + 100) * 3.0, grad3) * 5.0;
//    //    float stepped1 = smoothstep(0.25 * distFromCenter, max(rms, 0.3) * distFromCenter, rand1);
//    //    float stepped2 = smoothstep(0.75, max(rms, 0.8), rand2);
//    //    float stepped3 = smoothstep(0.75, max(rms, 0.8), rand3);
//
//    vec3 color1 = vec3(255, 255, 255) / 255.0;
//    vec3 color2 = vec3(47, 218, 200) / 255.0;
//    vec3 color3 = vec3(93, 72, 225) / 255.0;
//    //
//    vec3 color1Amt = distFromGridStp * color1;// * min(rms + 0.5, 1.0);
//    //    vec3 color2Amt = stepped2 * color2;
//    //    vec3 color3Amt = stepped3 * color3;
//    //
//    //    float audioFac1 = smoothstep(0.5, 1.0, min(pow(audioVal, 0.5), 1.0));
//    //    float audioFac2 = 0;min(pow(audioVal, 0.) + 0.1, 1.0);
//    //    float audioFac3 = min(rms, 1.0);
//    //    float audioFac = min(audioFac1 + audioFac2 + audioFac3, 1.0);
//    //
//    vec3 out3 = color1Amt * min(audioValAmt * audioHeightAmt, 0.3) *5.0;
//    outColor = vec4(out3, 1.0);
//}

//#version 120
//
//#ifdef GL_ES
//precision mediump float;
//#endif

#define M_PI 3.1415926535897932384626433832795
#define XY_SCALE 5.0
#define TIME_SCALE 50.
#define TIME_SCALE_INT 50

//uniform float time;
//uniform vec2 resolution;

// From http://byteblacksmith.com/improvements-to-the-canonical-one-liner-glsl-rand-for-opengl-es-2-0/
float rand(vec2 co) {
    float a = 12.9898;
    float b = 78.233;
    float c = 43758.5453;
    float dt= dot(co.xy ,vec2(a,b));
    float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}

vec3 random3(int seed) {
    return vec3(
                rand(vec2(float(seed + 383), float(seed + 389))),
                rand(vec2(float(seed + 397), float(seed + 401))),
                rand(vec2(float(seed + 409), float(seed + 419)))
                );
}

vec2 random2(int seed) {
    return vec2(
                rand(vec2(float(seed + 383), float(seed + 389))),
                rand(vec2(float(seed + 397), float(seed + 401)))
                );
}

float random1(int seed) {
    return rand(vec2(float(seed + 383), float(seed + 389)));
}

// // https://gist.github.com/patriciogonzalezvivo/114c1653de9e3da6e1e3
vec3 rgb2hsv(vec3 c){
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 0.000000000001;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb( in vec3 c ){
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z * mix( vec3(1.0), rgb, c.y);
}

float lineDist(vec2 v, vec2 w, vec2 p) {
    float d1 = distance(p, v);
    float d2 = distance(p, w);
    float dt = distance(v, w);

    return d1 + d2 - dt;
}

float nearZero(float val, float nearness) {
    return smoothstep(-nearness, 0., -val) * smoothstep(-nearness, 0., val);
}

vec3 genColor(float t, float tScale, float mixAmt) {
    int period = int(floor(t / tScale));
    int seed = period * 7793;
    int nextSeed = (period+ 1) * 7793;

    vec3 color = vec3(0.);
    vec3 c1 = random3(seed);
    vec3 c2 = random3(nextSeed);
    vec3 c = mix(c1, c2, mixAmt);
    c = rgb2hsv(c);
    c.g = 1.0; c.b = 1.0;
    c = hsv2rgb(c);

    return c;
}

void main() {
    vec2 pos = gl_FragCoord.xy;
    vec2 center = resolution * 0.5;
    vec2 centerDiff = (pos - center) / 30.;
    //float th = atan(centerDiff.y, centerDiff.x);

    // Map onto (-XY_SCALE, XY_SCALE)
    vec2 uv = XY_SCALE * 2.0 * pos / resolution - vec2(XY_SCALE, XY_SCALE);

    float myTime = time / 5.0 + rmsCumul / 100.0;

    float t2 = mod((myTime / (TIME_SCALE / 50.)), 1.);
    float t4 = mod((myTime / TIME_SCALE), 1.);
    float t3 = smoothstep(0., 0.5, t4) - smoothstep(0.5, 1., t4);

    int period = int(floor(myTime / TIME_SCALE * 100.));
    int seed = period * 7793;
    int nextSeed = (period+ 1) * 7793;

    vec3 c = genColor(myTime, TIME_SCALE / 50.0, t2);//abs(rmsDelta));

    float A = 10.0 + rms * 2.0, B = 8.0 + rms * 2.0;
    float a = 10.0, b = 5.0 * (1.0 - t3 / 1.5);
    float delta = 0.0 + myTime; //M_PI / 2.0;

    float minDist = 100.0;
    for (int i = 0; i < 100; ++i) {
        float t0 = float(i) / 10.0;
        float t1 = float(i+1) / 10.0;

        float x0 = A * sin(a * t0 + delta);
        float y0 = B * sin(b * t0);

        float x1 = A * sin(a * t0 + delta);
        float y1 = B * sin(b * t1);

        float texVal = texture(audioTex, vec2(pow(float(i) / 100.0, 2.0) * audioTexSize.x, 0)).r;
        float audioVal = pow(rms, 1.0) * pow(texVal, 0.8);

        float dist = lineDist(vec2(x0, y0), vec2(x1, y1), centerDiff);
        dist -= audioVal;
        minDist = min(dist, minDist);
    }

    vec3 color = mix(
                vec3(0),
                c,
                nearZero(
                         minDist,
                         0.2
                         )
                );
    
    outColor = vec4(color, 1.);
}
