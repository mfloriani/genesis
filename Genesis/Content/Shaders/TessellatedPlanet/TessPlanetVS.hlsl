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

#define MAX_TESS_FACTOR 10

HS_Input main(VS_Input input)
{
    float4 pos = float4(input.position, 1.0);
    
    float3 posW = mul(pos, gModel);    
    float distToCam = distance(posW, gCamEye);
    
    float tessFactor = saturate(4.0 - distToCam) * 0.5;
    tessFactor = 1.0 + tessFactor * (MAX_TESS_FACTOR - 1.0);
    
    HS_Input output;
    output.positionW = pos.xyz;
    output.normal = normalize(mul(input.normal, (float3x3) gModel));
    output.tangent = normalize(mul(input.tangent, (float3x3) gModel));
    output.binormal = normalize(mul(input.binormal, (float3x3) gModel));
    output.textcoord = input.textcoord;
    output.tessFactor = tessFactor;
    
    return output;
}