cbuffer ViewProjCB : register(b0)
{
    matrix gModel;
    matrix gView;
    matrix gProj;
    matrix gInvView;
};

struct GS_Input
{
    float4 pos : SV_POSITION;
};

struct GS_Output
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
};

static float3 QuadPos[4] =
{
    float3(-1, 1, 0),
    float3(1, 1, 0),
    float3(-1, -1, 0),
    float3(1, -1, 0),
};

static float2 QuadUV[4] =
{
    float2(0, 0),
    float2(1, 0),
    float2(0, 1),
    float2(1, 1),
};

static float gQuadSize = 30.;

[maxvertexcount(4)]
void main(point GS_Input input[1] : SV_POSITION, inout TriangleStream<GS_Output> outputStream)
{
    for (uint i = 0; i < 4; i++)
    {
        float3 pos = QuadPos[i] * gQuadSize;
        pos = mul(pos, (float3x3) gInvView) + input[0].pos.xyz;
		
        GS_Output v;
        v.pos = float4(pos, 1.0);
        v.pos = mul(v.pos, gView);
        v.pos = mul(v.pos, gProj);
		
        v.uv = QuadUV[i];

        outputStream.Append(v);
    }
}