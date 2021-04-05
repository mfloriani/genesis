struct PS_Input
{
    float4 positionH : SV_POSITION;
    float3 positionW : POSITION;
    float3 camViewDir : TEXCOORD1;
    float3 normal : NORMAL;
    float3 tangent : TANGENT;
    float3 binormal : BINORMAL;
    float2 uv : TEXCOORD2;
};

static float3 gLightDir = float3(0.0, 0.0, 1.0);
static float4 gLightAmb = float4(0.3, 0.3, 0.3, 1.0);
static float4 gLightDiff = float4(1, 1, 1, 1.0);

static float3 gPotAmb = float3(0.8, 0.63, 0.25);
static float3 gPotDiff = float3(0.8, 0.63, 0.25);

float4 Shading(float3 normal, float3 toCamEye)
{
    float4 ambient = (float4) 0;
    float4 diffuse = (float4) 0;
    float4 specular = (float4) 0;
    
    {
        ambient += float4(gPotAmb, 1.0) * gLightAmb;
        float3 lightDir = normalize(-gLightDir);
        float diffFactor = dot(lightDir, normal);
        if (diffFactor > 0.0f)
            diffuse += diffFactor * float4(gPotDiff, 1.0) * gLightDiff;
    }
    
    return ambient + diffuse + specular;

}

float4 main(PS_Input input) : SV_TARGET
{
    float3 normal = normalize(input.normal);
    return Shading(normal, input.camViewDir);
}