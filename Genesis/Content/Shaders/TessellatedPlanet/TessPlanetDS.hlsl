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
	float4 vPositionH  : SV_POSITION;
    //float4 vPositionW : WORLDPOS;
};

// Output control point
struct HS_CONTROL_POINT_OUTPUT
{
	float3 vPosition : WORLDPOS;
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
	
    float3 p = domain.x * patch[0].vPosition + domain.y * patch[1].vPosition + domain.z * patch[2].vPosition;
    p = normalize(p);
    
    float4 pos = float4(p, 1);
	
    pos = mul(pos, gModel);
    pos = mul(pos, gView);
    pos = mul(pos, gProj);
	
    Output.vPositionH = pos;
	//Output.Color = float4(domain.yx, 1 - domain.x, 1);
	
	return Output;
}
