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

Texture2D NoiseTexture0 : register(t0);
Texture2D NoiseTexture1 : register(t1);
Texture2D NoiseTexture2 : register(t2);

SamplerState SamplerTex : register(s0);

struct VS_Quad
{
    float4 position : SV_POSITION;
    float2 canvasXY : TEXCOORD0;
};


#if 1


// Re-entry by nimitz (twitter: @stormoid)
// https://www.shadertoy.com/view/4dGyRh
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

#define ITR 35
#define FAR 15.
//#define time iTime

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

float2x2 m2 = float2x2(0.970, 0.242, -0.242, 0.970);
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
#if 1
    t -= (dot(rd, float3(0, 1, 0)) + 1.);
#endif
    float tmt = t + 15.;
    for (int i = 0; i < 25; i++)
    {
        if (rz.a > 0.99)
            break;

        float3 pos = ro + t * rd;
        float r = mapVol(pos, .1);
        float gr = clamp((r - mapVol(pos + float3(.0, .7, 0.0), .1)) / .3, 0., 1.);
        float3 lg = float3(0.72, 0.28, .0) * 1.2 + 1.3 * float3(0.55, .77, .9) * gr;
        float4 col = float4(lg, r * r * r * 2.5); //Could increase this to simulate entry
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

// MIT Licensed hash From Dave_Hoskins (https://www.shadertoy.com/view/4djSRW)
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
    /*
    float3 ro = mul(float4(0, 0, 0, 1.0f), invView).xyz;
    float3 pixelPos = float3(input.canvasXY, -5);
    float3 rd = normalize(mul(float4(pixelPos, 0.0f), invView)).xyz;
    
    float2 mo = float2(-0.27, 0.31);
    //mo.x += sin(time * 0.3 + sin(time * 0.05)) * 0.03 + 0.03;
    //mo.y += sin(time * 0.4 + sin(time * 0.06)) * 0.03;
    float2x2 mx = mm2(mo.x * 6.);
    float2x2 my = mm2(mo.y * 6.);
    //ro.xz = mul(mx, ro.xz);
    //rd.xz = mul(mx, rd.xz);
    ro.xy = mul(my, ro.xy);
    rd.xy = mul(my, rd.xy);
    
    const float roz = 7.3;
    */
    
    //float2 iResolution = float2(1200, 900);
    
    float2 p = input.canvasXY.xy;// / iResolution.xy - 0.5;
    //p.x *= iResolution.x / iResolution.y;
    float2 mo; // = iMouse.xy / iResolution.xy-.5;
    mo = float2(4.7, 1.31);
    //mo.x *= iResolution.x / iResolution.y;
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
    
    float rz = march(ro, rd); //march geometry
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
        //pos = objmov(pos);
        
        col *= 1.2 - mv;
        //col *= triNoise3d(pos*2.8,0.)*0.25+0.45;
        col = pow(col, float3(1.5, 1.2, 1.2)) * .9;
    }
    col += mv;
    //col += marchVol2(ro,rd, roz-5.5,rz);
	//col = pow(col,float3(1.4))*1.1;
    
    return float4(col, 1.0);
}







#elif 0


static float distFactor = 5.5;

float2 rotate(float2 uv, float angle)
{
    float s = sin(angle);
    float c = cos(angle);
    return mul(uv, float2x2(c, s, -s, c));
}

float2 pp(float2 uv)
{
    float y = uv.y * 0.5 + 0.5;
    float ny = 1.5 * y;
    return float2(uv.x / 1.4 * (1.0 - ny / 3.0), ny * 2.0 - 1.5);
}

float spiral(float2 uv)
{
    float dist = 1.0 - length(uv) * distFactor;
    float d = dist * 0.6 * NoiseTexture0.Sample(SamplerTex, rotate(uv * 2.5, time * 0.1 + dist * 3.0)).x
            + dist * 0.5 * NoiseTexture0.Sample(SamplerTex, rotate(uv * 2.5, time * 0.15 + dist * 3.0)).x;
    
    for (int i = 0; i < 10; ++i)
    {
        float2 coord = uv * (1.0 - frac(time * -0.02 + float(i) * 0.089));
        coord = rotate(coord, time * 0.01 + dist * float(i) * 0.2);
        float2 tx = NoiseTexture0.Sample(SamplerTex, coord).xy;
        d += tx.x / 30.0;
        d -= tx.y / 70.0;
    }
    return d;
}

