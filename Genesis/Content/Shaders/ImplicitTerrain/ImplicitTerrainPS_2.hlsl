static float EPSILON = 0.0001;
static float NEAR_PLANE = 1.00;
static float FAR_PLANE = 500.0;
static int RAY_COUNT = 100;

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
    float  pad1;
    float  time;
    float3 pad2;
    float3 posW;
    float  pad3;
};

struct PS_Input
{
    float4 position : SV_POSITION;
    float2 canvasXY : TEXCOORD0;
};

struct Ray
{
    float3 o; // origin
    float3 d; // direction
};

static const float2x2 mat = float2x2(1.8, 1.1, -1.1, 1.8);

float rand(float2 v)
{
    float x = frac(sin(dot(v, float2(1872.8497, -2574.9248))) * 72123.19);
    return x;
}

float noise(in float2 p)
{
    float2 i = floor(p);
    float2 f = frac(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    return -1.0 + 2.0 * lerp(lerp(rand(i + float2(0.0, 0.0)), rand(i + float2(1.0, 0.0)), u.x),
						lerp(rand(i + float2(0.0, 1.0)), rand(i + float2(1.0, 1.0)), u.x), u.y);
}

float map(float2 xz)
{
    xz += noise(xz);
    float2 a = 1.0 - abs(sin(xz));
    float2 b = abs(cos(xz));
    return pow(dot(a, b) * length(cos(xz)), 0.5) + pow(sin(xz.x), 1.0) + pow(cos(xz.y), 1.0);
}

float terrain(float3 p)
{
    float2 xz = p.xz / 5.0;
    xz.x *= 0.7;
    float amp = 1.5;
    float h = 0.0;
    float freq = 0.1;
    for (int i = 0; i < 5; i++)
    {
        float h1 = map(xz * freq);
        float h2 = map(xz * freq);
        h += (h1 + h2) * amp;
        freq *= 2.1;
        amp *= 0.21;
        xz = mul(mat, xz);
    }
    return p.y - h;
}


float castRay(inout float3 p, float3 dir)
{
    float t = 0.1;
    float d = 0.1;
    for (int i = 0; i < RAY_COUNT; i++)
    {
        float h = terrain(p + dir * t);
        if (h < 0.0)
            break;
		
        d *= 1.05;
        t += d;
        if (i == (RAY_COUNT - 1))
            return FAR_PLANE+1;
    }
    
    float t2 = t;
    float h2 = terrain(p + dir * t2);
    if (h2 > 0.0)
        return t2;
    float t1 = t - d * 10.0;
    float h1 = terrain(p + dir * t1);
    for (int j = 0; j < 8; j++)
    {
        t = lerp(t1, t2, h1 / (h1 - h2));
        float h = terrain(p + dir * t);
        if (h < 0.0)
        {
            t2 = t;
            h2 = h;
        }
        else
        {
            t1 = t;
            h1 = h;
        }
    }
    p = p + dir * t;
    return t;
}

float3 getNormal(float3 p, float d)
{
    float3 n;
    n.y = terrain(p);
    n.x = terrain(p + float3(d, 0.0, 0.0)) - n.y;
    n.z = terrain(p + float3(0.0, 0.0, d)) - n.y;
    n.y = d;
    return normalize(n);
}

float4 main(PS_Input input) : SV_TARGET
{
    float dist2Imageplane = NEAR_PLANE;
    float3 pixelPos = float3(input.canvasXY, -dist2Imageplane);

    Ray ray;
    ray.o = mul(float4(float3(0.0f, 0.0f, 0.0f), 1.0f), invView).xyz;
    ray.d = normalize(mul(float4(pixelPos, 0.0f), invView)).xyz;
    
    float3 color = (float3)0.0;
    float3 light = normalize(float3(0.6, 0.8, 0.3));
    
    float dist = castRay(ray.o, ray.d);
	
    if (dist > FAR_PLANE)
        discard;    
    
    color = float3(0.5, 0.45, 0.4) * pow(max(dot(getNormal(ray.o, dist * 0.001), light), 0.0), 2.0) + noise(ray.o.xz * 4.0) / 25.0;
    
    return float4(color, 1);
}