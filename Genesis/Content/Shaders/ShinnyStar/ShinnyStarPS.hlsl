cbuffer PerFrameCB : register(b0)
{
    float3 eye;
    float pad1;
    float time;
    float3 pad2;
    float3 posW;
    float pad3;
};

struct GSOutput
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
};

#if 1

static float star_luminosity = 50.0;
static float2 FragCoord;

float3 draw_star(float2 pos, float3 star_col)
{
    pos -= float2(0.5,0.5);
    float d = length(pos) * 150.0;
    float3 col, spectrum = star_col;
    col = spectrum / (d * d * d);
	
	// produce spikes
    d = length(pos * float2(10., .2)) * 100.0;
    col += spectrum / (d * d * d);
    d = length(pos * float2(.2, 10.)) * 100.0;
    col += spectrum / (d * d * d);

    return col;
}


float4 main(GSOutput input) : SV_TARGET
{
    FragCoord = input.uv;
    
    float3 star_color = float3(abs(sin(time)), 0.2, abs(cos(time))) * star_luminosity;
    float3 color = draw_star(input.uv, star_color);
    
    float2 center = float2(0.5, 0.5);
    float falloff = 1.0 - smoothstep(0.0, 0.3, length(input.uv - center)); // falloff
    
    return float4(color * falloff, 1.0);
}

#else

#define SPIKE_WIDTH 0.01
#define CORE_SIZE 0.4

float parabola(float x, float k)
{
    return pow(4.0 * x * (1.0 - x), k);
}

float cubicPulse(float c, float w, float x)
{
    x = abs(x - c);
    if (x > w)
        return 0.0;
    x /= w;
    return 1.0 - x * x * (3.0 - 2.0 * x);
}

float3 starWithSpikes(float2 uv, float3 starColor)
{
    float d = 1.0 - length(uv - 0.5);

    float spikeV = cubicPulse(0.5, SPIKE_WIDTH, uv.x) * parabola(uv.y, 2.0) * 0.5;
    float spikeH = cubicPulse(0.5, SPIKE_WIDTH, uv.y) * parabola(uv.x, 2.0) * 0.5;
    float core = pow(d, 30.0) * CORE_SIZE;
    float corona = pow(d, 6.0);
    
    float val = spikeV + spikeH + core + corona;
    return float3(val * (starColor + val));
}

float4 main(GSOutput input) : SV_TARGET
{
    float2 uv = input.uv;
    
    float3 starColor = float3(abs(sin(time)), 0.1, abs(cos(time)));
    float3 col = starWithSpikes(uv, starColor);
    
    float2 center = float2(0.5, 0.5);
    float falloff = 1.0 - smoothstep(0.0, 0.5, length(input.uv - center)); // falloff
    
    return float4(col * falloff, 1.0);
}

#endif