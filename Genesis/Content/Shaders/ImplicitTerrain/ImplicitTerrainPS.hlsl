static const float EPSILON = 0.0001;
static const float NEAR_PLANE = 1.00;
static const float FAR_PLANE = 500.0;
static const float MAX_HEIGHT = 60.0;
static const float3 SUN_DIR = float3(-0.624695, 0.468521, -0.624695);
static const int RAY_COUNT = 400;

#define LOWQUALITY

cbuffer ModelViewProjCB : register(b0)
{
    matrix model;
    matrix view;
    matrix projection;
    matrix invView;
}

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

static const float2x2 m2 = float2x2(0.80, 0.60, -0.60, 0.80);
static const float2x2 m2i = float2x2(0.80, -0.60, 0.60, 0.80);

static const float3x3 m3 = float3x3( 0.00,  0.80,  0.60,
                                    -0.80,  0.36, -0.48,
                                    -0.60, -0.48,  0.64);
static const float3x3 m3i = float3x3( 0.00, -0.80, -0.60,
                                      0.80,  0.36, -0.48,
                                      0.60, -0.48,  0.64);

float hash1(float2 p)
{
    p = 50.0 * frac(p * 0.3183099);
    return frac(p.x * p.y * (p.x + p.y));
}

float hash1(float n)
{
    return frac(n * 17.0 * frac(n * 0.3183099));
}

float noise(in float2 x)
{
    float2 p = floor(x);
    float2 w = frac(x);
#if 1
    float2 u = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);
#else
    float2 u = w*w*(3.0-2.0*w);
#endif

    float a = hash1(p + float2(0, 0));
    float b = hash1(p + float2(1, 0));
    float c = hash1(p + float2(0, 1));
    float d = hash1(p + float2(1, 1));
    
    return -1.0 + 2.0 * (a + (b - a) * u.x + (c - a) * u.y + (a - b - c + d) * u.x * u.y);
}

// value noise, and its analytical derivatives
float4 noised(in float3 x)
{
    float3 p = floor(x);
    float3 w = frac(x);
#if 1
    float3 u = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);
    float3 du = 30.0 * w * w * (w * (w - 2.0) + 1.0);
#else
    float3 u = w*w*(3.0-2.0*w);
    float3 du = 6.0*w*(1.0-w);
#endif

    float n = p.x + 317.0 * p.y + 157.0 * p.z;
    
    float a = hash1(n + 0.0);
    float b = hash1(n + 1.0);
    float c = hash1(n + 317.0);
    float d = hash1(n + 318.0);
    float e = hash1(n + 157.0);
    float f = hash1(n + 158.0);
    float g = hash1(n + 474.0);
    float h = hash1(n + 475.0);

    float k0 = a;
    float k1 = b - a;
    float k2 = c - a;
    float k3 = e - a;
    float k4 = a - b - c + d;
    float k5 = a - c - e + g;
    float k6 = a - b - e + f;
    float k7 = -a + b + c - d + e - f - g + h;

    return float4(-1.0 + 2.0 * (k0 + k1 * u.x + k2 * u.y + k3 * u.z + k4 * u.x * u.y + k5 * u.y * u.z + k6 * u.z * u.x + k7 * u.x * u.y * u.z),
                      2.0 * du * float3(k1 + k4 * u.y + k6 * u.z + k7 * u.y * u.z,
                                      k2 + k5 * u.z + k4 * u.x + k7 * u.z * u.x,
                                      k3 + k6 * u.x + k5 * u.y + k7 * u.x * u.y));
}

float3 noised(in float2 x)
{
    float2 p = floor(x);
    float2 w = frac(x);
#if 1
    float2 u = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);
    float2 du = 30.0 * w * w * (w * (w - 2.0) + 1.0);
#else
    float2 u = w*w*(3.0-2.0*w);
    float2 du = 6.0*w*(1.0-w);