float3 star(float2 uv)
{
    const float aspect = 6.5;
    const float radius = 1.0 / aspect;
    float3 c = (float3) (0.0);
    float dist = distance(uv, float2(0, 0)) * distFactor;
    
    uv = uv * aspect;
    float r = dot(uv, uv);
    float f = (1.0 - sqrt(abs(1.0 - r))) / r;
    if (dist < radius)
    {
        float2 newUv = float2(uv.x * f, (uv.y - 0.8) * f);
        float wobble = NoiseTexture1.Sample(SamplerTex, newUv).r * 0.3;
        float uOff = (wobble - time * 0.2);
        float2 starUV = newUv + float2(uOff, 0.0);
        float3 starSphere = NoiseTexture1.Sample(SamplerTex, starUV).rgb;
        c = starSphere;
        c = float3(c.r + 1., c.g + 1., c.b + 1.1);
        c *= (1.0 - dist * aspect);
    }
    
    c = c * (uv.y * 8.0 + 0.3);
    return clamp(c, -0.03, 1.0);
}

float3 gas(float2 uv, float distort)
{
    const float3 grading1 = float3(0.15, 1.7, 1.8);
    const float3 grading2 = float3(1.0, 0.55, 0.0);
    const float3 grading3 = float3(2.5, 1.0, 1.5);
    
    float dist = (1.0 - length(uv * float2(0.6, 1.4))) * 0.01 * distFactor;
    float2 wobble = NoiseTexture1.Sample(SamplerTex, rotate(uv, time * 0.1)).rg * dist;
    
    float3 c = (float3) (spiral(pp(uv * 0.9 + wobble + distort * 0.5)));
    float3 cColor = float3(c + ((c - 0.5) * grading1) + (c * grading2) + ((atan(c) * 0.3 + 1.1) * grading3 * 0.1));
    return cColor;
}


float3 parts(float2 uv)
{
    float3 fi = NoiseTexture1.Sample(SamplerTex, rotate(pp(uv), time * 0.06)).rgb;
    float2 uv1 = pp((uv + fi.rg * 4.1) * 0.8) * 0.5;
    float2 uv2 = pp((uv) * 1.8) * 0.9;
    float dist = 1.0 - length(uv * float2(0.1, 0.2)) * distFactor;
    float d = dist * 0.63 * NoiseTexture2.Sample(SamplerTex, rotate(uv1.yy, time * 0.01 + dist * 1.0)).x
            + dist * 0.5 * NoiseTexture2.Sample(SamplerTex, rotate(uv1, time * 0.12 + dist * 1.2)).x
            + dist * 0.33 * NoiseTexture2.Sample(SamplerTex, rotate(uv2.xx, time * 0.014 + dist * 1.4)).x
            + dist * 0.7 * NoiseTexture2.Sample(SamplerTex, rotate(uv2, time * 0.16 + dist * 1.6)).x;
    float3 c = (float3) (pow(d, 8.0) * 0.2) * fi;
    return c;
}

float4 main(VS_Quad input) : SV_TARGET
{
    //float3 ro = mul(float4(0, 0, 0, 1.0f), invView).xyz;
    //float3 pixelPos = float3(input.canvasXY, -1);
    //float3 rd = normalize(mul(float4(pixelPos, 0.0f), invView)).xyz;
    
    float2 uv = input.canvasXY;//uniformCoord(input.canvasXY);
    
    float3 c1 = parts(uv);
    float3 c2 = gas(uv, c1.r);
    float3 c3 = star(uv);
    
    return float4(c1 + c2 + c3, 1.0);

}

#elif 0

// "Dusty nebula 4" by Duke
// https://www.shadertoy.com/view/MsVXWW
//-------------------------------------------------------------------------------------
// Based on "Dusty nebula 3" (https://www.shadertoy.com/view/lsVSRW) 
// and "Protoplanetary disk" (https://www.shadertoy.com/view/MdtGRl) 
// otaviogood's "Alien Beacon" (https://www.shadertoy.com/view/ld2SzK)
// and Shane's "Cheap Cloud Flythrough" (https://www.shadertoy.com/view/Xsc3R4) shaders
// Some ideas came from other shaders from this wonderful site
// Press 1-2-3 to zoom in and zoom out.
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
//-------------------------------------------------------------------------------------

//#define ROTATION
//#define MOUSE_CAMERA_CONTROL

#define DITHERING
#define BACKGROUND

//#define TONEMAPPING

//-------------------
#define pi 3.14159265
#define R(p, a) p=cos(a)*p+sin(a)*float2(p.y, -p.x)

