struct GSOutput
{
	float4 pos : SV_POSITION;
	float2 uv  : TEXCOORD0;
};

float4 main(GSOutput input) : SV_TARGET
{
    float2 center = float2(0.5, 0.5);    
    float color = 1.0 - smoothstep(0.0, 0.1, length(input.uv - center)); // falloff
    return (float4) color;
}