// A constant buffer that stores the three basic column-major matrices for composing geometry.
cbuffer ModelViewProjCB : register(b0)
{
    matrix gModel;
    matrix gView;
    matrix gProj;
    matrix gInvView;
};



float4 main(float4 inPos : POSITION) : SV_POSITION
{
    float4 pos = inPos;
    
    pos = mul(pos, gModel);
    pos = mul(pos, gView);
    pos = mul(pos, gProj);
    
    return pos;
}