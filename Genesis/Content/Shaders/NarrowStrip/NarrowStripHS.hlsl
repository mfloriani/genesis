#define NUM_CONTROL_POINTS 3

// Input control point
struct HS_Input
{
    float3 position : WORLDPOS;
    float tess : TESS;
};

// Output control point
struct HS_Output
{
    float3 position : WORLDPOS;
};

// Output patch constant data.
struct HS_CONSTANT_DATA_OUTPUT
{
    float EdgeTessFactor[3] : SV_TessFactor;
    float InsideTessFactor : SV_InsideTessFactor;
};

// Patch Constant Function
HS_CONSTANT_DATA_OUTPUT CalcHSPatchConstants(
	InputPatch<HS_Input, NUM_CONTROL_POINTS> ip,
	uint PatchID : SV_PrimitiveID)
{
    HS_CONSTANT_DATA_OUTPUT Output;
	
    Output.EdgeTessFactor[0] =
	    Output.EdgeTessFactor[1] = 
	        Output.EdgeTessFactor[2] = ip[0].tess;
    
    Output.InsideTessFactor = Output.EdgeTessFactor[0];

    return Output;
}

[domain("tri")]
[partitioning("fractional_odd")]
[outputtopology("triangle_cw")]
[outputcontrolpoints(NUM_CONTROL_POINTS)]
[patchconstantfunc("CalcHSPatchConstants")]
[maxtessfactor(64.0f)]
HS_Output main(
	InputPatch<HS_Input, NUM_CONTROL_POINTS> ip,
	uint i : SV_OutputControlPointID,
	uint PatchID : SV_PrimitiveID)
{
    HS_Output Output;
    Output.position = ip[i].position;
    return Output;
}
