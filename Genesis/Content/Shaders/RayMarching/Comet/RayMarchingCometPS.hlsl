cbuffer ModelViewProjCB : register(b0)
{
    matrix model;
    matrix view;
    matrix projection;
    matrix invView;
}

cbuffer PerFrameCB : register(b1)
{
    float3 eye;
    float pad1;
    float time;
    float3 pad2;
    float3 posW;
    float pad3;
};

struct VS_Quad
{
    float4 position : SV_POSITION;
    float2 canvasXY : TEXCOORD0;
};

#define ITR 35
#define FAR 15.

float2x2 mm2(in float a)
{
    float c = cos(a), s = sin(a);
    return float2x2(c, s, -s, c);
}

float3 objmov(float3 p)
{
    p.xz = mul(mm2(3.4), p.xz);
    p.yz = mul(mm2(2.7), p.yz);
    return p;
}

float tri(in float x)
{
    return abs(frac(x) - 0.5) - .25;
}
float trids(in float3 p)
{
    return max(tri(p.z), min(tri(p.x), tri(p.y)));
}
float tri2(in float x)
{
    return abs(frac(x) - .5);
}
float3 tri3(in float3 p)
{
    return float3(tri(p.z + tri(p.y * 1.0)), tri(p.z + tri(p.x * 1.05)), tri(p.y + tri(p.x * 1.1)));
}

static float2x2 m2 = float2x2(0.970, 0.242, -0.242, 0.970);
float triNoise3d(in float3 p, in float spd)
{
    float z = 1.45;
    float rz = 0.;
    float3 bp = p;
    for (float i = 0.; i < 4.; i++)
    {
        float3 dg = tri3(bp);
        p += (dg + time * spd + 10.1);
        bp *= 1.65;
        z *= 1.5;
        p *= .9;
        p.xz = mul(m2, p.xz);
        
        rz += (tri2(p.z + tri2(p.x + tri2(p.y)))) / z;
        bp += 0.9;
    }
    return rz;
}

float map(float3 p)
{
    p *= 1.5;
    p = objmov(p);
    float d = length(p) - 1.;
    d -= trids(p * 1.2) * .2;
    return d / 1.5;
}

float map2(float3 p)
{
    p = objmov(p);
    return length(p) - 1.3;
}

float march(in float3 ro, in float3 rd)
{
    float precis = 0.001;
    float h = precis * 2.0;
    float d = 0.;
    for (int i = 0; i < ITR; i++)
    {
        if (abs(h) < precis || d > FAR)
            break;
        d += h;
        float res = map(ro + rd * d);
        h = res;
    }
    return d;
}

float3 normal(const in float3 p)
{
    float2 e = float2(-1., 1.) * 0.04;
    return normalize(e.yxx * map(p + e.yxx) + e.xxy * map(p + e.xxy) +
					 e.xyx * map(p + e.xyx) + e.yyy * map(p + e.yyy));
}

float gradm(in float3 p)
{
    float e = .06;
    float d = map2(float3(p.x, p.y - e, p.z)) - map2(float3(p.x, p.y + e, p.z));
    d += map2(float3(p.x - e, p.y, p.z)) - map2(float3(p.x + e, p.y, p.z));
    d += map2(float3(p.x, p.y, p.z - e)) - map2(float3(p.x, p.y, p.z + e));
    return d;
}

//Main fireball
float mapVol(float3 p, in float spd)
{
    float f = smoothstep(0.0, 1.25, 1.7 - (p.y + dot(p.xz, p.xz) * .62));
    float g = p.y;
    p.y *= .27;
    p.z += gradm(p * 0.73) * 3.5;
    p.y += time * 6.;
    float d = triNoise3d(p * float3(0.3, 0.27, 0.3) - float3(0, time * .0, 0), spd * 0.7) * 1.4 + 0.1;
    d += max((g - 0.) * 0.3, 0.);
    d *= f;
    
    return clamp(d, 0., 1.);
}

float3 marchVol(in float3 ro, in float3 rd, in float t, in float mt)
{
    float4 rz = (float4) (0);
    t -= (dot(rd, float3(0, 1, 0)) + 1.);
    float tmt = t + 15.;
    for (int i = 0; i < 25; i++)
    {
        if (rz.a > 0.99)
            break;

        float3 pos = ro + t * rd;
        float r = mapVol(pos, .1);
        float gr = clamp((r - mapVol(pos + float3(.0, .7, 0.0), .1)) / .3, 0., 1.);
        float3 lg = float3(0.72, 0.28, .0) * 1.2 + 1.3 * float3(0.55, .77, .9) * gr;
        float4 col = float4(lg, r * r * r * 2.5);
        col *= smoothstep(t - 0.0, t + 0.2, mt);
        
        pos.y *= .7;
        pos.zx *= ((pos.y - 5.) * 0.15 - 0.4);
        float z2 = length(float3(pos.x, pos.y * .75 - .5, pos.z)) - .75;
        col.a *= smoothstep(.4, 1.2, .7 - map2(float3(pos.x, pos.y * .17, pos.z)));
        col.rgb *= col.a;
        rz = rz + col * (1. - rz.a);
		
        t += abs(z2) * .1 + 0.12;
        if (t > mt || t > tmt)
            break;
    }
	
    rz.g *= rz.w * 0.9 + 0.12;
    rz.r *= rz.w * 0.5 + 0.48;
    return clamp(rz.rgb, 0.0, 1.0);
}

