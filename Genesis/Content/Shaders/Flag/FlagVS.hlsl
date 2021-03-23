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
    float padding;
};

cbuffer ObjectCB : register(b2)
{
    float3 gCenterPosW;
    float padding2;
};

struct VS_Input
{
    float3 positionL : POSITION;
};

struct HS_Input
{
    float3 positionL : WORLDPOS;
    float tessFactor : TESS;
};

#define MAX_TESS_FACTOR 64

HS_Input main(VS_Input input)
{
    float4 pos = float4(input.positionL, 1.0);
    //float3 posW = mul(pos, gModel).xyz;
    
    float d = distance(gCenterPosW, gCamEye);
    const float d0 = 10.0f; // max factor dist
    const float d1 = 50.0f; // min factor dist
    float tessFactor = 1.0f + ((64.0f - 5.0f) * saturate((d1 - d) / (d1 - d0)));
    
    HS_Input output;
    output.positionL = pos.xyz;
    output.tessFactor = tessFactor;
    
    return output;
}