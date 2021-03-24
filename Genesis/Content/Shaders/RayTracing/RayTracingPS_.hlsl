cbuffer ModelViewProjCB : register(b0)
{
    matrix model;
    matrix view;
    matrix projection;
    matrix invView;
};

cbuffer CameraCB : register(b1)
{
    float3 camEye;
    float padding;
};

struct VS_Output
{
    float4 position : SV_POSITION;
    float2 canvasXY : TEXCOORD0;
};

struct PS_Output
{
    float4 colour : SV_TARGET;
    float depth : SV_DEPTH;
};

struct Ray
{
    float3 o; // origin
    float3 d; // direction
};

struct HitData
{
    bool hit;
    int object;
    float3 normal;
    int material;
};

struct Sphere
{
    float3 centre;
    float rad2; // radius* radius
    int material;
};

struct Box
{
    float3 mi;
    float3 ma;
    int material;
};

struct Material
{
    float4 color;
    float Kd, Ks, Kr, shininess;
};


static float4 red = float4(1, 0, 0, 1);
static float4 green = float4(0, 1, 0, 1);
static float4 blue = float4(0, 0, 1, 1);
static float4 white = float4(1, 1, 1, 1);

static float shininess = 10;

static float nearPlane = 1.0;
static float farPlane = 1000.0;
static float EPSILON = 0.0001;

static float4 lightColor = float4(1.0f, 1.0f, 1.0f, 1.0f);
static float3 lightPos = float3(0.0f, 5.0f, 0.0f);

#define NOSPHERES 3
static Sphere spheres[NOSPHERES] =
{
    { 0.0, 2.0, 0.0, 3.0, 0 },   // material index 0
    { 2.0, -1.0, 0.0, 1, 1 }, // material index 1
    { -2.0, -3.0, -1.0, 5, 2 },  // material index 2
};

#define NOBOXES 1
static Box boxes[NOBOXES] =
{
    { -20,0,-20, 20,20,20, 3 }, // material index 3
};

// total objects is NOSPHERES + NOBOXES
#define NOOBJECTS 4
static Material objectMaterials[NOOBJECTS] =
{
    { red, 0.3, 0.5, 0.7, shininess },
    { green, 0.3, 0.5, 0.7, shininess },
    { blue, 0.3, 0.5, 0.7, shininess },
    { white, 0.3, 0.5, 0.7, shininess },
};


float3 SphereNormal(Sphere s, float3 pos)
{
    return normalize(pos - s.centre);
}

float SphereIntersect(Sphere s, Ray ray, out bool hit, out float3 normal, out int material)
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
        normal = SphereNormal(s, t);
        material = s.material;
        if (t < 0.0)
            hit = false;
        else
            hit = true;
    }
    
    return t;
}

#define INF 100000.0
float BoxIntersect(in Box b, in Ray r, out bool hit, out float3 normal, out int material)
{
    float t;
    float3 size = b.ma - b.mi;
    
    float3 dA = (r.o - b.mi) / -r.d;
    float3 dB = (r.o - b.ma) / -r.d;
    
    float3 minD = min(dA, dB); // -
    float3 maxD = max(dA, dB); // +
    
    float tmin = minD.x;
    float tmax = maxD.x;
    
    if (tmin > maxD.y || tmax < minD.y)
    {
        hit = false;
        return t;
    }
    
    tmin = max(tmin, minD.y); //-
    tmax = min(tmax, maxD.y); //+
               
    if (tmin > maxD.z || tmax < minD.z)
    {
        hit = false;
        return t;
    }
    
    tmin = max(tmin, minD.z); //-
    float insideScaling = sign(tmin);
    
    tmin = tmin <= 0.0 ? INF : tmin; //+
    
    tmax = min(tmax, maxD.z); //+
    tmax = tmax < 0.0 ? INF : tmax; //+
    float testVal = tmax;
    float d = min(tmin, tmax); // tmax
    
    float f = step(0.0, -d);
    d = d * (1. - f) + (f * INF);
    if (d > INF)
    {
        hit = false;
        return t;
    }
    
    dA -= d;
    dB -= d;
    
    dA = step((float3)0.001, abs(dA));
    dB = step((float3)0.001, abs(dB));
    
    float3 n = dA + -dB;    
    normal = n * insideScaling;
    material = b.material;
    t = d;
    
    return t;
}

