Texture2D Texture : register(t0);
SamplerState SamplerTex : register(s0);

struct PS_Input
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
};

float4 main(PS_Input input) : SV_TARGET
{
    float4 texel = Texture.Sample(SamplerTex, input.uv);
    
    float2 center = float2(0.5, 0.5);
    float falloff = 1.0 - smoothstep(0.0, .6, length(input.uv - center));
    
    float4 color = texel * falloff;
    
    return color;
}