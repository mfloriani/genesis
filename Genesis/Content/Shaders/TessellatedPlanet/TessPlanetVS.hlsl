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
    float3 gCamPos;
    float  padding;
};

struct HS_Input
{
    float3 pos : WORLDPOS;
    float tess : TESS;
};

#define MAX_TESS_FACTOR 10

HS_Input main(float4 inPos : POSITION)
{
    float4 pos = inPos;
    
    float3 posW = mul(pos, gModel);    
    float distToCam = distance(posW, gCamPos);
    
    float tessFactor = saturate(5.0 - distToCam);
    tessFactor = 1.0 + tessFactor * (MAX_TESS_FACTOR - 1.0);
    
    HS_Input output;
    output.pos = pos.xyz;
    output.tess = tessFactor;
    
    return output;
}