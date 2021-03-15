// A constant buffer that stores the three basic column-major matrices for composing geometry.
cbuffer ViewProjCB : register(b0)
{
	matrix gModel;
	matrix gView;
	matrix gProj;
	matrix gInvView;
};

struct VSInput
{
	float4 pos : SV_POSITION;
};

struct GSOutput
{
	float4 pos : SV_POSITION;
	float2 uv  : TEXCOORD0;
};

static float3 gQuadPos[4] =
{
    float3(-1, 1, 0),
    float3(1, 1, 0),
    float3(-1, -1, 0),
    float3(1, -1, 0),
};

static float2 gQuadUV[4] =
{
    float2(0,0),
    float2(1,0),
    float2(0,1),
    float2(1,1),
};

static float gQuadSize = 0.1;

[maxvertexcount(4)]
void main(
	point VSInput input[1] : SV_POSITION,
	inout TriangleStream< GSOutput > outputStream
)
{
	for (uint i = 0; i < 4; i++)
	{	
		float3 pos = gQuadPos[i] * gQuadSize;
		pos = mul(pos, (float3x3)gInvView) + input[0].pos.xyz;
		
		GSOutput v;
		v.pos = float4(pos, 1.0);
		v.pos = mul(v.pos, gView);
		v.pos = mul(v.pos, gProj);
		
		v.uv = gQuadUV[i];

		outputStream.Append(v);
	}
}