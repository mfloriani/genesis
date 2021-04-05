cbuffer ModelViewProjCB : register(b0)
{
    matrix Model;
    matrix View;
    matrix Proj;
    matrix InvView;
};

struct VS_Input
{
    float3 position : POSITION;
};

struct VS_Output
{
    float3 position : WORLDPOS;
    float  tess : TESS;
};

VS_Output main(VS_Input input)
{
    VS_Output output;
    
    output.position = input.position;
    output.tess = 64.f;
    
    return output;
}