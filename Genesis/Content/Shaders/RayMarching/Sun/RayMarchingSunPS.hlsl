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

Texture2D NoiseTexture : register(t0);
SamplerState SamplerTex : register(s0);

struct VS_Quad
{
    float4 position : SV_POSITION;
    float2 canvasXY : TEXCOORD0;
};

float pn(in float3 p)
{
    float3 ip = floor(p);
    p = frac(p);
    p *= p * (3.0 - 2.0 * p);
    float2 uv = (ip.xy + float2(37.0, 17.0) * ip.z) + p.xy;
    uv = NoiseTexture.Sample(SamplerTex, (uv + .5) / 256.0).yx;
    return lerp(uv.x, uv.y, p.z);
}

float fpn(float3 p)
{
    return pn(p * .06125) * .57 + pn(p * .125) * .28 + pn(p * .25) * .15;
}

float rand(float2 co)
{   
    return frac(sin(dot(co * 0.123, float2(12.9898, 78.233))) * 43758.5453);
}

#define NoiseSteps 4
#define NoiseAmplitude 0.08
#define NoiseFrequency 48.0
#define Animation float3(5.0, -3.0, 0.5)
  
float Turbulence(float3 position, float minFreq, float maxFreq, float qWidth)
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

float sdSphere(float3 position, float radius)
{
    return length(position) - radius;
}

float Sun(float3 position, float3 rposition, float radius)
{
    float distance;
    
    float noise = Turbulence(position * NoiseFrequency + Animation * time * 1.24, 0.1, 1.5, 0.03) * NoiseAmplitude;
    noise = saturate(abs(noise));
    
    distance = sdSphere(position - rposition, radius)-noise;
    return distance;
}

float map(float3 p)
{
    float d1 = Sun(p, posW, 3.5);
    return d1;
}

float3 firePalette(float i)
{
    float T = 1500. + 1400. * i; // Temperature range (in Kelvin).
    float3 L = float3(7.4, 5.6, 4.4); // Red, green, blue wavelengths (in hundreds of nanometers).
    L = pow(L, (float3)5.0) * (exp(1.43876719683e5 / (T * L)) - 1.0);
    return 1.0 - exp(-5e8 / L); // Exposure level. Set to "50." For "70," change the "5" to a "7," etc.
}

#define DITHERING

float4 main(VS_Quad input) : SV_TARGET
{
    float3 ro = mul(float4(0, 0, 0, 1.0f), invView).xyz;
    float3 pixelPos = float3(input.canvasXY, -1);
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
    float3 tc = (float3) 0.;
   	
    #ifdef DITHERING
    float2 pos = (input.canvasXY.xy / float2(projection._m00, projection._m11));
    float2 seed = pos + frac(time);
    #endif
    
    float maxDensity = 200.;
    float maxDist = 100.;
    
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
        d = abs(d) * (.8 + 0.28 * rand(seed * (float2)i));
        #endif 
        
        // enforce minimum stepsize
        d = max(d, 0.04);
      
        // step forward
        t += d * 0.5;
    }
        
    tc = firePalette(tc.x);
    
    //if (ld <= 0.001)
    //{
    //    float3 stars = (float3)pn(rd * 300.0) * 0.5 + 0.5;
    //    float3 col = (float3)0.0;
    //    col = lerp(col, float3(0.8, 0.9, 1.0), smoothstep(0.95, 1.0, stars) * clamp(dot((float3)0.0, rd) + 0.75, 0.0, 1.0));
    //    col = clamp(col, 0.0, 1.0);
    //    tc += col;
    //}
    
    return float4(tc, 1.0);
}