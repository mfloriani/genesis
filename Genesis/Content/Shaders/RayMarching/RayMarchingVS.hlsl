cbuffer ModelViewProjCB : register(b0)
{
    matrix model;
    matrix view;
    matrix projection;
    matrix invView;
};

struct PS_Input
{
    float4 position : SV_POSITION;
    float2 canvasXY : TEXCOORD0;
};

PS_Input main(float4 pos : POSITION)
{
    PS_Input output;
    output.position = float4(sign(pos.xy), 0, 1);

    float aspectRatio = projection._m00 / projection._m11;
    output.canvasXY = sign(pos.xy) * float2(1.0, aspectRatio);

    return output;
}