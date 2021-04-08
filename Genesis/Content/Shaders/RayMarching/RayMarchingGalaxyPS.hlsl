cbuffer ModelViewProjCB : register(b0)
{
    matrix model;
    matrix view;
    matrix projection;
    matrix invView;
}

cbuffer CameraCB : register(b1)
{
    float3 eye;
    float pad;
};

cbuffer TimeCB : register(b2)
{
    float time;
    float3 pad2;
};

struct VS_Quad
{
    float4 position : SV_POSITION;
    float2 canvasXY : TEXCOORD0;
};

float4 main(VS_Quad input) : SV_TARGET
{
    float3 ro = mul(float4(0, 0, 0, 1.0f), invView).xyz;
    float3 pixelPos = float3(input.canvasXY, -1);
    float3 rd = normalize(mul(float4(pixelPos, 0.0f), invView)).xyz;
    
    
    float t = time * .1 + ((.25 + .05 * sin(time * .1)) / (length(input.canvasXY) + .07)) * 2.2;
    float si = sin(t);
    float co = cos(t);
    float2x2 ma = float2x2(co, si, -si, co);

    float v1, v2, v3;
    v1 = v2 = v3 = 0.0;
	
    float s = 0.0;
    for (int i = 0; i < 90; i++)
    {
        float3 p = s * float3(input.canvasXY, 0.0);
        p.xy = mul(ma, p.xy);
        p += float3(.22, .3, s - 1.5 - sin(time * .13) * .1);
        for (int i = 0; i < 8; i++)
            p = abs(p) / dot(p, p) - 0.659;
        v1 += dot(p, p) * .0015 * (1.8 + sin(length(input.canvasXY * 13.0) + .5 - time * .2));
        v2 += dot(p, p) * .0013 * (1.5 + sin(length(input.canvasXY * 14.5) + 1.2 - time * .3));
        v3 += length(p.xy * 10.) * .0003;
        s += .035;
    }
	
    float len = length(input.canvasXY);
    v1 *= smoothstep(.7, .0, len);
    v2 *= smoothstep(.5, .0, len);
    v3 *= smoothstep(.9, .0, len);
	
    float3 col = float3(v3 * (1.5 + sin(time * .2) * .4),
					(v1 + v3) * .3,
					 v2) + smoothstep(0.2, .0, len) * .85 + smoothstep(.0, .6, v3) * .3;

    return float4(min(pow(abs(col), (float3)1.2), 1.0), 1.0);
    
}