// iq's noise
float noise(in float3 x)
{
    float3 p = floor(x);
    float3 f = frac(x);
    f = f * f * (3.0 - 2.0 * f);
    float2 uv = (p.xy + float2(37.0, 17.0) * p.z) + f.xy;
    float2 rg = NoiseTexture.Sample(SamplerTex, (uv + 0.5) / 256.0, 0.0).yx;
    return 1. - 0.82 * lerp(rg.x, rg.y, f.z);
}

float rand(float2 co)
{
    return frac(sin(dot(co * 0.123, float2(12.9898, 78.233))) * 43758.5453);
}

//=====================================
// otaviogood's noise from https://www.shadertoy.com/view/ld2SzK
//--------------------------------------------------------------
// This spiral noise works by successively adding and rotating sin waves while increasing frequency.
// It should work the same on all computers since it's not based on a hash function like some other noises.
// It can be much faster than other noise functions if you're ok with some repetition.
static const float nudge = 0.739513; // size of perpendicular vector
static float normalizer = 1.0 / sqrt(1.0 + nudge * nudge); // pythagorean theorem on that perpendicular to maintain scale
float SpiralNoiseC(float3 p)
{
    float n = 0.0; // noise amount
    float iter = 1.0;
    for (int i = 0; i < 8; i++)
    {
        // add sin and cos scaled inverse with the frequency
        n += -abs(sin(p.y * iter) + cos(p.x * iter)) / iter; // abs for a ridged look
        // rotate by adding perpendicular and scaling down
        p.xy += float2(p.y, -p.x) * nudge;
        p.xy *= normalizer;
        // rotate on other axis
        p.xz += float2(p.z, -p.x) * nudge;
        p.xz *= normalizer;
        // increase the frequency
        iter *= 1.733733;
    }
    return n;
}

float SpiralNoise3D(float3 p)
{
    float n = 0.0;
    float iter = 1.0;
    for (int i = 0; i < 5; i++)
    {
        n += (sin(p.y * iter) + cos(p.x * iter)) / iter;
        p.xz += float2(p.z, -p.x) * nudge;
        p.xz *= normalizer;
        iter *= 1.33733;
    }
    return n;
}

float NebulaNoise(float3 p)
{
    float final = p.y + 4.5;
    final -= SpiralNoiseC(p.xyz); // mid-range noise
    final += SpiralNoiseC(p.zxy * 0.5123 + 100.0) * 4.0; // large scale features
    final -= SpiralNoise3D(p); // more large scale features, but 3d

    return final;
}

float map(float3 p)
{
#ifdef ROTATION
	R(p.xz, iMouse.x*0.008*pi+time*0.1);
#endif
    
    float NebNoise = abs(NebulaNoise(p / 0.5) * 0.5);
    
    return NebNoise + 0.03;
}
//--------------------------------------------------------------

// assign color to the media
float3 computeColor(float density, float radius)
{
	// color based on density alone, gives impression of occlusion within
	// the media
    float3 result = lerp(float3(1.0, 0.9, 0.8), float3(0.4, 0.15, 0.1), density);
	
	// color added to the media
    float3 colCenter = 7. * float3(0.8, 1.0, 1.0);
    float3 colEdge = 1.5 * float3(0.48, 0.53, 0.5);
    result *= lerp(colCenter, colEdge, min((radius + .05) / .9, 1.15));
	
    return result;
}

bool RaySphereIntersect(float3 org, float3 dir, out float near, out float far)
{
    float b = dot(dir, org);
    float c = dot(org, org) - 8.;
    float delta = b * b - c;
    if (delta < 0.0) 
        return false;
    float deltasqrt = sqrt(delta);
    near = -b - deltasqrt;
    far = -b + deltasqrt;
    return far > 0.0;
}

// Applies the filmic curve from John Hable's presentation
// More details at : http://filmicgames.com/archives/75
float3 ToneMapFilmicALU(float3 _color)
{
    _color = max((float3) (0), _color - (float3) (0.004));
    _color = (_color * (6.2 * _color + (float3) (0.5))) / (_color * (6.2 * _color + (float3) (1.7)) + (float3) (0.06));
    return _color;
}

