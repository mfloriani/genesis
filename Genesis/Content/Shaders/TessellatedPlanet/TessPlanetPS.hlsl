struct PS_Input
{
    float4 positionH : SV_POSITION;
    float3 positionW : WORLDPOS;
    float3 normal : NORMAL;
    float3 tangent : TANGENT;
    float3 binormal : BINORMAL;
    float2 textcoord : TEXCOORD;
    float3 camViewDir : TEXCOORD1;
};

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

static float3 gLightDir = float3(0.0, 1.0, 1.0);
static float4 gLightAmb = float4(0.3, 0.3, 0.3, 1.0);
static float4 gLightDiff = float4(1.0, 0.0, 0.0, 1.0);

static float3 gLightDir2 = float3(0.0, 0.0, -1.0);
static float4 gLightAmb2 = float4(0.3, 0.3, 0.3, 1.0);
static float4 gLightDiff2 = float4(0.0, 1.0, 0.0, 1.0);

float4 Shading( float3 normal, float3 toCamEye )
{
    float4 ambient = (float4) 0;
    float4 diffuse = (float4) 0;
    float4 specular = (float4) 0;
    
    {
        ambient += float4(0.5, 0.5, 0.5, 1.0) * gLightAmb;
        float3 lightDir = normalize(-gLightDir);
        float diffFactor = dot(lightDir, normal);
        if (diffFactor > 0.0f)
            diffuse += diffFactor * float4(0.4, 0.4, 0.4, 1.0) * gLightDiff;
    }
    
    
    {
        ambient += float4(0.5, 0.5, 0.5, 1.0) * gLightAmb2;
        float3 lightDir = normalize(-gLightDir2);
        float diffFactor = dot(lightDir, normal);
        if (diffFactor > 0.0f)
            diffuse += diffFactor * float4(0.4, 0.4, 0.4, 1.0) * gLightDiff2;
    }
    return ambient + diffuse + specular;

}

float4 main(PS_Input input) : SV_TARGET
{
    float3 normal = normalize(input.normal);
    return Shading(normal, input.camViewDir);
}