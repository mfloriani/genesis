struct GSOutput
{
	float4 pos : SV_POSITION;
	float2 uv  : TEXCOORD0;
};

float4 main(GSOutput input) : SV_TARGET
{
	return float4(1.0f, 1.0f, 1.0f, 1.0f);
}