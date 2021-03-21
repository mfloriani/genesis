#define NUM_CONTROL_POINTS 16

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
    float4 positionH : SV_POSITION;
    //float3 positionW : WORLDPOS;
    float3 camViewDir : TEXCOORD1;
};

// Output control point
struct HS_Output
{
    float3 positionL : WORLDPOS;
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
    sum = basisV.x * (basisU.x * patch[0].positionL + basisU.y * patch[1].positionL + basisU.z * patch[2].positionL + basisU.w * patch[3].positionL);
    sum += basisV.y * (basisU.x * patch[4].positionL + basisU.y * patch[5].positionL + basisU.z * patch[6].positionL + basisU.w * patch[7].positionL);
    sum += basisV.z * (basisU.x * patch[8].positionL + basisU.y * patch[9].positionL + basisU.z * patch[10].positionL + basisU.w * patch[11].positionL);
    sum += basisV.w * (basisU.x * patch[12].positionL + basisU.y * patch[13].positionL + basisU.z * patch[14].positionL + basisU.w * patch[15].positionL);

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
    
    Output.camViewDir = normalize(gCamEye - p);
    
    float4 pos = float4(p, 1);
    pos = mul(pos, gModel);
    pos = mul(pos, gView);
    pos = mul(pos, gProj);
    
    Output.positionH = pos;
	
    return Output;
}
