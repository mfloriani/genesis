struct GS_INPUT
{
    float4 positionH : SV_POSITION;
    float3 positionW : WORLDPOS;
    float3 normal : NORMAL;
    float3 tangent : TANGENT;
    float3 binormal : BINORMAL;
    float2 uv : TEXCOORD;
    float3 camViewDir : TEXCOORD1;
};

struct GS_OUTPUT
{
    float4 positionH : SV_POSITION;
    float3 positionW : WORLDPOS;
    float3 normal : NORMAL;
    float3 tangent : TANGENT;
    float3 binormal : BINORMAL;
    float2 uv : TEXCOORD;
    float3 camViewDir : TEXCOORD1;
};

float3 calcNormal(float3 a, float3 b, float3 c)
{
    return normalize(cross(b - a, c - a));
}

float3 calcTangent(float3 v1, float3 v2, float2 tuVector, float2 tvVector)
{
    float3 tangent;
    float den = 1.0f / (tuVector.x * tvVector.y - tuVector.y * tvVector.x);

    tangent.x = (tvVector.y * v1.x - tvVector.x * v2.x) * den;
    tangent.y = (tvVector.y * v1.y - tvVector.x * v2.y) * den;
    tangent.z = (tvVector.y * v1.z - tvVector.x * v2.z) * den;

    float length = sqrt(tangent.x * tangent.x + tangent.y * tangent.y + tangent.z * tangent.z);

    tangent.x = tangent.x / length;
    tangent.y = tangent.y / length;
    tangent.z = tangent.z / length;

    return tangent;
}

float3 calcBinormal(float3 v1, float3 v2, float2 tuVector, float2 tvVector)
{
    float3 binormal;
    float den = 1.0f / (tuVector.x * tvVector.y - tuVector.y * tvVector.x);

    binormal.x = (tuVector.x * v2.x - tuVector.y * v1.x) * den;
    binormal.y = (tuVector.x * v2.y - tuVector.y * v1.y) * den;
    binormal.z = (tuVector.x * v2.z - tuVector.y * v1.z) * den;

    float length = sqrt(binormal.x * binormal.x + binormal.y * binormal.y + binormal.z * binormal.z);

    binormal.x = binormal.x / length;
    binormal.y = binormal.y / length;
    binormal.z = binormal.z / length;

    return binormal;
}

[maxvertexcount(3)]
void main(triangle GS_INPUT input[3] : SV_POSITION, inout TriangleStream<GS_OUTPUT> output)
{
    for (uint i = 0; i < 3; i++)
    {
        GS_OUTPUT element;
        element.positionH = input[i].positionH;
        element.positionW = input[i].positionW;
        element.camViewDir = input[i].camViewDir;
        element.normal = calcNormal(input[0].positionH.xyz, input[1].positionH.xyz, input[2].positionH.xyz);

        float3 v1 = input[1].positionH.xyz - input[0].positionH.xyz;
        float3 v2 = input[2].positionH.xyz - input[0].positionH.xyz;

        float2 tuVector, tvVector;
        tuVector.x = input[1].uv.x - input[0].uv.x;
        tvVector.x = input[1].uv.y - input[0].uv.y;
        tuVector.y = input[2].uv.x - input[0].uv.x;
        tvVector.y = input[2].uv.y - input[0].uv.y;

        element.tangent = normalize(calcTangent(v1, v2, tuVector, tvVector));
        element.binormal = normalize(calcBinormal(v1, v2, tuVector, tvVector));

        element.uv = input[i].uv;
		
        output.Append(element);
    }
}