float4 main(VS_Quad input) : SV_TARGET
{
    float2 iResolution = float2(1200, 900);
    
    float3 ro = mul(float4(0, 0, 0, 1.0f), invView).xyz;
    float3 pixelPos = float3(input.canvasXY, -1);
    float3 rd = normalize(mul(float4(pixelPos, 0.0f), invView)).xyz;
    
    //const float KEY_1 = 49.5 / 256.0;
    //const float KEY_2 = 50.5 / 256.0;
    //const float KEY_3 = 51.5 / 256.0;
    //float key = 0.0;
    //key += 0.7 * NoiseTexture.Sample(SamplerTex, float2(KEY_1, 0.25)).x;
    //key += 0.7 * NoiseTexture.Sample(SamplerTex, float2(KEY_2, 0.25)).x;
    //key += 0.7 * NoiseTexture.Sample(SamplerTex, float2(KEY_3, 0.25)).x;

	// ro: ray origin
	// rd: direction of the ray
    //float3 rd = normalize(float3((gl_FragCoord.xy - 0.5 * iResolution.xy) / iResolution.y, 1.));
    //float3 ro = float3(0., 0., -6. + key * 1.6);
    
    
#ifdef MOUSE_CAMERA_CONTROL
    R(rd.yz, -iMouse.y*0.01*pi*2.);
    R(rd.xz, iMouse.x*0.01*pi*2.);
    R(ro.yz, -iMouse.y*0.01*pi*2.);
    R(ro.xz, iMouse.x*0.01*pi*2.);
#else
    R(rd.yz, -pi*3.93);
    R(rd.xz, pi*3.2);
    R(ro.yz, -pi*3.93);
   	R(ro.xz, pi*3.2);
#endif 
    
#ifdef DITHERING
    float2 dpos = (input.canvasXY.xy / iResolution.xy);
    float2 seed = dpos + frac(time);
#endif 
    
	// ld, td: local, total density 
	// w: weighting factor
    float ld = 0., td = 0., w = 0.;

	// t: length of the ray
	// d: distance function
    float d = 1., t = 0.;
    
    const float h = 0.1;
   
    float4 sum = (float4) (0.0);
   
    float min_dist = 0.0, max_dist = 0.0;

    if (RaySphereIntersect(ro, rd, min_dist, max_dist))
    {
       
        t = min_dist * step(t, min_dist);
   
	// raymarch loop
        for (int i = 0; i < 56; i++)
        {
	 
            float3 pos = ro + t * rd;
  
		// Loop break conditions.
            if (td > 0.9 || d < 0.1 * t || t > 10. || sum.a > 0.99 || t > max_dist)
                break;
	    
        // evaluate distance function
            float d = map(pos);
		       
		// change this string to control density 
            d = max(d, 0.08);
        
        // point light calculations
            float3 ldst = (float3) (0.0) - pos;
            float lDist = max(length(ldst), 0.001);

        // star in center
            float3 lightColor = float3(1.0, 0.5, 0.25);
            sum.rgb += (lightColor / (lDist * lDist) / 30.); // star itself and bloom around the light
      
            if (d < h)
            {
			// compute local density 
                ld = h - d;
            
            // compute weighting factor 
                w = (1. - td) * ld;
     
			// accumulate density
                td += w + 1. / 200.;
		
                float4 col = float4(computeColor(td, lDist), td);
		
			// uniform scale density
                col.a *= 0.185;
			// colour by alpha
                col.rgb *= col.a;
			// alpha blend in contribution
                sum = sum + col * (1.0 - sum.a);
       
            }
      
            td += 1. / 70.;
       
        // enforce minimum stepsize
            d = max(d, 0.04);
      
#ifdef DITHERING
        // add in noise to reduce banding and create fuzz
            d = abs(d) * (.8 + 0.2 * rand(seed * (float2) (i)));
#endif 
		
        // trying to optimize step size near the camera and near the light source
            t += max(d * 0.1 * max(min(length(ldst), length(ro)), 1.0), 0.02);
      
        }
    
    // simple scattering
        sum *= 1. / exp(ld * 0.2) * 0.6;
        
        sum = clamp(sum, 0.0, 1.0);
   
        sum.xyz = sum.xyz * sum.xyz * (3.0 - 2.0 * sum.xyz);
    
    }

#ifdef BACKGROUND
    // stars background
    if (td < .8)
    {
        float3 stars = (float3) (noise(rd * 500.0) * 0.5 + 0.5);
        float3 starbg = (float3) (0.0);
        starbg = lerp(starbg, float3(0.8, 0.9, 1.0), smoothstep(0.99, 1.0, stars) * clamp(dot((float3) (0.0), rd) + 0.75, 0.0, 1.0));
        starbg = clamp(starbg, 0.0, 1.0);
        sum.xyz += starbg;
    }
#endif
   
#ifdef TONEMAPPING
    fragColor = float4(ToneMapFilmicALU(sum.xyz*2.2),1.0);
#else
    return float4(sum.xyz, 1.0);
#endif
}

