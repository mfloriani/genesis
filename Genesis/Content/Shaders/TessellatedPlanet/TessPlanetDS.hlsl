// A constant buffer that stores the three basic column-major matrices for composing geometry.
cbuffer ModelViewProjCB : register(b0)
{
    matrix gModel;
    matrix gView;
    matrix gProj;
    matrix gInvView;
};

struct DS_OUTPUT
{
	float4 positionH  : SV_POSITION;
    float3 positionW : WORLDPOS;
    float3 normal : NORMAL;
    float3 tangent : TANGENT;
    float3 binormal : BINORMAL;
    float2 textcoord : TEXCOORD;
    float tessFactor : TESS;
};

// Output control point
struct HS_CONTROL_POINT_OUTPUT
{
    float3 positionW : WORLDPOS;
    float3 normal : NORMAL;
    float3 tangent : TANGENT;
    float3 binormal : BINORMAL;
    float2 textcoord : TEXCOORD;
    float tessFactor : TESS;
    
};

// Output patch constant data.
struct HS_CONSTANT_DATA_OUTPUT
{
	float EdgeTessFactor[3]	: SV_TessFactor; // e.g. would be [4] for a quad domain
	float InsideTessFactor	: SV_InsideTessFactor; // e.g. would be Inside[2] for a quad domain
};

#define NUM_CONTROL_POINTS 3

static float PI = 3.14159265359;

[domain("tri")]
DS_OUTPUT main(
	HS_CONSTANT_DATA_OUTPUT input,
	float3 domain : SV_DomainLocation,
	const OutputPatch<HS_CONTROL_POINT_OUTPUT, NUM_CONTROL_POINTS> patch)
{
	DS_OUTPUT Output;
	
    float3 p = domain.x * patch[0].positionW + domain.y * patch[1].positionW + domain.z * patch[2].positionW;
    p = normalize(p);
    
    //Output.normal = domain.x * patch[0].normal + domain.y * patch[1].normal + domain.x * patch[2].normal;
    //Output.normal = normalize(Output.normal);
    
    Output.normal = normalize(patch[0].normal);
    
    float4 pos = float4(p, 1);	
    pos = mul(pos, gModel);
    pos = mul(pos, gView);
    pos = mul(pos, gProj);
    
    Output.positionH = pos;
	//Output.Color = float4(domain.yx, 1 - domain.x, 1);
	
	return Output;
}
