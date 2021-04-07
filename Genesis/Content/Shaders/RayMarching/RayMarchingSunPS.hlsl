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
    float pad;
};

cbuffer TimeCB : register(b2)
{
    float iTime;
    float3 pad2;
};

Texture2D NoiseTexture : register(t0);
SamplerState SamplerTex : register(s0);

struct VS_Quad
{
    float4 position : SV_POSITION;
    float2 canvasXY : TEXCOORD0;
};

//#define DITHERING

#define mat2 float2x2
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define fract frac
#define mix lerp

float pn(in vec3 p)
{
    vec3 ip = floor(p);
    p = fract(p);
    p *= p * (3.0 - 2.0 * p);
    vec2 uv = (ip.xy + vec2(37.0, 17.0) * ip.z) + p.xy;
    uv = NoiseTexture.Sample(SamplerTex, (uv + .5) / 256.0).yx;
    return mix(uv.x, uv.y, p.z);
}

float fpn(vec3 p)
{
    return pn(p * .06125) * .57 + pn(p * .125) * .28 + pn(p * .25) * .15;
}

float rand(vec2 co)
{   
    return fract(sin(dot(co * 0.123, vec2(12.9898, 78.233))) * 43758.5453);
}

#define NoiseSteps 4
#define NoiseAmplitude 0.08
#define NoiseFrequency 48.0
#define Animation vec3(2.0, -3.0, 0.5)
  
float Turbulence(vec3 position, float minFreq, float maxFreq, float qWidth)
{
    float value = 0.0;
    float cutoff = clamp(0.5 / qWidth, 0.0, maxFreq);
    float fade;
    float fOut = minFreq;
    for (int i = NoiseSteps; i >= 0; i--)
    {
        if (fOut >= 0.5 * cutoff)
            break;
        fOut *= 2.0;
        value += abs(pn(position * fOut)) / fOut;
    }
    fade = clamp(2.0 * (cutoff - fOut) / cutoff, 0.0, 1.0);
    value += fade * abs(fpn(position * fOut)) / fOut;
    return 1.0 - value;
}

float SphereDist(vec3 position, vec3 rposition, float radius)
{
    return length(position - rposition) - radius;
}

float Star(vec3 position, vec3 rotdir, vec3 rposition, float radius)
{
    float distance;
    
    float noise = Turbulence(position * NoiseFrequency + Animation * iTime * 1.24, 0.1, 1.5, 0.03) * NoiseAmplitude;
    noise = saturate(abs(noise));
    
    distance = SphereDist(position, rposition, radius)-noise;
    return distance;
}

float map(vec3 p)
{
    
    float d1 = Star(p, p, vec3(-1.0, 6.5, -5.0), 2.5);
    return d1;
}

vec3 firePalette(float i)
{

    float T = 1500. + 1400. * i; // Temperature range (in Kelvin).
    vec3 L = vec3(7.4, 5.6, 4.4); // Red, green, blue wavelengths (in hundreds of nanometers).
    L = pow(L, (vec3)5.0) * (exp(1.43876719683e5 / (T * L)) - 1.0);
    return 1.0 - exp(-5e8 / L); // Exposure level. Set to "50." For "70," change the "5" to a "7," etc.
}

float4 main(VS_Quad input) : SV_TARGET
{
    vec2 iResolution = vec2(1200, 900);
    
    float3 ro = mul(float4(0, 0, 0, 1.0f), invView).xyz;
    float3 pixelPos = float3(input.canvasXY, -5.);
    float3 rd = normalize(mul(float4(pixelPos, 0.0f), invView)).xyz;
    
    // ld, td: local, total density 
    // w: weighting factor
    float ld = 0., td = 0., w;

    // t: length of the ray
    // d: distance function
    float d = 1., t = 0.;
   
    // Distance threshold.
    const float h = .1;
   
    // total color
    vec3 tc = (vec3) 0.;
   
#ifdef DITHERING
    vec2 pos = (input.canvasXY.xy / iResolution.xy);
    vec2 seed = pos + fract(iTime);
#endif
	
    float maxDensity = 200.;
    float maxDist = 22.;
    
    for (int i = 0; i < 48; i++)
    {
        // Loop break conditions. 
        if (td > (1. - 1. / maxDensity) || d < 0.001 * t || t > maxDist)
            break;

        // evaluate distance function
        d = map(ro + t * rd);
      
        // check whether we are close enough (step)
        // compute local density and weighting factor 
        // const float h = .1;
        ld = (h - d) * step(d, h);
        w = (1. - td) * ld;
     
        // accumulate color and density
        tc += w * w + 1. / 50.; // Different weight distribution.
        td += w + 1. / maxDensity;
       
#ifdef DITHERING 
        d = abs(d) * (.8 + 0.28 * rand(seed * (vec2)i));
#endif 
       
        // enforce minimum stepsize
        d = max(d, 0.04);
      
        // step forward
        t += d * 0.5;   
    }

    tc = firePalette(tc.x);
    
    return vec4(tc, 1.0);
}