#elif 0
// "Supernova remnant" by Duke
// https://www.shadertoy.com/view/MdKXzc
//-------------------------------------------------------------------------------------
// Based on "Dusty nebula 4" (https://www.shadertoy.com/view/MsVXWW) 
// and "Protoplanetary disk" (https://www.shadertoy.com/view/MdtGRl) 
// otaviogood's "Alien Beacon" (https://www.shadertoy.com/view/ld2SzK)
// and Shane's "Cheap Cloud Flythrough" (https://www.shadertoy.com/view/Xsc3R4) shaders
// Some ideas came from other shaders from this wonderful site
// Press 1-2-3 to zoom in and zoom out.
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
//-------------------------------------------------------------------------------------

#define DITHERING
//#define BACKGROUND

//#define TONEMAPPING

//-------------------
#define pi 3.14159265
#define R(p, a) p=cos(a)*p+sin(a)*float2(p.y, -p.x)

// iq's noise
float noise(in float3 x)
{
    float3 p = floor(x);
    float3 f = frac(x);
    f = f * f * (3.0 - 2.0 * f);
    float2 uv = (p.xy + float2(37.0, 17.0) * p.z) + f.xy;
    float2 rg = NoiseTexture.Sample(SamplerTex, (uv + 0.5) / 256.0, 0.0).yx;
    return 1. - 0.82 * lerp(rg.x, rg.y, f.z);
}

float fbm(float3 p)
{
    return noise(p * .06125) * .5 + noise(p * .125) * .25 + noise(p * .25) * .125 + noise(p * .4) * .2;
}

float length2(float2 p)
{
    return sqrt(p.x * p.x + p.y * p.y);
}

float length8(float2 p)
{
    p = p * p;
    p = p * p;
    p = p * p;
    return pow(p.x + p.y, 1.0 / 8.0);
}


float Disk(float3 p, float3 t)
{
    float2 q = float2(length2(p.xy) - t.x, p.z * 0.5);
    return max(length8(q) - t.y, abs(p.z) - t.z);
}

//==============================================================
// otaviogood's noise from https://www.shadertoy.com/view/ld2SzK
//--------------------------------------------------------------
// This spiral noise works by successively adding and rotating sin waves while increasing frequency.
// It should work the same on all computers since it's not based on a hash function like some other noises.
// It can be much faster than other noise functions if you're ok with some repetition.
static const float nudge = 0.9; // size of perpendicular vector
static float normalizer = 1.0 / sqrt(1.0 + nudge * nudge); // pythagorean theorem on that perpendicular to maintain scale
float SpiralNoiseC(float3 p)
{
    float n = 0.0; // noise amount
    float iter = 2.0;
    for (int i = 0; i < 8; i++)
    {
        // add sin and cos scaled inverse with the frequency
        n += -abs(sin(p.y * iter) + cos(p.x * iter)) / iter; // abs for a ridged look
        // rotate by adding perpendicular and scaling down
        p.xy += float2(p.y, -p.x) * nudge;
        p.xy *= normalizer;
        // rotate on other axis
        p.xz += float2(p.z, -p.x) * nudge;
        p.xz *= normalizer;
        // increase the frequency
        iter *= 1.733733;
    }
    return n;
}

float NebulaNoise(float3 p)
{
    float final = Disk(p.xzy, float3(2.0, 1.8, 1.25));
    final += fbm(p * 90.);
    final += SpiralNoiseC(p.zxy * 0.5123 + 100.0) * 3.0;

    return final;
}

float map(float3 p)
{
	//R(p.xz, iMouse.x*0.008*pi+time*0.1);
	R(p.xz, 0.008*pi+time*0.1);

    float NebNoise = abs(NebulaNoise(p / 0.5) * 0.5);
    
    return NebNoise + 0.07;
}
//--------------------------------------------------------------

// assign color to the media
float3 computeColor(float density, float radius)
{
	// color based on density alone, gives impression of occlusion within
	// the media
    float3 result = lerp(float3(1.0, 0.9, 0.8), float3(0.4, 0.15, 0.1), density);
	
	// color added to the media
    float3 colCenter = 7. * float3(0.8, 1.0, 1.0);
    float3 colEdge = 1.5 * float3(0.48, 0.53, 0.5);
    result *= lerp(colCenter, colEdge, min((radius + .05) / .9, 1.15));
	
    return result;
}