#endif
    
    float a = hash1(p + float2(0, 0));
    float b = hash1(p + float2(1, 0));
    float c = hash1(p + float2(0, 1));
    float d = hash1(p + float2(1, 1));

    float k0 = a;
    float k1 = b - a;
    float k2 = c - a;
    float k4 = a - b - c + d;

    return float3(-1.0 + 2.0 * (k0 + k1 * u.x + k2 * u.y + k4 * u.x * u.y),
                      2.0 * du * float2(k1 + k4 * u.y,
                                      k2 + k4 * u.x));
}

float4 fbmd_8(in float3 x)
{
    float f = 1.92;
    float s = 0.5;
    float a = 0.0;
    float b = 0.5;
    float3 d = (float3)0.0;
    float3x3 m = float3x3(1.0, 0.0, 0.0,
                          0.0, 1.0, 0.0,
                          0.0, 0.0, 1.0);
    for (int i = 0; i < 7; i++)
    {
        float4 n = noised(x);
        a += b * n.x; // accumulate values		
        d += b * mul(m, n.yzw); // accumulate derivatives
        b *= s;
        x = f * mul(m3, x);
        m = f * mul(m3i, m);
    }
    return float4(a, d);
}

float fbm_9(in float2 x)
{
    float f = 1.9;
    float s = 0.55;
    float a = 0.0;
    float b = 0.5;
    for (int i = 0; i < 9; i++)
    {
        float n = noise(x);
        a += b * n;
        b *= s;
        x = f * mul(m2, x);
    }
    return a;
}

float3 fbmd_9(in float2 x)
{
    float f = 1.9;
    float s = 0.55;
    float a = 0.0;
    float b = 0.5;
    float2 d = (float2)0.0;
    float2x2 m = float2x2(1.0, 0.0, 0.0, 1.0);
    for (int i = 0; i < 9; i++)
    {
        float3 n = noised(x);
        a += b * n.x; // accumulate values
        d += b * mul(m, n.yz); // accumulate derivatives
        b *= s;
        x = f * mul(m2, x);
        m = f * mul(m2i, m);
    }
    return float3(a, d);
}

// return smoothstep and its derivative
float2 smoothstepd(float a, float b, float x)
{
    if (x < a)
        return float2(0.0, 0.0);
    if (x > b)
        return float2(1.0, 0.0);
    float ir = 1.0 / (b - a);
    x = (x - a) * ir;
    return float2(x * x * (3.0 - 2.0 * x), 6.0 * x * (1.0 - x) * ir);
}

float2 terrainMap(in float2 p)
{
    const float sca = 0.0010;
    const float amp = 100.0;
    p *= sca;
    float e = fbm_9(p + float2(1.0, -2.0));
    float a = 1.0 - smoothstep(0.12, 0.13, abs(e + 0.12)); // flag high-slope areas (-0.25, 0.0)
    e = e + 0.15 * smoothstep(-0.08, -0.01, e);
    e *= amp;
    return float2(e, a);
}

float4 terrainMapD(in float2 p)
{
    const float sca = 0.0010;
    const float amp = 300.0;
    p *= sca;
    float3 e = fbmd_9(p + float2(1.0, -2.0));
    float2 c = smoothstepd(-0.08, -0.01, e.x);
    e.x = e.x + 0.15 * c.x;
    e.yz = e.yz + 0.15 * c.y * e.yz;
    e.x *= amp;
    e.yz *= amp * sca;
    return float4(e.x, normalize(float3(-e.y, 1.0, -e.z)));
}

float raymarchTerrain(Ray r, float tmin, float tmax)
{
    // bounding plane
    float tp = (MAX_HEIGHT - r.o.y) / r.d.y;
    if (tp > 0.0)
        tmax = min(tmax, tp);
    
    // raymarch
    float dis, th;
    float t2 = -1.0;
    float t = tmin;
    float ot = t;
    float odis = 0.0;
    float odis2 = 0.0;
    for (int i = 0; i < RAY_COUNT; i++)
    {
        th = 0.001 * t;

        float3 pos = r.o + t * r.d;
        float2 env = terrainMap(pos.xz);
        float hei = env.x;
        
        // terrain
        dis = pos.y - hei;
        if (dis < th)
            break;
        
        ot = t;
        odis = dis;
        t += dis * 0.8 * (1.0 - 0.75 * env.y); // slow down in step areas
        if (t > tmax)
            break;
    }

    if (t > tmax)
        t = -1.0;
    else
        t = ot + (th - odis) * (t - ot) / (dis - odis); // linear interpolation for better accuracy
    
    return t;
}

