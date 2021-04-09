struct PS_Input
{
    float4 positionH : SV_POSITION;
    float3 positionW : WORLDPOS;
    float3 normal : NORMAL;
    float3 tangent : TANGENT;
    float3 binormal : BINORMAL;
    float2 textcoord : TEXCOORD;
    float3 camViewDir : TEXCOORD1;
};

static float3 gLightPos = float3(0.0, 15.f, -10.f);
static float4 gLightAmb = float4(0.3, 0.3, 0.3, 1.0);
static float4 gLightDiff = float4(0.9, .7, .7, 1.0);

float4 Shading(float3 n, float3 lightDir)
{
    float4 ambient = (float4) 0;
    float4 diffuse = (float4) 0;
    float4 specular = (float4) 0;
    
    {
        ambient += float4(0.3, 0.3, 0.3, 1.0) * gLightAmb;
        float3 l = normalize(-lightDir);
        float diffFactor = dot(l, n);
        if (diffFactor > 0.0f)
            diffuse += diffFactor * float4(0.4, 0.4, 0.4, 1.0) * gLightDiff;
    }
    
    return ambient + diffuse + specular;
}

float4 main(PS_Input input) : SV_TARGET
{
    float3 normal = normalize(input.normal);
    
    float3 lightDir = gLightPos - input.positionW;
    
    return Shading(normal, lightDir);
}