bool RaySphereIntersect(float3 org, float3 dir, out float near, out float far)
{
    float b = dot(dir, org);
    float c = dot(org, org) - 8.;
    float delta = b * b - c;
    if (delta < 0.0) 
        return false;
    float deltasqrt = sqrt(delta);
    near = -b - deltasqrt;
    far = -b + deltasqrt;
    return far > 0.0;
}

// Applies the filmic curve from John Hable's presentation
// More details at : http://filmicgames.com/archives/75
float3 ToneMapFilmicALU(float3 _color)
{
    _color = max((float3) (0), _color - (float3) (0.004));
    _color = (_color * (6.2 * _color + (float3) (0.5))) / (_color * (6.2 * _color + (float3) (1.7)) + (float3) (0.06));
    return _color;
}

float4 main(VS_Quad input) : SV_TARGET
{
    float3 ro = mul(float4(0, 0, 0, 1.0f), invView).xyz;
    float3 pixelPos = float3(input.canvasXY, -1);
    float3 rd = normalize(mul(float4(pixelPos, 0.0f), invView)).xyz;
    
    
	// ro: ray origin
	// rd: direction of the ray
    //float3 rd = normalize(float3((fragCoord.xy - 0.5 * iResolution.xy) / iResolution.y, 1.));
    //float3 ro = float3(0., 0., -6. + key * 1.6);
    
    
    
	// ld, td: local, total density 
	// w: weighting factor
    float ld = 0., td = 0., w = 0.;

	// t: length of the ray
	// d: distance function
    float d = 1., t = 0.;
    
    const float h = 0.1;
   
    float4 sum = (float4) (0.0);
   
    float min_dist = 0.0, max_dist = 0.0;

    if (RaySphereIntersect(ro, rd, min_dist, max_dist))
    {
       
        t = min_dist * step(t, min_dist);
   
	// raymarch loop
        for (int i = 0; i < 64; i++)
        {
	 
            float3 pos = ro + t * rd;
  
		// Loop break conditions.
            if (td > 0.9 || d < 0.1 * t || t > 10. || sum.a > 0.99 || t > max_dist)
                break;
        
        // evaluate distance function
            float d = map(pos);
		       
		// change this string to control density 
            d = max(d, 0.0);
        
        // point light calculations
            float3 ldst = (float3) (0.0) - pos;
            float lDist = max(length(ldst), 0.001);

        // the color of light 
            float3 lightColor = float3(1.0, 0.5, 0.25);
        
            sum.rgb += (float3(0.67, 0.75, 1.00) / (lDist * lDist * 10.) / 80.); // star itself
            sum.rgb += (lightColor / exp(lDist * lDist * lDist * .08) / 30.); // bloom
        
            if (d < h)
            {
			// compute local density 
                ld = h - d;
            
            // compute weighting factor 
                w = (1. - td) * ld;
     
			// accumulate density
                td += w + 1. / 200.;
		
                float4 col = float4(computeColor(td, lDist), td);
            
            // emission
                sum += sum.a * float4(sum.rgb, 0.0) * 0.2;
            
			// uniform scale density
                col.a *= 0.2;
			// colour by alpha
                col.rgb *= col.a;
			// alpha blend in contribution
                sum = sum + col * (1.0 - sum.a);
       
            }
      
            td += 1. / 70.;

#ifdef DITHERING
        //idea from https://www.shadertoy.com/view/lsj3Dw
            float2 uv = input.canvasXY; //fragCoord.xy / iResolution.xy;
            uv.y *= 120.;
            uv.x *= 280.;
            d = abs(d) * (.8 + 0.08 * NoiseTexture.Sample(SamplerTex, float2(uv.y, -uv.x + 0.5 * sin(4. * time + uv.y * 4.0))).r);
#endif 
		
        // trying to optimize step size near the camera and near the light source
            t += max(d * 0.1 * max(min(length(ldst), length(ro)), 1.0), 0.01);
        
        }
    
    // simple scattering
        sum *= 1. / exp(ld * 0.2) * 0.6;
        
        sum = clamp(sum, 0.0, 1.0);
   
        sum.xyz = sum.xyz * sum.xyz * (3.0 - 2.0 * sum.xyz);
    
    }

#ifdef BACKGROUND
    // stars background
    if (td < .8)
    {
        float3 stars = (float3) (noise(rd * 500.0) * 0.5 + 0.5);
        float3 starbg = (float3) (0.0);
        starbg = lerp(starbg, float3(0.8, 0.9, 1.0), smoothstep(0.99, 1.0, stars) * clamp(dot((float3) (0.0), rd) + 0.75, 0.0, 1.0));
        starbg = clamp(starbg, 0.0, 1.0);
        sum.xyz += starbg;
    }
#endif
   
#ifdef TONEMAPPING
    return float4(ToneMapFilmicALU(sum.xyz*2.2),1.0);
#else
    return float4(sum.xyz, 1.0);
#endif
}



