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

// union primitives 1 and 2
// d1 is a vec2 where .x is the distance
float4 opU(float4 d1, float4 d2)
{
    return (d1.w < d2.w) ? d1 : d2;
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

// returns xyz as color and w as distance
float4 scene(float3 p)
{
    float4 d = float4(0, 0, 0, 1e10); // xyz = color, w = distance
    
    //Ray Marched Implicit Geometric Primitives
    
    d = opU(d, float4(1, 0, 0, sdCone(p - float3(0.0, 0.53f, 0.0), float3(0.16, 0.12, 0.06))));
    //d = opU(d, sdTorus(p - float3(-0.3, 0.5f, -0.3), float2(0.04, 0.01)));
    //d = opU(d, sdBox(p - float3(-0.3, 0.5f, 0.0), float3(0.05f, 0.05f, 0.05f)));
    //d = opU(d, sdRoundBox(p - float3(-0.3, 0.5f, 0.3), float3(0.04f, 0.04f, 0.04f), 0.016));
    //d = opU(d, sdEllipsoid(p - float3(0.3, 0.5f, -0.3), float3(0.05, 0.05, 0.02)));
    //d = opU(d, sdTriPrism(p - float3(-0.6, 0.5f, -0.3), float2(0.05, 0.02)));
    //d = opU(d, sdCylinder(p - float3(-0.6, 0.5f, 0.0), float3(0.002, -0.002, 0.0), float3(-0.02, 0.06, 0.02), 0.016));
    //d = opU(d, sdCylinder(p - float3(-0.6, 0.5f, 0.3), float2(0.02, 0.04)));
    //d = opU(d, sdOctahedron(p - float3(0.0, 0.5f, 0.6), 0.07));
    //d = opU(d, sdHexPrism(p - float3(-0.3, 0.5f, 0.6), float2(0.05, 0.01)));
    //d = opU(d, sdRoundCone(p - float3(-0.6, 0.5f, 0.6), 0.04, 0.02, 0.06));
    
    float sphere1 = sdSphere(p - (float3(0, 5, 0) + float3(sin(time), 0, 0) * 2), 1.0);
    float sphere2 = sdSphere(p - float3(2, 5, 0), 1.0);
    d = opU(d, float4(0, 0, 1, softMin2(sphere1, sphere2, 0.5)));
    
    return d;
}

float4 rayMarch(Ray r)
{
    float t = EPSILON;
    
    for (int i = 0; i < MAX_STEPS; i++)
    {
        float4 cd = scene(r.o + t * r.d); // returns xyz as color and w as distance
        
        if(cd.w < EPSILON)
            return float4(cd.xyz, t);
        
        t += cd.w; // w is distance
        
        if(t >= FAR_PLANE)
            return float4(0, 0, 0, FAR_PLANE);
    }
    return float4(0, 0, 0, FAR_PLANE);
}

/* from Art of Code
float3 calcNormal(float3 p)
{
    float d = scene(p);
    float2 e = float2(EPSILON, 0);
    
    return normalize(d - float3( scene(p - e.xyy), scene(p - e.yxy), scene(p - e.yyx) ));
}
*/

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

//struct PS_Output
//{
//    float4 color : SV_TARGET;
//    float depth : SV_DEPTH;
//};

float4 main(VS_Quad input) : SV_TARGET
//PS_Output main(VS_Quad input)
{
    float3 pixelPos = float3(input.canvasXY, -NEAR_PLANE);
    
    Ray ray;
    ray.o = mul(float4(0, 0, 0, 1.0f), invView);
    ray.d = normalize(mul(float4(pixelPos, 0.0f), invView));
    
    float4 colorDist = rayMarch(ray);
    
    if (colorDist.w > FAR_PLANE - EPSILON)
        discard;
    
    float3 pos = ray.o + ray.d * colorDist.w;
    
    light.position.xz += float2(sin(time), cos(time)) * 2.0;
    /* from Youtube Art of Code
    float3 n = calcNormal(pos);
    float3 l = normalize(light.position - pos);    
    float dif = dot(n, l);
    float3 color = (float3) dif;
    */
    
    //PS_Output output;
    
    //float4 vPos = mul(float4(pos, 1.0f), view);
    //vPos = mul(vPos, projection);
    //output.depth = vPos.z / vPos.w;
    
    //output.color = phong(
    float4 color = phong(pos, calcNormal(pos), ray.d, float4(colorDist.xyz, 1.0));
    
    return color;
    //return output;
}