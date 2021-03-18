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


static float3 gLightDir = { 0.0, 0.0, 2.0 };
static float4 gLightAmb = { 0.2, 0.2, 0.2, 1.0 };
static float4 gLightDiff = { 1.4, 0.0, 0.0, 1.0 };

void Shading
(
    float3 normal, float3 toCamEye, out float4 ambient, out float4 diffuse, out float4 specular
)
{
    ambient = float4(0.0f, 0.0f, 0.0f, 0.0f);
    diffuse = float4(0.0f, 0.0f, 0.0f, 0.0f);
    specular = float4(0.0f, 0.0f, 0.0f, 0.0f);

    ambient = float4(0.5, 0.5, 0.5, 1.0) * gLightAmb;

    float3 lightDir = normalize(-gLightDir);

    float diffFactor = dot(lightDir, normal);

    if (diffFactor > 0.0f)
        diffuse = diffFactor * float4(0.4, 0.4, 0.4, 1.0) * gLightDiff;
        
}

float4 main(PS_Input input) : SV_TARGET
{
    float4 ambient = float4(0.0f, 0.0f, 0.0f, 0.0f);
    float4 diffuse = float4(0.0f, 0.0f, 0.0f, 0.0f);
    float4 specular = float4(0.0f, 0.0f, 0.0f, 0.0f);
    
    input.normal = normalize(input.normal);
    float3 toCamEye = normalize(gCamEye - input.positionW);
    
    Shading(input.normal, toCamEye, ambient, diffuse, specular);
    
    return ambient + diffuse + specular;
}