#elif 0
// My edit of https://www.shadertoy.com/view/XdjXDy

const float pi = 3.1415927;

float sdSphere(float3 p, float s)
{
    return length(p) - s;
}

float sdTorus(float3 p, float2 t)
{
    float2 q = float2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float4 main(VS_Quad input) : SV_TARGET
{
    float3 ro = mul(float4(0, 0, 0, 1.0f), invView).xyz;
    float3 pixelPos = float3(input.canvasXY, -1);
    float3 rd = normalize(mul(float4(pixelPos, 0.0f), invView)).xyz;
        
    float3 bh = posW;
    float bhr = 0.2;
    float bhmass = 20.0;
    bhmass *= 0.001; // premul G
    
    float3 p = ro;
    float3 pv = rd;
    float dt = 0.02;
    
    float3 col = (float3) (0.0);
    
    float noncaptured = 1.0;
     
    float3 c1 = float3(.9, .35, 0.1);
    float3 c2 = float3(1.0, .8, .6);
    
    
    for (float t = 0.0; t < 1.0; t += 0.005)
    {
        p += pv * dt * noncaptured;
        
        // gravity
        float3 bhv = bh - p;
        
        //noncaptured = smoothstep(0.0, 0.1, sdSphere(p - bh, bhr * 2.));
        noncaptured = sdSphere(p - bh, bhr * 2.);
        
        // Texture for the accretion disc
        float dr = length(bhv.xz);
        float da = atan2(bhv.x, bhv.z);
        float2 ra = float2(dr, da * (0.01 + (dr - bhr) * 0.002) + 2.0 * pi + time * 0.002);
        ra *= float2(10.0, 20.0);
        
        float3 dcol = lerp( c2,
                            c1,
                            pow(length(bhv) - bhr, 0.5)
                           ) * max(0.0,
                                   NoiseTexture.Sample(SamplerTex, ra * float2(0.1, 0.5)).r + 0.05
                                   ) * (5.0 / ((0.001 + (length(bhv) - bhr) * 50.0)));
        
        col += max((float3) (0.0),
                   dcol * smoothstep(0.0,
                                     1.0,
                                     -sdTorus((p * float3(1.5, 20.0, 1.5)) - bh,
                                               float2(1., .79)
                                              )
                                     ) * noncaptured);
        
        
        //col += dcol * (1.0/dr) * noncaptured * 0.005;
        
        // Glow
        col += float3(1.0, 0.9, 0.85) * 0.5 * (1.0 / ((float3) dot(bhv, bhv))) * 0.0033 * noncaptured;
        
    }
    
    // BG
    //  col += pow(NoiseTexture0.Sample(Sampler,pv.xy).rgb,float3(5.0)) * 0.25;
    
    // FInal color
    return float4(col, 1.0);

}


#else

static const float3 PLANET_COLOR_D = float3(0.8, 0.7, 0.48);
static const float3 PLANET_COLOR_L = float3(0.8, 0.75, 0.5);
static const float3 RING_COLOR = float3(1.8, 1.85, 1.8);

static const float3 LIGHT_POS = normalize(float3(0.0, 15.f, -10.f));
static const float3 LIGHT_COLOR = (float3) 1.;

float3 rotateX(float3 v, float angle)
{
    float ca = cos(angle);
    float sa = sin(angle);
    return mul(v, float3x3(1.0, .0, .0,
                          .0, ca, -sa,
                          .0, sa, ca));
}

float sdSphere(float3 p, float r)
{
    return length(p) - r;
}

float sdCylinder(float3 p, float3 c)
{
    return length(p.xz - c.xy) - c.z;
}

float sdCappedCylinder(float3 p, float2 h)
{
    float2 d = abs(float2(length(p.xz), p.y)) - h;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float opS(float d1, float d2)
{
    return max(-d1, d2);
}

float rand(float n)
{
    return frac(sin(n) * 43758.5453123);
}

float noise(float p)
{
    float i = floor(p);
    float f = frac(p);
    
    float u = f * f * (3.0 - 2.0 * f);
	
    return lerp(rand(i), rand(i + 1.), u);
}

float sdTorus(float3 p, float2 t)
{
    float2 q = float2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float4 scene(float3 q)
{
    float3 col = (float3)0.0;
    float obj = 1000.;
    
    float3 p = q - posW;
    
    //p = rotateX(p, .2 + sin(time) * 2.);
    p = rotateX(p, .3);
   
    
    float sphere = sdSphere(p, 15.);
    if (obj > sphere)
    {
        float col_displacement = 0.15 * (noise(20. * atan2(p.z, p.x) + 25. * p.y) - .5);
        col = lerp(PLANET_COLOR_D, PLANET_COLOR_L, frac(p.y * 5. + col_displacement));
        obj = sphere;
    }
    
    float max_ring_r = 30.8;
    float ring = sdCappedCylinder(p, float2(max_ring_r, 0.001));
    
    float ring_r = 20.55;
    ring = opS(sdCylinder(p, float3(0., 0., ring_r)), ring);
        
    if (obj > ring)
    {
        obj = ring;
        col = RING_COLOR;
        col *= smoothstep(0.1, 1., noise(length(p) * 10.));
    }
    
    return float4(col, obj);
}

float map(float3 p)
{
    return scene(p).w;
}

float raymarch(float3 start, float3 dir)
{
    int steps = 100;
    float t = 0.;
    for (int i = 0; i <= steps; i++)
    {
        float3 curr_point = start + t * dir;
        float obj = map(curr_point);
        
        if (obj < 0.01)
        {
            return t;
        }
        else
        {
            t += obj;
        }
        
        if (t >= steps)
        {
            return -1.;
        }
    }
    
    return -1.;
}

//float3 normalAtPoint(float3 p)
//{
//    const float eps = 0.0001;
//    const float2 h = float2(eps, 0);
//    return normalize(float3(map(p + h.xyy) - map(p - h.xyy),
//                            map(p + h.yxy) - map(p - h.yxy),
//                            map(p + h.yyx) - map(p - h.yyx)));
//}

float3 normalAtPoint(float3 p)
{
    const float eps = 0.001;
 
    return normalize
 (float3
 	(map(p + float3(eps, 0, 0)) - map(p - float3(eps, 0, 0)),
 	  map(p + float3(0, eps, 0)) - map(p - float3(0, eps, 0)),
	  map(p + float3(0, 0, eps)) - map(p - float3(0, 0, eps))
 	)
 );
}

//float hardShadow(float3 start, float3 dir, float t_min, float t_max)
//{
//    float t = t_min;
//    while (t < t_max)
//    {
//        float3 curr_point = start + t * dir;
//        float map_val = map(curr_point);
        
//        if (map_val < 0.01)
//        {
//            return 0.;
//        }
//        else
//        {
//            t += map_val;
//        }
//    }
    
//    return 1.;
//}

float softshadow(in float3 ro, in float3 rd, float mint, float maxt, float k)
{
    float res = 1.0;
    float ph = 1e20;
    for (float t = mint; t < maxt;)
    {
        float h = map(ro + rd * t);
        if (h < 0.001)
            return 0.0;
        
        float y = h * h / (2.0 * ph);
        float d = sqrt(h * h - y * y);
        res = min(res, k * d / max(0.0, t - y));
        ph = h;
        t += 0.95 * h;
    }
    return res;
}

float3 render(float3 p)
{
    float3 col = (float3)0.0;
    float3 normal = normalAtPoint(p);
    float3 diffuse = scene(p).xyz;
 	 
    float3 lpos = LIGHT_POS;
    //lpos.xz += float2(time, time);
    
    //float3 lightDir = -normalize(lpos - p);
    float3 lightDir = normalize(float3(1., 1., 0.));
    
   	//directional lighting
    float LdotN = clamp(dot(normal, lightDir), 0., 1.);
    //float shadow = softshadow(p, lightDir, 0.02, 20., 17.);
    //float shadow = hardShadow(p, lightDir, 0.02, 20.);
    //float shadow = 1.0;
    col = diffuse * LdotN * LIGHT_COLOR;// * clamp(0.3, 1., shadow);
        
    return col;    
    //return normal;
}

float4 main(VS_Quad input) : SV_TARGET
{
    float3 ro = mul(float4(0, 0, 0, 1.0f), invView).xyz;
    float3 pixelPos = float3(input.canvasXY, -1);
    float3 rd = normalize(mul(float4(pixelPos, 0.0f), invView)).xyz;
    
    float3 color = (float3) 0.0;
    
    float t = raymarch(ro, rd);
    float3 p = ro + rd * t;
    
    if (t > 0.0)
    {
        //color = (float3) 1.;
        color = render(p);
    }
    else
    {
        //color = float3(1, 0, 0);
    }
    
    
    
    return float4(color, 1.0);
}
#endif