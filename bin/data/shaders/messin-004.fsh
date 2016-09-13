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

float snoise(vec3 v)
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
    m = m * m;
    return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1),
                                 dot(p2,x2), dot(p3,x3) ) );
}

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

float sphere(vec3 pos)
{
    vec3 spherePos = vec3(0,0.0,0);
    float radius = 10.0 + rms;//max(0.0, pow(rms, 0.5) - 0.1) * 0.5;

    return length(pos - spherePos) - radius;
}

float displacement( vec3 p ) {
    //    return sin(1.1*p.x)*sin(4.0*p.y)*sin(2.0*p.z);
    return abs(rms) / 10.0;
}

float sdHexPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
    return max(q.z-h.y,max((q.x*0.866025+q.y*0.5),q.y)-h.x);
}

float sdTorus( vec3 p, vec2 t )
{
    vec2 q = vec2(length(p.xz)-t.x,p.y);
    return length(q)-t.y;
}


float shapeCombine(vec3 p) {
    float amtTorus = smoothstep(0.1, 0.9, slider03) + 0.01;
    float torus = sdTorus(p, vec2(0.1, 0.03 + knob03 * 0.5));

    float amtPrism = smoothstep(0.1, 0.9, slider04) + 0.01;
    float prism = sdHexPrism(p, vec2(0.1, 0.03 + knob04 * 0.5));

    float totalAmt = amtTorus + amtPrism;
    return amtTorus / totalAmt * torus + amtPrism / totalAmt * prism;
}

float opTwist( vec3 p )
{

    float c = cos(rms*30.0*p.y);
    float s = sin(rms*30.0*p.y);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xz,p.y);
    return shapeCombine(q);
}

float opDisplace( vec3 p )
{
    float d1 = opTwist(p);
    float d2 = displacement(p);
    return d1+d2;
}

float sphereRep( vec3 p, vec3 c )
{
    vec3 q = mod(p,c)-0.5*c;
    return opDisplace(q);
}

//float box(vec3 pos)
//{
//    vec3 size = vec3(0.4);
//    vec3 boxPos = vec3(6,0.3,abs(cos(time) * 1.0 + 10.0));
//    return length(max(abs(pos - boxPos) - size, 0.0));
//}

float distfunc(vec3 pos)
{
    float d1 = sphere(pos);
    float d2 = 1000;//box(pos);
    return min(d1, d2);
}

vec3 hsv2rgb( in vec3 c ){
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z * mix( vec3(1.0), rgb, c.y);
}

vec3 genColor(float wheelPos) {
    vec3 c = vec3(mod(wheelPos, 1.0), 1.0, 1.0);
    c = hsv2rgb(c);

    return c;
}

vec4 rayMarch(vec3 start, vec3 dir, vec2 screenPos) {
    const int MAX_ITER = 100; // 100 is a safe number to use, it won't produce too many artifacts and still be quite fast
    const float MAX_DIST = 50.0; // Make sure you change this if you have objects farther than 20 units away from the camera
    const float EPSILON = 0.001; // At this distance we are close enough to the object that we have essentially hit it

    float totalDist = 0.0;
    vec3 pos = start;
    float dist = EPSILON;

    for (int i = 0; i < MAX_ITER; i++)
    {
        // Either we've hit the object or hit nothing at all, either way we should break out of the loop
        if (dist < EPSILON || totalDist > MAX_DIST)
            break; // If you use windows and the shader isn't working properly, change this to continue;

        dist = distfunc(pos); // Evalulate the distance at the current point
        totalDist += dist;
        pos += dist * dir; // Advance the point forwards in the ray direction by the distance
    }

    if (dist < EPSILON)
    {
        vec3 lp = vec3(0, 2, -2);
        vec2 eps = vec2(0.0, EPSILON);
        vec3 normal = normalize(vec3(
                                     distfunc(pos + eps.yxx) - distfunc(pos - eps.yxx),
                                     distfunc(pos + eps.xyx) - distfunc(pos - eps.xyx),
                                     distfunc(pos + eps.xxy) - distfunc(pos - eps.xxy)));

        float diffuse = max(0.5, dot(-dir, normal));
        float specular = pow(diffuse, 12.0);
        vec3 color = vec3(diffuse + specular);

        float size = 1.0;

        float whichX = floor(abs(pos.x) * size);
        float whichY = floor(abs(pos.y) * size);
        float val = texture(audioTex, vec2(pow(whichX / audioTexSize.x, 0.75), 0)).r;

        vec3 color1 = genColor(slider00);
        vec3 color2 = genColor(slider01 + 0.2);
        vec3 color3 = genColor(slider02 + 0.3);

        vec3 modded = floor(mod(abs(pos), vec3(3.0)));
        vec3 thisColor =
        color1 * step(-0.5, modded.x) * step(-0.5, -modded.x)
        +
        color2 * step(0.5, modded.x) * step(-1.5, -modded.x)
        +
        color3 * step(1.5, modded.x) * step(-2.5, -modded.x)
        ;

        vec3 myColor = mix(vec3(0,0,0), thisColor, pow(val, 0.1)) * color;
        //        vec3 modded = floor(mod(pos, vec3(3.0)));
        //        vec3 myColor = vec3(modded.x / 3.0, 0.0, 0.0);//vec3(abs(pos.x / 10.0));
        return vec4(myColor, 1.0);
    }
    else
    {
        return vec4(vec3(0.0), 1.0);
    }
}

void main() {
    float x = snoise(vec3(rmsCumul, 0.0, 0.0) / 100.0) - 0.5;
    float y = snoise(vec3(0.0, rmsCumul, 0.0) / 100.0) - 0.5;

    float dir1 = snoise(vec3(time / 10.0 + 1000.0, 0.0, 17.0)) - 0.5;
    float dir2 = snoise(vec3(0.0, time / 10.0 + 1000.0, 17.0)) - 0.5;

    vec3 cameraOrigin = vec3(0.0,0.0, -20);
    vec3 cameraTarget = vec3(0.0, 0.0, 0.0);
    vec3 upDirection  = vec3(dir1, dir2, 0.0);
    vec3 cameraDir = normalize(cameraTarget - cameraOrigin);

    vec3 cameraRight = normalize(cross(upDirection, cameraOrigin));
    vec3 cameraUp = cross(cameraDir, cameraRight);

    vec2 screenPos = -1.0 + 2.0 * gl_FragCoord.xy / resolution.xy; // screenPos can range from -1 to 1
    screenPos.x *= resolution.x / resolution.y; // Correct aspect ratio

    vec3 rayDir = normalize(cameraRight * screenPos.x + cameraUp * screenPos.y + cameraDir);
    
    vec4 color1 = rayMarch(cameraOrigin, rayDir, screenPos);
    vec4 color2 = vec4(1.0);
    outColor = min(color1, color2);
}