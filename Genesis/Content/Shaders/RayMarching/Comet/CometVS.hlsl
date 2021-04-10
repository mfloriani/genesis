cbuffer ViewProjCB : register(b0)
{
    matrix gModel;
    matrix gView;
    matrix gProj;
    matrix gInvView;
};

float4 main( float4 pos : POSITION ) : SV_POSITION
{
    return mul(pos, gModel);
}