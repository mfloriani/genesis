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

static const float3 PLANET_COLOR_D = float3(0.8, 0.7, 0.48);
static const float3 PLANET_COLOR_L = float3(0.8, 0.75, 0.5);
static const float3 RING_COLOR = float3(0.8, 0.85, 0.8);

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

float4 scene(float3 q)
{
    float3 col = (float3)0.0;
    float obj = 1000.;
        
    float3 p = q;
    p -= posW;
    
    //p = rotateX(p, .2 + sin(time) * 2.);
    p = rotateX(p, .1);
   
    
    float sphere = sdSphere(p, 1.);
    if (obj > sphere)
    {
        float col_displacement = 0.15 * (noise(20. * atan2(p.z, p.x) + 25. * p.y) - .5);
        col = lerp(PLANET_COLOR_D, PLANET_COLOR_L, frac(p.y * 5. + col_displacement));
        obj = sphere;
    }
    
    float max_ring_r = 2.8;
    float ring = sdCappedCylinder(p, float2(max_ring_r, 0.0001));
    
    float ring_r = 1.55;
    ring = opS(sdCylinder(p, float3(0., 0., ring_r)), ring);
        
    if (obj > ring)
    {
        obj = ring;
        col = RING_COLOR;
        col *= smoothstep(0.3, 1., noise(length(p) * 20.));
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

float3 normalAtPoint(float3 p)
{
    const float eps = 0.0001;
    const float2 h = float2(eps, 0);
    return normalize(float3(map(p + h.xyy) - map(p - h.xyy),
                            map(p + h.yxy) - map(p - h.yxy),
                            map(p + h.yyx) - map(p - h.yyx)));
}

float hardShadow(float3 start, float3 dir, float t_min, float t_max)
{
    float t = t_min;
    while (t < t_max)
    {
        float3 curr_point = start + t * dir;
        float map_val = map(curr_point);
        
        if (map_val < 0.01)
        {
            return 0.;
        }
        else
        {
            t += map_val;
        }
    }
    
    return 1.;
}

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
    float3 normal = -normalAtPoint(p);
    float3 diffuse = scene(p).xyz;
 	 
    float3 lpos = LIGHT_POS;
    //lpos.xz += float2(time, time);
    
    float3 lightDir = -normalize(lpos - p);
    //float3 lightDir = -normalize(float3(1., 1., 0.));
    
   	//directional lighting
    float LdotN = clamp(dot(normal, lightDir), 0., 1.);
    //float shadow = softshadow(p, lightDir, 0.02, 20., 17.);
    //float shadow = hardShadow(p, lightDir, 0.02, 20.);
    float shadow = 1.0;
    col = diffuse * LdotN * LIGHT_COLOR * clamp(0.3, 1., shadow);
        
    return col;    
    //return normal;
}

float4 main(VS_Quad input) : SV_TARGET
{
    float3 ro = mul(float4(0, 0, 0, 1.0f), invView).xyz;
    float3 pixelPos = float3(input.canvasXY, -15);
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
        color = float3(1, 0, 0);
    }
    
    
    
    return float4(color, 1.0);
}