#version 330
precision highp float;

uniform sampler2DRect audioTex;
uniform sampler2DRect currGradient;
uniform sampler2DRect prevGradient;
uniform vec2 currGradientSize;
uniform vec2 prevGradientSize;
uniform float currGradientAmt;
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

 vec2 ds_set(float a)
{
    vec2 z;
    z.x = a;
    z.y = 0.0;
    return z;
}

vec2 ds_add (vec2 dsa, vec2 dsb)
{
    vec2 dsc;
    float t1, t2, e;

    t1 = dsa.x + dsb.x;
    e = t1 - dsa.x;
    t2 = ((dsb.x - e) + (dsa.x - (t1 - e))) + dsa.y + dsb.y;

    dsc.x = t1 + t2;
    dsc.y = t2 - (dsc.x - t1);
    return dsc;
}

vec2 ds_mul (vec2 dsa, vec2 dsb)
{
    vec2 dsc;
    float c11, c21, c2, e, t1, t2;
    float a1, a2, b1, b2, cona, conb, split = 8193.;

    cona = dsa.x * split;
    conb = dsb.x * split;
    a1 = cona - (cona - dsa.x);
    b1 = conb - (conb - dsb.x);
    a2 = dsa.x - a1;
    b2 = dsb.x - b1;

    c11 = dsa.x * dsb.x;
    c21 = a2 * b2 + (a2 * b1 + (a1 * b2 + (a1 * b1 - c11)));

    c2 = dsa.x * dsb.y + dsa.y * dsb.x;

    t1 = c11 + c2;
    e = t1 - c11;
    t2 = dsa.y * dsb.y + ((c2 - e) + (c11 - (t1 - e))) + c21;

    dsc.x = t1 + t2;
    dsc.y = t2 - (dsc.x - t1);

    return dsc;
}

void main()
{
    float speedScale = 300.0;
    float horizRange = 1.0;
    float minZoom = 100.0;
    float addlZoom = 5000.0;
    float zoomTime = 30.0;
    float zoom = minZoom + (cos(time/zoomTime) + 1.0) * 0.5 * addlZoom;
    int iter = int(1500.0 * slider00);
    float colorSpeed = 6.0;

    vec2 center = vec2(-0.761574,-0.0847596);
    vec3 oooo;

    center.x += (snoise(vec3(time / speedScale, 0, 0), oooo) * 2.0 - 1.0) * horizRange / zoom;
    center.y += (snoise(vec3((time + 17) / speedScale, 0, 0), oooo) * 2.0 - 1.0) * horizRange / zoom;
    float scale =  1.0 / zoom;
    // float scale = 1.0 / 10000.0;

    
    float eps = 1 << 8;
    vec2 uv2 = uv;
    uv2.y = (uv2.y - 0.5) / (resolution.x / resolution.y) + 0.5;
    uv2 -= vec2(0.5);




    // float val = texture(audioTex, vec2(uv2.x, 0)).r;
    // val += time;
    // val = mod(val, 1.0);

    // NAIVE

    // vec2 z, c;
    // c = uv2 * scale + center;

    // int i;
    // z = c;
    // for(i=0; i<iter; i++) {
    //     float x = (z.x * z.x - z.y * z.y) + c.x;
    //     float y = (z.y * z.x + z.x * z.y) + c.y;

    //     if((x * x + y * y) > 4.0) break;
    //     z.x = x;
    //     z.y = y;
    // }

    // OTHER
    // vec2 c = uv2 * scale + center;
    // vec2 cx = ds_set(c.x);
    // vec2 cy = ds_set(c.y);
    // vec2 zx = cx;
    // vec2 zy = cy;
    
    // int i;
    // for(i=0; i<iter; i++) {
    //     vec2 x = ds_add(ds_add(ds_mul(zx, zx), -ds_mul(zy, zy)), cx);
    //     vec2 y = ds_add(ds_add(ds_mul(zy, zx),  ds_mul(zx, zy)), cy);

    //     if(ds_add(ds_mul(x, x), ds_mul(y, y)).x > 4.0) break;
    //     zx = x;
    //     zy = y;
    // }
    
    // float audioAmt = texture(audioTex, vec2(amt, 0)).r;

    // FIELD

    vec2 c = uv2 * scale + center;
    vec2 p = vec2(0.0);
    float xtemp;
    float i = 0;
    float xx = p.x * p.x;
    float yy = p.y * p.y; 
    while (xx + yy < eps && i < iter) {
        xtemp = xx - yy+ c.x;
        p.y = 2 * p.x * p.y + c.y;
        p.x = xtemp;
        i += 1.0;

        xx = p.x * p.x;
        yy = p.y * p.y; 
    }

    if (i < iter) {
        float log_zn = log(xx + yy) / 2.0;
        float nu = log(log_zn / log(2)) / log(2);
        i = i + 1.0 - nu;

        float amt = float(i) / pow(iter, slider01);
        // amt = pow(amt, slider01 * 2.0);
        amt = mod(amt - time / colorSpeed, 1.0);
        vec3 color1 = texture(currGradient, vec2(amt * currGradientSize.x, 0)).rgb;
        vec3 color2 = texture(prevGradient, vec2(amt * prevGradientSize.x, 0)).rgb;
        vec3 out3 = mix(color2, color1, currGradientAmt);
        // out3 *= sqrt(audioAmt);
        // out3 = vec3(amt);
        outColor = vec4(out3, 1.0);
    } else {
        float amt = mod(time / colorSpeed, 1.0);
        vec3 color1 = texture(currGradient, vec2(amt * currGradientSize.x, 0)).rgb;
        vec3 color2 = texture(prevGradient, vec2(amt * prevGradientSize.x, 0)).rgb;
        vec3 out3 = mix(color2, color1, currGradientAmt);
        outColor = vec4(out3, 1.0);
    }

    // i = i == iter ? 0 : i;
    // // i = i < 50 ? 0 : i;
    // float p = 2.0;
    // float num = pow(i, p);
    // float denom = pow(iter / 2, p);
    // float xpos = min(num / denom, 1.0);
    // // xpos = pow(xpos * audioTexSize.x, 1.05);
    // // float amt = texture(audioTex, vec2(xpos, 0)).r;
    // // float amt = cos(xpos + time / 4) * 0.5 + 0.5;
    // float amt = mod(xpos + time / 8, 1.0);
    // amt = pow(amt, 4.0);

    // float amt = i == iter ? 0.0 : float(i) / 400 * val;
    // gl_FragColor = texture1D(tex, (i == iter ? 0.0 : float(i)) / 100.0);

    
}
