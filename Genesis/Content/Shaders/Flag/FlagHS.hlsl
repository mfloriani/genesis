#define NUM_CONTROL_POINTS 16

// Input control point
struct VS_Output
{
    float3 positionL : WORLDPOS;
    float tessFactor : TESS;
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



// Patch Constant Function
HS_CONSTANT_DATA_OUTPUT CalcHSPatchConstants(
	InputPatch<VS_Output, NUM_CONTROL_POINTS> ip,
	uint PatchID : SV_PrimitiveID)
{
    HS_CONSTANT_DATA_OUTPUT Output;
	
    Output.EdgeTessFactor[0] =
		Output.EdgeTessFactor[1] =
		Output.EdgeTessFactor[2] =
		Output.EdgeTessFactor[3] =
		Output.InsideTessFactor[0] =
        Output.InsideTessFactor[1] = ip[0].tessFactor;

    return Output;
}

[domain("quad")]
[partitioning("integer")]
[outputtopology("triangle_cw")]
[outputcontrolpoints(NUM_CONTROL_POINTS)]
[patchconstantfunc("CalcHSPatchConstants")]
[maxtessfactor(64.0f)]
HS_Output main(
	InputPatch<VS_Output, NUM_CONTROL_POINTS> ip,
	uint i : SV_OutputControlPointID,
	uint PatchID : SV_PrimitiveID)
{
    HS_Output Output;

	// Insert code to compute Output here
    Output.positionL = ip[i].positionL;

    return Output;
}
