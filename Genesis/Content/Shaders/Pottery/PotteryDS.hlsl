#define NUM_CONTROL_POINTS 16

// A constant buffer that stores the three basic column-major matrices for composing geometry.
cbuffer ModelViewProjCB : register(b0)
{
    matrix gModel;
    matrix gView;
    matrix gProj;
    matrix gInvView;
};

cbuffer PerFrameCB : register(b1)
{
    float3 eye;
    float  pad1;
    float  time;
    float3 pad2;
    float3 posW;
    float  pad3;
};

struct DS_OUTPUT
{
    float4 positionH : SV_POSITION;
    float3 positionW : POSITION;
    float3 camViewDir : TEXCOORD1;
    float2 uv : TEXCOORD2;
};

// Output control point
struct HS_Output
{
    float3 position : WORLDPOS;
};

// Output patch constant data.
struct HS_CONSTANT_DATA_OUTPUT
{
    float EdgeTessFactor[4] : SV_TessFactor;
    float InsideTessFactor[2] : SV_InsideTessFactor;
};

float4 BernsteinBasis(float t)
{
    float invT = 1.0f - t;
    return float4( invT * invT * invT,
                   3.0f * t * invT * invT,
                   3.0f * t * t * invT,
                   t * t * t);
}

float3 CubicBezierSum(const OutputPatch<HS_Output, NUM_CONTROL_POINTS> patch, float4 basisU, float4 basisV)
{
    float3 sum = float3(0.0f, 0.0f, 0.0f);
    sum = basisV.x * (basisU.x * patch[0].position + basisU.y * patch[1].position + basisU.z * patch[2].position + basisU.w * patch[3].position);
    sum += basisV.y * (basisU.x * patch[4].position + basisU.y * patch[5].position + basisU.z * patch[6].position + basisU.w * patch[7].position);
    sum += basisV.z * (basisU.x * patch[8].position + basisU.y * patch[9].position + basisU.z * patch[10].position + basisU.w * patch[11].position);
    sum += basisV.w * (basisU.x * patch[12].position + basisU.y * patch[13].position + basisU.z * patch[14].position + basisU.w * patch[15].position);

    return sum;
}

[domain("quad")]
DS_OUTPUT main(
	HS_CONSTANT_DATA_OUTPUT input,
	float2 domain : SV_DomainLocation,
	const OutputPatch<HS_Output, NUM_CONTROL_POINTS> patch)
{
    DS_OUTPUT Output;
	
    float4 basisU = BernsteinBasis(domain.x);
    float4 basisV = BernsteinBasis(domain.y);

    float3 p = CubicBezierSum(patch, basisU, basisV);
    
    Output.camViewDir = normalize(eye - p);    
    Output.uv = domain;
    
    float4 pos = float4(p, 1);
    pos = mul(pos, gModel);
    
    Output.positionW = pos;
    
    pos = mul(pos, gView);
    pos = mul(pos, gProj);
    
    Output.positionH = pos;
	
    return Output;
}
