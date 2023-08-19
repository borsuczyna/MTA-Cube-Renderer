float3 UnitToColor24(in float depth) 
{
    const float3 scale	= float3(1.0, 256.0, 65536.0);
    const float2 ogb = float2(65536.0, 256.0) / 16777215.0;
    const float normal	= 256.0 / 255.0;
	
    float3 unit	= (float3)depth;
    unit.gb	-= floor(unit.gb / ogb) * ogb;
	
    float3 color = unit * scale;
    color = frac(color);
    color *= normal;
    color.rg -= color.gb / 256.0;

    return color;
}

float ColorToUnit24(in float3 color) {
    const float3 scale = float3(65536.0, 256.0, 1.0) / 65793.0;
    return dot(color, scale);
}

float DistToUnit(in float dist, in float nearClip, in float farClip) 
{
    float unit = (dist - nearClip) / (farClip - nearClip);
    return unit;
}

float UnitToDist(in float unit, in float nearClip, in float farClip) 
{
    float dist = (dist * (farClip - nearClip)) + nearClip;
    return dist;
}