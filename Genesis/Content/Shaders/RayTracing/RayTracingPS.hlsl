static float EPSILON = 0.0001;
static float nearPlane = 1.00;
static float farPlane = 100.0;

static float4 LightColor = float4(1, 1, 1, 1);
static float3 LightPos = float3(0, 100, 0);

static float4 sphereColor_1 = float4(1, 0, 0, 1); //sphere1 color
static float4 sphereColor_2 = float4(0, 1, 0, 1); //sphere2 color
static float4 sphereColor_3 = float4(1, 0, 1, 1); //sphere3 color
static float shininess = 10;

cbuffer ModelViewProjCB : register(b0)
{
    matrix model;
    matrix view;
    matrix projection;
    matrix invView;
}

cbuffer CameraCB : register(b1)
{
    float3 cameraPos;
    float padding;
};


struct VS_Quad
{
    float4 position : SV_POSITION;
    float2 canvasXY : TEXCOORD0;
};

struct Ray
{
    float3 o; // origin
    float3 d; // direction
};

struct Sphere
{
    float3 centre;
    float rad2; // radius* radius
    float4 color;
    float Kd, Ks, Kr, shininess;
};

#define NOBJECTS 3
static Sphere object[NOBJECTS] =
{
    { 0.0, 2.0, 0.0, 1.0, sphereColor_1, 0.3, 0.5, 0.7, shininess },
    { 2.0, -2.0, 0.0, 1, sphereColor_2, 0.5, 0.7, 0.4, shininess },
    { -2.0, 0.0, 1.0, 1, sphereColor_3, 0.5, 0.3, 0.3, shininess },
};

float3 SphereNormal(Sphere s, float3 pos)
{
    return normalize(pos - s.centre);
}

float SphereIntersect(Sphere s, Ray ray, out bool hit)
{
    float t;
    float3 v = s.centre - ray.o;
    float A = dot(v, ray.d);
    float B = dot(v, v) - A * A;
    float R = sqrt(s.rad2);
    if (B > R * R)
    {
        hit = false;
        t = farPlane;
    }
    else
    {
        float disc = sqrt(R * R - B);
        t = A - disc;
        if (t < 0.0)
        {
            hit = false;
        }
        else
            hit = true;
    }
    return t;
}

float3 NearestHit(Ray ray, out int hitobj, out bool anyhit, out float mint)
{
    mint = farPlane;
    hitobj = -1;
    anyhit = false;
    for (int i = 0; i < NOBJECTS; i++)
    {
        bool hit = false;
        float t = SphereIntersect(object[i], ray, hit);
        if (hit)
        {
            if (t < mint)
            {
                hitobj = i;
                mint = t;
                anyhit = true;
            }
        }
    }
    return ray.o + ray.d * mint;
}

bool AnyHit(Ray ray)
{
    bool anyhit = false;
    for (int i = 0; i < NOBJECTS; i++)
    {
        bool hit;
        float t = SphereIntersect(object[i], ray, hit);
        if (hit)
        {
            anyhit = true;
        }
    }
    return anyhit;
}

float4 Phong(float3 n, float3 l, float3 v, float shininess, float4 diffuseColor, float4 specularColor)
{
    float NdotL = dot(n, l);
    float diff = saturate(NdotL);
    float3 r = reflect(l, n);
    float spec = pow(saturate(dot(v, r)), shininess) * (NdotL > 0.0);
    return diff * diffuseColor + spec * specularColor;
}

float4 Shade(float3 hitPos, float3 normal, float3 viewDir, int hitobj, float lightIntensity)
{
    Ray shadowRay;
    shadowRay.o = hitPos.xyz;
    shadowRay.d = LightPos - hitPos.xyz;
    float shadowFactor = 1.0;
    //if (AnyHit(shadowRay))
    //    shadowFactor = 0.3;

    float3 lightDir = normalize(LightPos - hitPos);
    float4 diff = object[hitobj].color * object[hitobj].Kd;
    float4 spec = object[hitobj].color * object[hitobj].Ks;
    return LightColor * lightIntensity * Phong(normal, lightDir, viewDir, object[hitobj].shininess, diff, spec) * shadowFactor;
}

float4 RayTracing(Ray ray, out bool anyHit)
{
    int hitobj;
    bool hit = false;
    float3 n;
    float4 c = (float4) 0;
    float lightInensity = 1.0;
    float mint = 0.0f;
    anyHit = false;
	
    float3 i = NearestHit(ray, hitobj, hit, mint);
    
    for (int depth = 1; depth < 5; depth++)
    {
        if (hit)
        {
            anyHit = true;
            n = SphereNormal(object[hitobj], i);
            c += Shade(i, n, ray.d, hitobj, lightInensity);
			// shoot refleced ray
            lightInensity *= object[hitobj].Kr;
            ray.o = i;
            ray.d = reflect(ray.d, n);
            i = NearestHit(ray, hitobj, hit, mint);
        }
    }
    return float4(c.xyz, mint);
}

struct PS_Output
{
    float4 color : SV_TARGET;
    float depth : SV_DEPTH;
};

//PS_Output main(VS_Quad input)
float4 main(VS_Quad input) : SV_TARGET
{
    float dist2Imageplane = nearPlane;//   5.0;
    float3 PixelPos = float3(input.canvasXY, -dist2Imageplane);

    Ray eyeray;
    eyeray.o = mul(float4(float3(0.0f, 0.0f, 0.0f), 1.0f), invView);
    eyeray.d = normalize(mul(float4(PixelPos, 0.0f), invView));
    
    bool anyHit = false;
    float4 colorDistance = RayTracing(eyeray, anyHit);
    
    if (!anyHit)
    //if (colorDistance.w > farPlane - EPSILON)
        discard;
    
    //PS_Output output;
    
    //float3 surfacePoint = cameraPos + colorDistance.w * eyeray.d;

    //float4 pv = mul(float4(surfacePoint, 1.0f), view);
    //pv = mul(pv, projection);
    //output.depth = pv.z / pv.w;

    //output.color = float4(colorDistance.xyz, 1.0f);
    //output.color = float4(lerp(output.color.xyz, float3(1.0f, 0.97255f, 0.86275f), 1.0 - exp(-0.0005 * colorDistance.w * colorDistance.w * colorDistance.w)), 1.0f);

    return float4(colorDistance.xyz, 1.0);
    //return output;
}
