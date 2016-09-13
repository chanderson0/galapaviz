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

vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289(vec4 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
    return mod289(((x*34.0)+1.0)*x);
}

vec4 taylorInvSqrt(vec4 r)
{
    return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(vec3 v, out vec3 gradient)
{
    const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
    const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

    // First corner
    vec3 i  = floor(v + dot(v, C.yyy) );
    vec3 x0 =   v - i + dot(i, C.xxx) ;

    // Other corners
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min( g.xyz, l.zxy );
    vec3 i2 = max( g.xyz, l.zxy );

    //   x0 = x0 - 0.0 + 0.0 * C.xxx;
    //   x1 = x0 - i1  + 1.0 * C.xxx;
    //   x2 = x0 - i2  + 2.0 * C.xxx;
    //   x3 = x0 - 1.0 + 3.0 * C.xxx;
    vec3 x1 = x0 - i1 + C.xxx;
    vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
    vec3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

    // Permutations
    i = mod289(i);
    vec4 p = permute( permute( permute(
                                       i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
                              + i.y + vec4(0.0, i1.y, i2.y, 1.0 ))
                     + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

    // Gradients: 7x7 points over a square, mapped onto an octahedron.
    // The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
    float n_ = 0.142857142857; // 1.0/7.0
    vec3  ns = n_ * D.wyz - D.xzx;

    vec4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

    vec4 x = x_ *ns.x + ns.yyyy;
    vec4 y = y_ *ns.x + ns.yyyy;
    vec4 h = 1.0 - abs(x) - abs(y);

    vec4 b0 = vec4( x.xy, y.xy );
    vec4 b1 = vec4( x.zw, y.zw );

    //vec4 s0 = vec4(lessThan(b0,0.0))*2.0 - 1.0;
    //vec4 s1 = vec4(lessThan(b1,0.0))*2.0 - 1.0;
    vec4 s0 = floor(b0)*2.0 + 1.0;
    vec4 s1 = floor(b1)*2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));

    vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
    vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

    vec3 p0 = vec3(a0.xy,h.x);
    vec3 p1 = vec3(a0.zw,h.y);
    vec3 p2 = vec3(a1.xy,h.z);
    vec3 p3 = vec3(a1.zw,h.w);

    //Normalise gradients
    vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;

    // Mix final noise value
    vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
    vec4 m2 = m * m;
    vec4 m4 = m2 * m2;
    vec4 pdotx = vec4(dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3));

    // Determine noise gradient
    vec4 temp = m2 * m * pdotx;
    gradient = -8.0 * (temp.x * x0 + temp.y * x1 + temp.z * x2 + temp.w * x3);
    gradient += m4.x * p0 + m4.y * p1 + m4.z * p2 + m4.w * p3;
    gradient *= 42.0;

    return 42.0 * dot(m4, pdotx);
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

    float distFromCenter = distance(uv2, vec2(slider03, 0.9+-0.8* slider04));
    float audioVal = texture(audioTex, vec2(distFromCenter * (1.0 - 1.0 * knob03) * audioTexSize.x, 0)).r;
    float sqAudioVal = texture(audioTex, vec2(sin(distFromCenter) * audioTexSize.x, 0)).r;

    vec3 grad1, grad2, grad3;
    float rand1 = snoise(vec3(uv2.x, uv2.y, (rmsCumul / 100.0) + rms / 30.0) * 3.0, grad1) * 3.0;
    float rand2 = snoise(vec3(uv2.x, uv2.y, rmsCumul / 300.0 + 50) * 3.0, grad2) * 5.0;
    float rand3 = snoise(vec3(uv2.x, uv2.y, rmsCumul / 500.0 + 100) * 3.0, grad3) * 5.0;
    float stepped1 = smoothstep(0.25 * distFromCenter, max(rms, 0.3) * distFromCenter, rand1);
    float stepped2 = smoothstep(0.75, max(rms, 0.8), rand2);
    float stepped3 = smoothstep(0.75, max(rms, 0.8), rand3);

    vec3 color1 = modColor(vec3(181, 248, 54) / 255.0, slider00);
    vec3 color2 = modColor(vec3(47, 218, 200) / 255.0, slider01);
    vec3 color3 = modColor(vec3(93, 72, 225) / 255.0, slider02);

    vec3 color1Amt = stepped1 * color1;// * min(rms + 0.5, 1.0);
    vec3 color2Amt = stepped2 * color2;
    vec3 color3Amt = stepped3 * color3;

    float audioFac1 = smoothstep(0.5, 1.0, min(pow(audioVal, 0.5), 1.0));
    float audioFac2 = 0;min(pow(audioVal, 0.) + 0.1, 1.0);
    float audioFac3 = min(rms, 1.0);
    float audioFac = min(audioFac1 + audioFac2 + audioFac3, 1.0);

    vec3 out3 = audioFac * (color1Amt + color2Amt + color3Amt);
    outColor = vec4(out3, 1.0);
}
