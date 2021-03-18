cbuffer CameraCB : register(b0)
{
    float3 gCamEye;
    float padding;
};

struct PS_Input
{
    float4 positionH : SV_POSITION;
    float3 positionW : WORLDPOS;
    float3 normal : NORMAL;
    float3 tangent : TANGENT;
    float3 binormal : BINORMAL;
    float2 textcoord : TEXCOORD;
    float tessFactor : TESS;
};


static float3 gLightDir = float3(0.0, 1.0, 1.0);
static float4 gLightAmb = float4(0.3, 0.3, 0.3, 1.0);
static float4 gLightDiff = float4(1.0, 0.0, 1.0, 1.0);

static float3 gLightDir2 = float3(0.0, 0.0, -1.0);
static float4 gLightAmb2 = float4(0.3, 0.3, 0.3, 1.0);
static float4 gLightDiff2 = float4(0.0, 1.0, 0.0, 1.0);

float4 Shading( float3 normal, float3 toCamEye )
{
    float4 ambient = (float4) 0;
    float4 diffuse = (float4) 0;
    float4 specular = (float4) 0;
    
    {
        ambient += float4(0.5, 0.5, 0.5, 1.0) * gLightAmb;
        float3 lightDir = normalize(-gLightDir);
        float diffFactor = dot(lightDir, normal);
        if (diffFactor > 0.0f)
            diffuse += diffFactor * float4(0.4, 0.4, 0.4, 1.0) * gLightDiff;
    }
    
    
    {
        ambient += float4(0.5, 0.5, 0.5, 1.0) * gLightAmb2;
        float3 lightDir = normalize(-gLightDir2);
        float diffFactor = dot(lightDir, normal);
        if (diffFactor > 0.0f)
            diffuse += diffFactor * float4(0.4, 0.4, 0.4, 1.0) * gLightDiff2;
    }
    return ambient + diffuse + specular;

}

float4 main(PS_Input input) : SV_TARGET
{
    input.normal = normalize(input.normal);
    float3 toCamEye = normalize(gCamEye - input.positionW);
    
    return Shading(input.normal, toCamEye);
}