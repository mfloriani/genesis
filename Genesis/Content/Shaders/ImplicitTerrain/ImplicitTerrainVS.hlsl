cbuffer ModelViewProjCB : register(b0)
{
    matrix model;
    matrix view;
    matrix projection;
    matrix invView;
};

struct VS_Output
{
    float4 position : SV_POSITION;
    float2 canvasXY : TEXCOORD0;
};

VS_Output main(float4 pos : POSITION)
{
    VS_Output output;

    float aspectRatio = projection._m00 / projection._m11;
    output.canvasXY = sign(pos.xy) * float2(1.0, aspectRatio);
    output.position = float4(sign(pos.xy), 0, 1);

    return output;
}