float terrainShadow(in float3 ro, in float3 rd, in float mint)
{
    float res = 1.0;
    float t = mint;

#ifdef LOWQUALITY
    for( int i=0; i<32; i++ )
    {
        float3  pos = ro + t*rd;
        float2  env = terrainMap( pos.xz );
        float hei = pos.y - env.x;
        res = min( res, 32.0*hei/t );
        if( res<0.0001 || pos.y>MAX_HEIGHT ) break;
        t += clamp( hei, 1.0+t*0.1, 50.0 );
    }
#else
    for (int i = 0; i < 128; i++)
    {
        float3 pos = ro + t * rd;
        float2 env = terrainMap(pos.xz);
        float hei = pos.y - env.x;
        res = min(res, 32.0 * hei / t);
        if (res < 0.0001 || pos.y > MAX_HEIGHT)
            break;
        t += clamp(hei, 0.5 + t * 0.05, 25.0);
    }
#endif

    return clamp(res, 0.0, 1.0);
}

float3 terrainNormal(in float2 pos)
{
#if 1
    return terrainMapD(pos).yzw;
#else    
    float2 e = float2(0.03,0.0);
	return normalize( float3(terrainMap(pos-e.xy).x - terrainMap(pos+e.xy).x,
                             2.0*e.x,
                             terrainMap(pos-e.yx).x - terrainMap(pos+e.yx).x ) );
#endif    
}

float4 main(PS_Input input) : SV_TARGET
{
    float dist2Imageplane = NEAR_PLANE;
    float3 pixelPos = float3(input.canvasXY, -dist2Imageplane);

    Ray ray;
    ray.o = mul(float4(float3(0.0f, 0.0f, 0.0f), 1.0f), invView).xyz;
    ray.d = normalize(mul(float4(pixelPos, 0.0f), invView)).xyz;
    
    const float tmax = FAR_PLANE;
    
    float t = raymarchTerrain(ray, 15.0, tmax);
    
    if (t.x <= 0.0)
        discard;
    
    float3 pos = ray.o + t * ray.d;
    float3 epos = pos + float3(0.0, 2.4, 0.0);
    
    float sha1 = terrainShadow(pos + float3(0, 0.01, 0), SUN_DIR, 0.01);
    
    float3 tnor = terrainNormal(pos.xz);
    
    // bump map
    
    float3 nor = normalize(tnor + 0.8 * (1.0 - abs(tnor.y)) * 0.8 * fbmd_8(pos * 0.3 * float3(1.0, 0.2, 1.0)).yzw);

    float3 col = float3(0.18, 0.18, 0.18) * .85;
    
    float dif = clamp(dot(nor, SUN_DIR), 0.0, 1.0);
    dif *= sha1;
    
    float bac = clamp(dot(normalize(float3(-SUN_DIR.x, 0.0, -SUN_DIR.z)), nor), 0.0, 1.0);
    float foc = clamp((pos.y + 100.0) / 100.0, 0.0, 1.0);
    float dom = clamp(0.5 + 0.5 * nor.y, 0.0, 1.0);
    float3 lin = 1.0 * 0.2 * lerp(0.1 * float3(0.1, 0.2, 0.1), float3(0.4, 0.4, .5) * 3.0, dom) * foc;
    lin += 1.0 * 8.5 * float3(1.0, 0.9, 0.8) * dif;
    lin += 1.0 * 0.27 * float3(1.0, 1.0, 1.0) * bac * foc;

    col *= lin;
    
    //col = sqrt(clamp(col, 0.0, 1.0));

    // contrast
    //col = col * col * (3.0 - 2.0 * col);
    
    // color grade
    //col = pow(col, float3(1.0, 0.92, 1.0)); // soft green
    //col *= float3(1.02, 0.99, 0.99); // tint red
    //col.z = (col.z + 0.1) / 1.1; // bias blue        
    
    return float4(col, 1);
}