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
    float3 gCamEye;
    float padding;
};

struct DS_OUTPUT
{
	float4 positionH  : SV_POSITION;
    float3 positionW : WORLDPOS;
    float3 normal : NORMAL;
    float3 tangent : TANGENT;
    float3 binormal : BINORMAL;
    float2 textcoord : TEXCOORD;
    float3 camViewDir : TEXCOORD1;
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

float hash(float n)
{
    return frac(sin(n) * 43758.5453);
}


float noise(float3 x)
{
    float3 p = floor(x);
    float3 f = frac(x);

    f = f * f * (3.0 - 2.0 * f);
    float n = p.x + p.y * 57.0 + 113.0 * p.z;

    return lerp(lerp(lerp(hash(n + 0.0), hash(n + 1.0), f.x),
		lerp(hash(n + 57.0), hash(n + 58.0), f.x), f.y),
		lerp(lerp(hash(n + 113.0), hash(n + 114.0), f.x),
			lerp(hash(n + 170.0), hash(n + 171.0), f.x), f.y), f.z);
}

float rand(float2 co)
{
    return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
}


[domain("tri")]
DS_OUTPUT main(
	HS_CONSTANT_DATA_OUTPUT input,
	float3 domain : SV_DomainLocation,
	const OutputPatch<HS_CONTROL_POINT_OUTPUT, NUM_CONTROL_POINTS> patch)
{
	DS_OUTPUT Output;
	
    Output.positionW = domain.x * patch[0].positionW + domain.y * patch[1].positionW + domain.z * patch[2].positionW;
    Output.positionW = normalize(Output.positionW);
    
    Output.normal = domain.x * patch[0].normal + domain.y * patch[1].normal + domain.z * patch[2].normal;
    Output.normal = normalize(Output.normal);
    
    Output.tangent = domain.x * patch[0].tangent + domain.y * patch[1].tangent + domain.z * patch[2].tangent;
    Output.tangent = normalize(Output.tangent);
    
    Output.binormal = domain.x * patch[0].binormal + domain.y * patch[1].binormal + domain.z * patch[2].binormal;
    Output.binormal = normalize(Output.binormal);
    
    Output.textcoord = domain.x * patch[0].textcoord + domain.y * patch[1].textcoord + domain.z * patch[2].textcoord;
    //Output.textcoord = normalize(Output.textcoord);
    
    float height = rand(Output.positionW.xy);
    //float height = noise(Output.positionW);
    Output.positionW += Output.normal * height * 0.2;
    
    Output.camViewDir = normalize(gCamEye - Output.positionW);
    
    float4 pos = float4(Output.positionW, 1);
    pos = mul(pos, gModel);
    pos = mul(pos, gView);
    pos = mul(pos, gProj);
    
    Output.positionH = pos;
	
	return Output;
}
