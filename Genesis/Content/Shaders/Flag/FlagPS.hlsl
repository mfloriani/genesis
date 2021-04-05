struct PS_Input
{
    float4 positionH : SV_POSITION;
    float3 positionW : POSITION;
    float3 camViewDir : TEXCOORD1;
};

float4 main(PS_Input input) : SV_TARGET
{
    return float4(1, 1, 0, 1);
}