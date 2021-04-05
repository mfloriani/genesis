static const float EPSILON = 0.0001;
static const float NEAR_PLANE = 1.0;
static const float FAR_PLANE = 200.0;
static const int MAX_STEPS = 200;

cbuffer ModelViewProjCB : register(b0)
{
    matrix model;
    matrix view;
    matrix projection;
    matrix invView;
}

cbuffer CameraCB : register(b1)
{
    float3 eye;
    float  pad;
};

cbuffer TimeCB : register(b2)
{
    float  time;
    float3 pad2;
};

struct VS_Quad
{
    float4 position : SV_POSITION;
    float2 canvasXY : TEXCOORD0;
};

struct Ray
{
    float3 o;
    float3 d;
};

struct Light
{
    float3 position;
    float4 ambient;
    float4 diffuse;
    float4 specular;
    float shininess;
};

static Light light =
{
    float3(0, 10, 0),
    float4(0.2f, 0.2f, 0.2f, 1.0f),
    float4(0.3f, 0.3f, 0.3f, 1.0f),
    float4(0.3f, 0.3f, 0.3f, 1.0f),
    16.0
};

float2x2 rotate(float a)
{
    float s = sin(a);
    float c = cos(a);
    return float2x2(c, -s, s, c);
}

float dot2(in float2 v)
{
    return dot(v, v);
}
float dot2(in float3 v)
{
    return dot(v, v);
}

float rounding(in float d, in float h)
{
    return d - h;
}

// union 
float4 opU(float4 d1, float4 d2)
{
    return (d1.w < d2.w) ? d1 : d2;
}

// intersection
float4 opI(float4 d1, float4 d2)
{
    return (d1.w > d2.w) ? d1 : d2;
}

// subtraction
float4 opS(float4 d1, float4 d2)
{
    return (-d2.w < d1.w) ? d1 : float4(d2.xyz, -d2.w);
}

float3 twist(float3 p, float rep)
{
    float c = cos(rep * p.y + rep);
    float s = sin(rep * p.y + rep);
    float2x2 m = float2x2(c, -s, s, c);
    return float3(mul(p.xz, m), p.y);
}

float softAbs2(float x, float a)
{
    float xx = 2.0 * x / a;
    float abs2 = abs(xx);
    if (abs2 < 2.0)
        abs2 = 0.5 * xx * xx * (1.0 - abs2 / 6) + 2.0 / 3.0;
    return abs2 * a / 2.0;
}

float softMax2(float x, float y, float a)
{
    return 0.5 * (x + y + softAbs2(x - y, a));
}

float softMin2(float x, float y, float a)
{
    return -0.5 * (-x - y + softAbs2(x - y, a));
}


float smoothU(float d1, float d2, float k)
{
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return lerp(d2, d1, h) - k * h * (1.0 - h);
}

float smoothS(float d1, float d2, float k)
{
    //float h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0);
    //return lerp(d2, -d1, h) + k * h * (1.0 - h);
    
    float h = max(k - abs(-d1 - d2), 0.0);
    return max(-d1, d2) + h * h * 0.25 / k;
}

float smoothI(float d1, float d2, float k)
{
    float h = clamp(0.5 - 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return lerp(d2, d1, h) + k * h * (1.0 - h);
}


float3 opRep(in float3 p, in float s)
{
    return fmod(p + s * 0.5, s) - s * 0.5;
}

float2 opRep(in float2 p, in float s)
{
    return fmod(p + s * 0.5, s) - s * 0.5;
}

float opExtrussion(in float3 p, in float sdf, in float h)
{
    float2 w = float2(sdf, abs(p.z) - h);
    return min(max(w.x, w.y), 0.0) + length(max(w, 0.0));
}


float2 opRevolution(in float3 p, float w)
{
    return float2(length(p.xz) - w, p.y);
}



float sdPlane(float3 p)
{
    return p.y;
}

float sdLink(in float3 p, in float le, in float r1, in float r2)
{
    float3 q = float3(p.x, max(abs(p.y) - le, 0.0), p.z);
    return length(float2(length(q.xy) - r1, q.z)) - r2;
}

float sdChain(in float3 pos, in float le, in float r1, in float r2)
{
    float ya = max(abs(frac(pos.y) - 0.5) - le, 0.0);
    float yb = max(abs(frac(pos.y + 0.5) - 0.5) - le, 0.0);

    float la = ya * ya - 2.0 * r1 * sqrt(pos.x * pos.x + ya * ya);
    float lb = yb * yb - 2.0 * r1 * sqrt(pos.z * pos.z + yb * yb);
    
    return sqrt(dot(pos.xz, pos.xz) + r1 * r1 + min(la, lb)) - r2;
}

float sdSphere(float3 p, float s)
{
    return length(p) - s;
}

float sdCube(float3 p, float3 b)
{
    float3 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0);
}

