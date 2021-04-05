#define NUM_CONTROL_POINTS 3

// A constant buffer that stores the three basic column-major matrices for composing geometry.
cbuffer ModelViewProjCB : register(b0)
{
    matrix Model;
    matrix View;
    matrix Proj;
    matrix InvView;
};

cbuffer CameraCB : register(b1)
{
    float3 eye;
    float padding;
};

cbuffer TimeCB : register(b2)
{
    float time;
    float3 pad2;
};

struct DS_OUTPUT
{
    float4 positionH  : SV_POSITION;
    float3 positionW  : POSITION;
    float3 camViewDir : TEXCOORD1;
};

// Output control point
struct DS_Input
{
    float3 position : WORLDPOS;
};

// Output patch constant data.
struct HS_CONSTANT_DATA_OUTPUT
{
    float EdgeTessFactor[3] : SV_TessFactor;
    float InsideTessFactor : SV_InsideTessFactor;
};

float4 BernsteinBasis(float t)
{
    float invT = 1.0f - t;

    return float4(invT * invT * invT, 3.0f * t * invT * invT, 3.0f * t * t * invT, t * t * t);
}

float4 EvaluateCubicHermite(float4 basis)
{
    return float4(
			basis.x + basis.y,
			basis.y / 3.0,
			-basis.z / 3.0,
			basis.z + basis.w
	);
}

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

[domain("tri")]
DS_OUTPUT main(
	HS_CONSTANT_DATA_OUTPUT input,
	float3 domain : SV_DomainLocation,
	const OutputPatch<DS_Input, NUM_CONTROL_POINTS> patch)
{
    DS_OUTPUT output;
	
    float4 basis = BernsteinBasis(domain.x);
    output.positionW = EvaluateCubicHermite(basis);
    
    //output.positionW += cos(output.positionW * time);
    output.positionW += sin(output.positionW * time);
    //output.positionW += noise(output.positionW * time);
    
    output.camViewDir = normalize(eye - output.positionW);
    
    float4 pos = float4(output.positionW, 1);
    pos = mul(pos, Model);
    pos = mul(pos, View);
    pos = mul(pos, Proj);    
    output.positionH = pos;
	
    return output;
}
