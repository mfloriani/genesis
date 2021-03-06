// A constant buffer that stores the three basic column-major matrices for composing geometry.
cbuffer ModelViewProjCB : register(b0)
{
    matrix gModel;
    matrix gView;
    matrix gProj;
    matrix gInvView;
};

cbuffer PerFrameCB : register(b1)
{
    float3 eye;
    float  pad1;
    float  time;
    float3 pad2;
    float3 posW;
    float  pad3;
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
    
    float d = distance(posW, eye);
    const float d0 = 1.0f; // max factor dist
    const float d1 = 5.f; // min factor dist
    float tessFactor = 1.0f + ((64.0f - 1.0f) * saturate((d1 - d) / (d1 - d0)));
    
    HS_Input output;
    output.positionL = pos.xyz;
    output.tessFactor = tessFactor;
    
    return output;
}