float sdTorus(float3 p, float2 t)
{
    float2 q = float2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float sdHexagonalPrism(float3 p, float2 h)
{
    const float3 k = float3(-0.8660254, 0.5, 0.57735);

    p = abs(p);
    p.xy -= 2.0 * min(dot(k.xy, p.xy), 0.0) * k.xy;

    float2 d = float2(length(p.xy - float2(clamp(p.x, -k.z * h.x, k.z * h.x), h.x)) * sign(p.y - h.x), p.z - h.y);

    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdRoundBox(float3 p, float3 b, float r)
{
    float3 q = abs(p) - b;
    return min(max(q.x, max(q.y, q.z)), 0.0) + length(max(q, 0.0)) - r;
}

float sdCylinder(float3 p, float2 h)
{
    float2 d = abs(float2(length(p.xz), p.y)) - h;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

//float sdCylinder(float3 p, float2 h)
//{
//    return max(length6(p.xz) - h.x, abs(p.y) - h.y);
//}

float sdCylinder(float3 p, float3 a, float3 b, float r)
{
    float3 pa = p - a;
    float3 ba = b - a;
    float baba = dot(ba, ba);
    float paba = dot(pa, ba);

    float x = length(pa * baba - ba * paba) - r * baba;
    float y = abs(paba - baba * 0.5) - baba * 0.5;
    float x2 = x * x;
    float y2 = y * y * baba;
    float d = (max(x, y) < 0.0) ? -min(x2, y2) : (((x > 0.0) ? x2 : 0.0) + ((y > 0.0) ? y2 : 0.0));
    return sign(d) * sqrt(abs(d)) / baba;
}

//float torus82SDF(float3 p, float2 t)
//{
//    float2 q = float2(length2(p.xz) - t.x, p.y);
//    return length8(q) - t.y;
//}

float sdBox(float3 p, float3 b)
{
    float3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float sdCone(float3 p, float3 c)
{
    float2 q = float2(length(p.xz), p.y);
    float d1 = -q.y - c.z;
    float d2 = max(dot(q, c.xy), q.y);
    return length(max(float2(d1, d2), 0.0)) + min(max(d1, d2), 0.0);
}

//float cappedConeSDF(float3 p, float h, float r1, float r2)
//{
//    float2 q = float2(length(p.xz), p.y);

//    float2 k1 = float2(r2, h);
//    float2 k2 = float2(r2 - r1, 2.0 * h);
//    float2 ca = float2(q.x - min(q.x, (q.y < 0.0) ? r1 : r2), abs(q.y) - h);
//    float2 cb = q - k1 + k2 * clamp(dot(k1 - q, k2) / dot2(k2), 0.0, 1.0);
//    float s = (cb.x < 0.0 && ca.y < 0.0) ? -1.0 : 1.0;
//    return s * sqrt(min(dot2(ca), dot2(cb)));
//}

float sdRoundCone(float3 p, float r1, float r2, float h)
{
    float2 q = float2(length(p.xz), p.y);

    float b = (r1 - r2) / h;
    float a = sqrt(1.0 - b * b);
    float k = dot(q, float2(-b, a));

    if (k < 0.0)
        return length(q) - r1;
    if (k > a * h)
        return length(q - float2(0.0, h)) - r2;

    return dot(q, float2(a, b)) - r1;
}

//float sdRoundCone(float3 p, float3 a, float3 b, float r1, float r2)
//{
//    float3 ba = b - a;
//    float l2 = dot(ba, ba);
//    float rr = r1 - r2;
//    float a2 = l2 - rr * rr;
//    float il2 = 1.0 / l2;

//    float3 pa = p - a;
//    float y = dot(pa, ba);
//    float z = y - l2;
//    float x2 = dot2(pa * l2 - ba * y);
//    float y2 = y * y * l2;
//    float z2 = z * z * l2;

//    float k = sign(rr) * rr * rr * x2;
//    if (sign(z) * a2 * z2 > k)
//        return sqrt(x2 + z2) * il2 - r2;
//    if (sign(y) * a2 * y2 < k)
//        return sqrt(x2 + y2) * il2 - r1;
//    return (sqrt(x2 * a2 * il2) + y * rr) * il2 - r1;
//}

float sdEllipsoid(float3 p, float3 r)
{
    float k0 = length(p / r);
    float k1 = length(p / (r * r));
    return k0 * (k0 - 1.0) / k1;

}

float sdEquilateralTriangle(float2 p)
{
    const float k = 1.73205;
    p.x = abs(p.x) - 1.0;
    p.y = p.y + 1.0 / k;
    if (p.x + k * p.y > 0.0)
        p = float2(p.x - k * p.y, -k * p.x - p.y) / 2.0;
    p.x += 2.0 - 2.0 * clamp((p.x + 2.0) / 2.0, 0.0, 1.0);
    return -length(p) * sign(p.y);
}

float sdTriPrism(float3 p, float2 h)
{
    float3 q = abs(p);
    float d1 = q.z - h.y;
    h.x *= 0.866025;
    float d2 = sdEquilateralTriangle(p.xy / h.x) * h.x;
    return length(max(float2(d1, d2), 0.0)) + min(max(d1, d2), 0.);
}

float sdHexPrism(float3 p, float2 h)
{
    float3 q = abs(p);

    const float3 k = float3(-0.8660254, 0.5, 0.57735);
    p = abs(p);
    p.xy -= 2.0 * min(dot(k.xy, p.xy), 0.0) * k.xy;
    float2 d = float2(
		length(p.xy - float2(clamp(p.x, -k.z * h.x, k.z * h.x), h.x)) * sign(p.y - h.x),
		p.z - h.y);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdOctahedron(float3 p, float s)
{
    p = abs(p);

    float m = p.x + p.y + p.z - s;

    float3 q;
    if (3.0 * p.x < m)
        q = p.xyz;
    else if (3.0 * p.y < m)
        q = p.yzx;
    else if (3.0 * p.z < m)
        q = p.zxy;
    else
        return m * 0.57735027;

    float k = clamp(0.5 * (q.z - q.y + s), 0.0, s);
    return length(float3(q.x, q.y - s + k, q.z - k));
}

float sdPyramid(in float3 p, in float h)
{
    float m2 = h * h + 0.25;
    
    // symmetry
    p.xz = abs(p.xz);
    p.xz = (p.z > p.x) ? p.zx : p.xz;
    p.xz -= 0.5;
	
    // project into face plane (2D)
    float3 q = float3(p.z, h * p.y - 0.5 * p.x, h * p.x + 0.5 * p.y);
   
    float s = max(-q.x, 0.0);
    float t = clamp((q.y - 0.5 * p.z) / (m2 + 0.25), 0.0, 1.0);
    
    float a = m2 * (q.x + s) * (q.x + s) + q.y * q.y;
    float b = m2 * (q.x + 0.5 * t) * (q.x + 0.5 * t) + (q.y - m2 * t) * (q.y - m2 * t);
    
    float d2 = min(q.y, -q.x * m2 - q.y * 0.5) > 0.0 ? 0.0 : min(a, b);
    
    // recover 3D and scale, and add sign
    return sqrt((d2 + q.z * q.z) / m2) * sign(max(q.z, -p.y));;
}

float sdPryamid4(float3 p, float3 h) // h = { cos a, sin a, height }
{
    // Tetrahedron = Octahedron - Cube
    float box = sdBox(p - float3(0, -2.0 * h.z, 0), (float3)2.0 * h.z);
 
    float d = 0.0;
    d = max(d, abs(dot(p, float3(-h.x, h.y, 0))));
    d = max(d, abs(dot(p, float3(h.x, h.y, 0))));
    d = max(d, abs(dot(p, float3(0, h.y, h.x))));
    d = max(d, abs(dot(p, float3(0, h.y, -h.x))));
    float octa = d - h.z;
    return max(-box, octa); // Subtraction
}

float sdCross(in float2 p, in float2 b, float r)
{
    p = abs(p);
    p = (p.y > p.x) ? p.yx : p.xy;
    
    float2 q = p - b;
    float k = max(q.y, q.x);
    float2 w = (k > 0.0) ? q : float2(b.y - p.x, -k);
    
    return sign(k) * length(max(w, 0.0)) + r;
}

float udRoundBox(float3 p, float3 b, float r)
{
    return length(max(abs(p) - b, 0.0)) - r;
}

float sdCappedCone(in float3 p, in float h, in float r1, in float r2)
{
    float2 q = float2(length(p.xz), p.y);
    
    float2 k1 = float2(r2, h);
    float2 k2 = float2(r2 - r1, 2.0 * h);
    float2 ca = float2(q.x - min(q.x, (q.y < 0.0) ? r1 : r2), abs(q.y) - h);
    float2 cb = q - k1 + k2 * clamp(dot(k1 - q, k2) / dot2(k2), 0.0, 1.0);
    float s = (cb.x < 0.0 && ca.y < 0.0) ? -1.0 : 1.0;
    return s * sqrt(min(dot2(ca), dot2(cb)));
}

float sdConeSection(in float3 p, in float h, in float r1, in float r2)
{
    float d1 = -p.y - h;
    float q = p.y - h;
    float si = 0.5 * (r1 - r2) / h;
    float d2 = max(sqrt(dot(p.xz, p.xz) * (1.0 - si * si)) + q * si - r2, q);
    return length(max(float2(d1, d2), 0.0)) + min(max(d1, d2), 0.);
}

float sdCapsule(float3 p, float3 a, float3 b, float r)
{
    float3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

float sdVerticalCapsule(float3 p, float h, float r)
{
    p.y -= clamp(p.y, 0.0, h);
    return length(p) - r;
}

// returns xyz as color and w as distance
float4 scene(float3 p)
{
    float4 d = float4(0, 0, 0, 1e10); // xyz = color, w = distance
    
    //Ray Marched Implicit Geometric Primitives
    
    
    // hollow box cut using plane
    {        
        float plane = dot(p, normalize(float3(1, 1, 1))) +6.5;
        //d = opU(d, float4(1, 1, 1, plane));
        float3 boxPos = p - float3(-20.3, 8.5f, -5.0);
        float box = sdBox(boxPos, float3(4.05f, 4.05f, 4.05f));
        box = abs(box) - .05; // hollow
        d = opU(d, float4(0, .5, 1, max(plane, box)));
        
        
        
        d = opU(d, float4(1, 1, 0, sdTriPrism(boxPos - float3(3.3, .5, 0), float2(.1, 0.1))));
        d = opU(d, float4(1, 0, 0, sdCone(boxPos - float3(1.0, .93f, .0), float3(.4, .4, .4))));
        d = opU(d, float4(1, 1, 1, sdRoundBox(boxPos - float3(2.3, .5f, 0), float3(0.1f, 0.1f, 0.1f), 0.016)));
        d = opU(d, float4(0, 1, 0, sdEllipsoid(boxPos - float3(3.6, .5f, 2), float3(0.1, 0.1, 0.1))));
        d = opU(d, float4(0.4, 0.3, 0.7, sdCylinder(boxPos - float3(2.6, -.5f, 0.0), float3(0.052, -0.052, 0.0), float3(-0.52, 0.56, 0.52), 0.416)));
        d = opU(d, float4(1, 0.5, 0.5, sdCylinder(boxPos - float3(-2.6, .5f, 2.6), float2(.12, .14))));
        d = opU(d, float4(0, 0.5, 0.8, sdHexPrism(boxPos - float3(3.3, .5f, 3.6), float2(.15, .11))));
        d = opU(d, float4(0.4, 0.1, 0.1, sdRoundCone(boxPos - float3(0.6, -.5f, 0.6), 0.24, 0.22, 0.26)));
        
    }
    
    float waveBox = sdRoundBox(p - float3(5.0, -28.5f, -5.0), float3(10.05f, 1.05f, 10.05f), 1.) - sin(p.x * 7.5 + time * 3.)* .02;
    d = opU(d, float4(0.5, 0.5, 1, waveBox));
        
    /* clone objects using abs
    float3 box2Pos = p - float3(10, 8, -8);
    //box2Pos.x = abs(box2Pos.x);
    //box2Pos.x -= 1.;
    box2Pos = abs(box2Pos);
    box2Pos -= 1.;
    
    float scale = lerp(1., 3., smoothstep(-1., 1., box2Pos.y));
    box2Pos.xz *= scale;
    //box2Pos.xz = mul(box2Pos.xz, rotate(box2Pos.y));
    box2Pos.xz = mul(box2Pos.xz, rotate(smoothstep(0., 1., box2Pos.y)));
    float box2 = sdBox(box2Pos, float3(1, 1, 1)) / scale;
    d = opU(d, float4(1, 0.4, 0.2, box2));
    */
    
    {
        float3 pos = float3(0, -15, -40);
        float3 s1Pos = p - (pos);
        float3 s2Pos = p - (pos - float3(sin(time) * 4., 0, 0));
        float3 s3Pos = p - (pos - float3(0, sin(time) * 7., 0));
        float3 s4Pos = p - (pos - float3(sin(time) * 2., 0, sin(time) * 2.));
        
        float s1Dist = sdSphere(s1Pos, 5.0 * 1 + sin(time));
        float s2Dist = sdSphere(s2Pos, 5.0 * 1 + sin(time));
        float s3Dist = sdSphere(s3Pos, 5.0 * 1 + sin(time));
        float s4Dist = sdSphere(s4Pos, 5.0 * 1 + sin(time));
        
        float blend = softMin2(s1Dist, softMin2(s2Dist, softMin2(s3Dist, s4Dist, 0.9), 0.9), 0.9);
        
        d = opU(d, float4(.5, 0, .5, blend));
    }
    
    // open close object
    {
        float3 q = p - float3(30.0, 10.0, -5.0);
        d = min(d, float4(1, 1, 1, sdCross(opRevolution(q, 0.5 + 0.5 * sin(time)), float2(0.5, 0.15), 0.1)));
    }
    
    
    
    // planet with ring
    {
        float3 planetPos = p - float3(-70, 40, -75);
        d = opU(d, float4(1, 0, 0, sdSphere(planetPos, 20.0)));
        d = opU(d, float4(1, 1, 0, sdTorus(planetPos + (float3(sin(time), sin(time)+.5, cos(time)+1.) * 2.), float2(35.0, 1.5))));        
    }
    
    // vulcano
    {
        float3 basePos = p - float3(-50, -20, 15);
        float baseDist = sdConeSection(basePos, 7.95, 7.9, 2.9);
        
        float3 spherePos = basePos - float3(.0, 8.5, .0);
        float sphereDist = sdSphere(spherePos, 2.);
        
        float volcano = smoothS(sphereDist, baseDist, 0.5);
        
        float rock = sdSphere(spherePos - float3(0, sin(time) * 10., 0), 0.75);
        float rock2 = sdSphere(spherePos - float3(1, sin(time) * 8., 0), .55);
        float rock3 = sdSphere(spherePos - float3(0, sin(time) * 15., 1), .35);
        
        float final = softMin2(volcano, softMin2(rock, softMin2(rock2, rock3, 0.5), 0.5), 0.5);
        
        d = opU(d, float4(1, 0, 0, final));
    }
    
    
    // portal box with deformed sphere inside
    {
        float3 pos = p - float3(10.0, 0.2, 5.0);
        float roundBox = udRoundBox(pos, (float3) 1.55, 0.05);
        float sphere = sdSphere(pos, 1.95);
        float4 portalBox = opS(
            float4(1, 1, 1, roundBox),
            float4(1, 0, 1, sphere)
        );
        d = opU(d, portalBox);
        
        float deformedSphere = 0.5 * sdSphere(pos, 1.2) + 0.03 * sin(50.0 * p.x) * sin(50.0 * p.y + time * -5.) * sin(50.0 * p.z);
        d = opU(d, float4(1, .2, 1, deformedSphere));
    }
    
    // infinite repetition
    {
        float3 infPos = float3(abs(p.x), p.y + 25., abs(p.z));
        infPos.xz = opRep(infPos.xz, 35.);
        //float infSphere = sdSphere(infPos, 0.3);
        float infDist = sdOctahedron(infPos, 1.07);
        d = opU(d, float4(0.9, .9, 0, infDist));
    }
    
    // flag
    {
        float3 flagPos = p - float3(55.0, 7.0, -85.0);
        flagPos.z += sin(flagPos.x * 1.5 - time * 3.) * .1;
        float flag = sdBox(flagPos, float3(10., 5., .1));
        d = opU(d, float4(1, 1, 1, flag));
    
        float flagPost = sdCylinder(flagPos - float3(-10, -14, 0), float2(0.5, 20.04));
        d = opU(d, float4(0.3, 0.3, 0.3, flagPost));
    }
    
    // rocket
    {
        float3 conePos = p - float3(0.0, 0.0 + time, -25.0);
        float coneDist = rounding(sdCappedCone(conePos, 1.4, 1.3, .05), 0.1);
        
        float3 cylinderPos = conePos - float3(.0, -6.5, .0);
        float cylinderDist = sdCylinder(cylinderPos, float2(1.02, 5.04));
        
        float3 leftBoosterPos = cylinderPos - float3(-1.5, -.8, 0);
        float leftBoosterdist = sdVerticalCapsule(leftBoosterPos, 3., .5);
        
        float body = softMin2(cylinderDist, leftBoosterdist, 0.5);
        
        float3 rightBoosterPos = cylinderPos - float3(1.5, -.8, 0);
        float rightBoosterdist = sdVerticalCapsule(rightBoosterPos, 3., .5);
        
        body = softMin2(body, rightBoosterdist, 0.5);
        
        float3 basePos = cylinderPos - float3(.0, -6, .0);
        float baseDist = sdConeSection(basePos, 1.95, 1.9, 0.9);
        
        d = opU(d, float4(.5, .5, .5,
                softMin2(
                    softMin2(coneDist, body, .5),
                    baseDist,
                    0.5
                )
        ));
    }
    
    
    return d;
}

float4 raymarch(Ray r)
{
    float t = EPSILON;
    
    for (int i = 0; i < MAX_STEPS; i++)
    {
        float4 cd = scene(r.o + t * r.d); // returns xyz as color and w as distance
        
        if(cd.w < EPSILON)
            return float4(cd.xyz, t);
        
        t += cd.w; // w is distance
        
        if(t >= FAR_PLANE)
            return float4(0, 0, 0, t);
    }
    return float4(0, 0, 0, FAR_PLANE);
}

float3 calcNormal(float3 p)
{
    return normalize(float3(
        scene(float3(p.x + EPSILON, p.y, p.z)).w - scene(float3(p.x - EPSILON, p.y, p.z)).w,
		scene(float3(p.x, p.y + EPSILON, p.z)).w - scene(float3(p.x, p.y - EPSILON, p.z)).w,
		scene(float3(p.x, p.y, p.z + EPSILON)).w - scene(float3(p.x, p.y, p.z - EPSILON)).w)
    );
}

float4 phong(float3 pos, float3 normal, float3 rayD, float4 color)
{
    float4 ambient = float4(0.0f, 0.0f, 0.0f, 0.0f);
    float4 diffuse = float4(0.0f, 0.0f, 0.0f, 0.0f);
    float4 specular = float4(0.0f, 0.0f, 0.0f, 0.0f);
    
    ambient += light.ambient * color;

    float3 lightDirection = normalize(light.position - pos);
    float nDotL = dot(normal, lightDirection);
    float3 reflection = normalize(reflect(-lightDirection, normal));
    float rDotV = max(0.0f, dot(reflection, -rayD));
    diffuse += saturate(light.diffuse * nDotL * color);
    
    if (nDotL > 0.0f)
        specular += light.specular * pow(rDotV, light.shininess);

    return ambient + diffuse + specular;
}

float4 main(VS_Quad input) : SV_TARGET
{
    float3 pixelPos = float3(input.canvasXY, -NEAR_PLANE);
    
    Ray ray;
    ray.o = mul(float4(0, 0, 0, 1.0f), invView);
    ray.d = normalize(mul(float4(pixelPos, 0.0f), invView));
    
    float4 colorDist = raymarch(ray);
    
    if (colorDist.w > FAR_PLANE - EPSILON)
        discard;
    
    float3 pos = ray.o + ray.d * colorDist.w;
    
    light.position.xz += float2(sin(time), cos(time)) * 2.0;
    
    float4 color = phong(pos, calcNormal(pos), ray.d, float4(colorDist.xyz, 1.0));
    
    return color;
}