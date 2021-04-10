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

cbuffer PerFrameCB : register(b1)
{
    float3 eye;
    float pad1;
    float time;
    float3 pad2;
    float3 posW;
    float pad3;
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
    float3(0, 15.f, -10.f),
    float4(0.2f, 0.2f, 0.2f, 1.0f),
    float4(0.3f, 0.3f, 0.3f, 1.0f),
    float4(0.3f, 0.3f, 0.3f, 1.0f),
    16.0
};

float sdSphere(float3 p, float s)
{
    return length(p) - s;
}

float sdTorus(float3 p, float ri, float rc)
{
    float2 q = float2(length(p.xy) - rc, p.z);
    return length(q) - ri;
}

static float3 SATURN_COLOR = float3(0.8, 0.7, 0.3);
static const float pi = 3.14159;

static const float4 cHashA4 = float4(0., 1., 57., 58.);
static const float3 cHashA3 = float3(1., 57., 113.);
static const float cHashM = 43758.54;

float2 Rot2D(float2 q, float a)
{
    return q * cos(a) * float2(1., 1.) + q.yx * sin(a) * float2(-1., 1.);
}

float2 Hashv2f(float p)
{
    return frac(sin(p + cHashA4.xy) * cHashM);
}

float Noiseff(float p)
{
    float i, f;
    i = floor(p);
    f = frac(p);
    f = f * f * (3. - 2. * f);
    float2 t = Hashv2f(i);
    return lerp(t.x, t.y, f);
}

float SmoothBump(float lo, float hi, float w, float x)
{
    return (1. - smoothstep(hi - w, hi + w, x)) * smoothstep(lo - w, lo + w, x);
}

float4 sdSaturn(float3 p, float dHit)
{
    float3 col = (float3) 0;
    
    const float dz = 6., radO = 9., radI = 6.5;
    float3 q;
    float d;
    q = p;
    q -= posW;
    q.yz = Rot2D(q.yz, -0.2 * pi);
    q.xz = Rot2D(q.xz, -0.2 * pi);
    d = sdSphere(q, 5.);
    if (d < dHit)
    {
        col = SATURN_COLOR * float3(1., 0.9, 0.9) * clamp(1. - 0.2 * Noiseff(12. * q.z), 0., 1.);
        dHit = d;
    }
    q.z += dz;
    d = sdTorus(q, radI, radO);
    q.z -= 2. * dz;
    d = max(d, sdTorus(q, radI, radO));
    if (d < dHit)
    {
        col = SATURN_COLOR * (1. - 0.4 * SmoothBump(9.3, 9.5, 0.01, length(q.xy)));
        dHit = d;
    }
    return float4(col, dHit);
}

// returns xyz as color and w as distance
float4 scene(float3 p)
{
    float4 d = float4(0, 0, 0, 1e10); // xyz = color, w = distance
    
    {
        d = sdSaturn(p, d.w);
    }
    
    return d;
}

float4 raymarch(Ray r)
{
    float t = EPSILON;
    
    for (int i = 0; i < MAX_STEPS; i++)
    {
        float4 cd = scene(r.o + t * r.d); // returns xyz as color and w as distance
        
        if (cd.w < EPSILON)
            return float4(cd.xyz, t);
        
        t += cd.w; // w is distance
        
        if (t >= FAR_PLANE)
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

static const float dstFar = 200.;

float ObjDf(float3 p)
{
    float3 q;
    float d;
    float dHit = dstFar;
    dHit = sdSaturn(p, dHit).w;
    return dHit;
}

float3 saturnNormal(float3 p)
{
    const float3 e = float3(0.001, -0.001, 0.);
    float4 v = float4(ObjDf(p + e.xxx), ObjDf(p + e.xyy), ObjDf(p + e.yxy), ObjDf(p + e.yyx));
    return normalize((float3) (v.x - v.y - v.z - v.w) + (2. * v.yzw));
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

float ObjSShadow(float3 ro, float3 rd)
{
    float sh, d, h;
    sh = 1.;
    d = 0.2;
    for (int i = 0; i < 30; i++)
    {
        h = ObjDf(ro + rd * d);
        sh = min(sh, 20. * h / d);
        d += 0.2;
        if (h < 0.001)
            break;
    }
    return clamp(sh, 0., 1.);
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
    
    float3 sunDir = light.position - pos;
    float sh = ObjSShadow(ray.o, sunDir);
    
    float3 n = saturnNormal(pos);
    float4 color = phong(pos, n, ray.d, float4(colorDist.xyz, 1.)) * sh;
    color = sqrt(clamp(color, 0., 1.));
    
    return color;
}