// "Particles"
float mapVol2(float3 p, in float spd)
{
    p *= 1.3;
    float f = smoothstep(0.2, 1.0, 1.3 - (p.y + length(p.xz) * 0.4));
    p.y *= .05;
    p.y += time * 1.7;
    float d = triNoise3d(p * 1.1, spd);
    d = clamp(d - 0.15, 0.0, 0.75);
    d *= d * d * d * d * 47.;
    d *= f;
    
    return d;
}

float3 marchVol2(in float3 ro, in float3 rd, in float t, in float mt)
{
    
    float3 bpos = ro + rd * t;
    t += length(float3(bpos.x, bpos.y, bpos.z)) - 1.;
    t -= dot(rd, float3(0, 1, 0));
    float4 rz = (float4) (0);
    float tmt = t + 1.5;
    for (int i = 0; i < 25; i++)
    {
        if (rz.a > 0.99)
            break;

        float3 pos = ro + t * rd;
        float r = mapVol2(pos, .01);
        float3 lg = float3(0.7, 0.3, .2) * 1.5 + 2. * float3(1, 1, 1) * 0.75;
        float4 col = float4(lg, r * r * r * 3.);
        col *= smoothstep(t - 0.25, t + 0.2, mt);
        
        float z2 = length(float3(pos.x, pos.y * .9, pos.z)) - .9;
        col.a *= smoothstep(.7, 1.7, 1. - map2(float3(pos.x * 1.1, pos.y * .4, pos.z * 1.1)));
        col.rgb *= col.a;
        rz = rz + col * (1. - rz.a);
		
        t += z2 * .015 + abs(.35 - r) * 0.09;
        if (t > mt || t > tmt)
            break;
        
    }
	
    return clamp(rz.rgb, 0.0, 1.0);
}

float3 hash33(float3 p)
{
    p = frac(p * float3(443.8975, 397.2973, 491.1871));
    p += dot(p.zxy, p.yxz + 19.27);
    return frac(float3(p.x * p.y, p.z * p.x, p.y * p.z));
}

float curv(in float3 p, in float w)
{
    float2 e = float2(-1., 1.) * w;
    float t1 = map(p + e.yxx), t2 = map(p + e.xxy);
    float t3 = map(p + e.xyx), t4 = map(p + e.yyy);
    return 1.0 / e.y * (t1 + t2 + t3 + t4 - 4. * map(p));
}

float4 main(VS_Quad input) : SV_TARGET
{
    
    float2 p = input.canvasXY.xy;
    float2 mo = float2(4.7, 1.31);
    const float roz = 7.3;
    float3 ro = float3(-1.5, 0.5, roz);
    float3 rd = normalize(float3(p, -1.5));
    mo.x += sin(time*0.3 + sin(time*0.05))*0.03+0.03;
    mo.y += sin(time*0.4 + sin(time*0.06))*0.03;
    float2x2 mx = mm2(mo.x * 6.);
    float2x2 my = mm2(mo.y * 6.);
    ro.xz = mul(mx, ro.xz);
    rd.xz = mul(mx, rd.xz);
    ro.xy = mul(my, ro.xy);
    rd.xy = mul(my, rd.xy);
    
    float rz = march(ro, rd);
    float3 col = (float3) (0.);
    float maxT = rz;
    if (rz > FAR)
        maxT = 25.;
    
    float3 mv = marchVol(ro, rd, roz - 1.5, maxT);
    
    if (rz < FAR)
    {
        float3 pos = ro + rz * rd;
        float3 nor = normal(pos);
        float crv = clamp(curv(pos, 0.3) * 0.35, 0., 1.3);
        
        float3 col2 = float3(1, 0.1, 0.02) * (crv * 0.8 + 0.2) * 0.5;
        float frict = dot(pos, normalize(float3(0., 1., 0.)));
        col = col2 * (frict * 0.3 + 0.7);
        
        col += float3(1, 0.3, 0.1) * (crv * 0.7 + 0.3) * max((frict * 0.5 + 0.5), 0.) * 1.3;
        col += float3(.8, 0.8, .5) * (crv * 0.9 + 0.1) * pow(max(frict, 0.), 1.5) * 1.9;
        pos = objmov(pos);
        
        col *= 1.2 - mv;
        col *= triNoise3d(pos*2.8,0.)*0.25+0.45;
        col = pow(col, float3(1.5, 1.2, 1.2)) * .9;
    }
    col += mv;
    col += marchVol2(ro,rd, roz-5.5,rz);
    col = pow(col, (float3) (1.4)) * 1.1;
    
    return float4(col, 1.0);
}
