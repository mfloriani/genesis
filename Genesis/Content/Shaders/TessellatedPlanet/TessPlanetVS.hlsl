// A constant buffer that stores the three basic column-major matrices for composing geometry.
cbuffer ModelViewProjCB : register(b0)
{
    matrix gModel;
    matrix gView;
    matrix gProj;
    matrix gInvView;
};

cbuffer CameraCB : register(b1)
{
    float3 gCamEye;
    float  padding;
};

cbuffer ObjectCB : register(b2)
{
    float3 gCenterPosW;
    float padding2;
};

struct VS_Input
{
    float3 position : POSITION;
    float3 normal : NORMAL;
    float3 tangent : TANGENT;
    float3 binormal : BINORMAL;
    float2 textcoord : TEXCOORD;
};

struct HS_Input
{
    float3 positionW : WORLDPOS;
    float3 normal : NORMAL;
    float3 tangent : TANGENT;
    float3 binormal : BINORMAL;
    float2 textcoord : TEXCOORD;
    float tessFactor : TESS;
};

#define MAX_TESS_FACTOR 64

HS_Input main(VS_Input input)
{
    float4 pos = float4(input.position, 1.0);    
    float3 posW = mul(pos, gModel).xyz;
    
    float d = distance(gCenterPosW, gCamEye); // TODO: pass position, not (0,0,0)
    
    const float d0 = 1.0f; // max factor dist
    const float d1 = 60.0f; // min factor dist
    float tessFactor = 2.0f + ((25.0f - 2.0f) * saturate((d1 - d) / (d1 - d0)));
    
    HS_Input output;
    output.positionW = pos.xyz;
    output.normal = normalize(mul(input.normal, (float3x3) gModel));
    output.tangent = normalize(mul(input.tangent, (float3x3) gModel));
    output.binormal = normalize(mul(input.binormal, (float3x3) gModel));
    output.textcoord = input.textcoord;
    output.tessFactor = tessFactor;
    
    return output;
}