float3 NearestHit(
    Ray ray, out HitData hitData, 
    //out int hitobj, out bool anyhit, 
    out float mint
)
{
    mint = farPlane;
    
    hitData.object = -1;
    hitData.hit = false;
    
    bool hit = false;
    //hitobj = -1;
    //anyhit = false;
    
    float t; // hit point
    float3 n; // normal
    int m; // material

    for (int i = 0; i < NOSPHERES; i++)
    {
        t = SphereIntersect(spheres[i], ray, hit, n, m);
        if (hit)
        {
            if (t < mint)
            {
                //hitobj = i;
                //anyhit = true;
                hitData.hit = true;
                hitData.object = i;
                hitData.normal = n;
                hitData.material = spheres[i].material;
                mint = t;
            }
        }
    }
    
    //hit = false;
    //for (int j = 0; j < NOBOXES; j++)
    //{
    //    t = BoxIntersect(boxes[j], ray, hit, n, m);
    //    if (hit)
    //    {
    //        if (t < mint)
    //        {
    //            //hitobj = j;
    //            //anyhit = true;
    //            hitData.hit = true;
    //            hitData.object = i;
    //            hitData.normal = n;
    //            hitData.material = boxes[j].material;
    //            mint = t;
    //        }
    //    }
    //}
    
    return ray.o + ray.d * mint;
}

bool AnyHit(Ray ray)
{
    bool anyhit = false;
    for (int i = 0; i < NOSPHERES; i++)
    {
        bool hit;
        float3 n;
        int m;
        float t = SphereIntersect(spheres[i], ray, hit, n, m);
        if (hit)
            anyhit = true;
    }
    
    for (int j = 0; j < NOBOXES; j++)
    {
        bool hit;
        float3 n;
        int m;
        float t = BoxIntersect(boxes[j], ray, hit, n, m);
        if (hit)
            anyhit = true;
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

float4 Shade(float3 hitPos, float3 normal, Ray ray, Material hitMat, float lightIntensity)
{
    float3 lightDir = normalize(lightPos - hitPos);

    float4 diff = (float4) 0.0f;
    float4 spec = (float4) 0.0f;
    float shininess = 0.0f;
    
    diff = hitMat.color * hitMat.Kd;
    spec = hitMat.color * hitMat.Ks;
    shininess = hitMat.shininess;

    //if (AnyHit(ray))
    //{
        return lightColor * lightIntensity * Phong(normal, lightDir, ray.d, shininess, diff, spec);
    //}
    //else
    //{
    //    return (float4) 1.0f;
    //}

}

float4 RayTracing(Ray ray)
{
    //int hitobj;
    //bool hit = false;    
    //float3 n;
    
    HitData hitData;
    hitData.hit = false;
    hitData.object = -1;
    
    float4 c = (float4) 0;
    float lightIntensity = 1.0;

    float mint = 0.0f;
    float3 i = NearestHit(ray, hitData, mint);

    for (int depth = 1; depth < 5; depth++)
    {
        if (hitData.hit)
        {
            hitData.normal = SphereNormal(spheres[hitData.object], i);
            c += Shade(i, hitData.normal, ray, objectMaterials[hitData.material], lightIntensity);
			//Shoot reflect ray
            lightIntensity *= objectMaterials[hitData.material].Kr;
            ray.o = i;
            ray.d = reflect(ray.d, hitData.normal);
            float mint2 = 0.0f;
            i = NearestHit(ray, hitData, mint2);
        }
    }

    return float4(mint, c.xyz);
}

PS_Output main(VS_Output input)
{
    float3 pixelPos = float3(input.canvasXY, -nearPlane);
    
    Ray eyeray;
    eyeray.o = mul(float4(0,0,0,1), invView);
    eyeray.d = normalize(mul(float4(pixelPos, 0.0f), invView));
    
    float4 distanceAndColour = RayTracing(eyeray);

    if (distanceAndColour.x > farPlane - EPSILON)
        discard;

    float3 surfacePoint = camEye + distanceAndColour.x * eyeray.d;

    float4 pv = mul(float4(surfacePoint, 1.0f), view);
    pv = mul(pv, projection);
    
    PS_Output output;
    output.depth = pv.z / pv.w;

    output.colour = float4(distanceAndColour.yzw, 1.0f);
    output.colour = float4(lerp(output.colour.xyz, float3(1.0f, 0.97255f, 0.86275f), 1.0 - exp(-0.0005 * distanceAndColour.x * distanceAndColour.x * distanceAndColour.x)), 1.0f);
    
    return output;
}