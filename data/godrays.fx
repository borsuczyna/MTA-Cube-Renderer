#include "data/include/mta-helper.fx"

float2 sSunPosition;
float2 sScrRes;
float fSunSize;
float3 sSunColor = float3(255/255.0, 255/265.0, 255/275.0);
bool sSunVisible;

float fGodRayStrength = 0.05;
float fGodRayStartOffset = 0.3;
float fGodRayLength = 0.7;
static int iGodRaySamples = 25;

texture sRTDepth;
texture sGodraysTexture < string renderTarget = "yes"; >;

sampler SamplerDepth = sampler_state
{
    Texture = sRTDepth;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = Point;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler SamplerGodrays = sampler_state
{
    Texture = sGodraysTexture;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
};

struct VSInput
{
    float3 Position : POSITION;
    float4 Diffuse  : COLOR0;
    float2 TexCoord : TEXCOORD0;
};

struct PSInput
{
    float4 Position : POSITION0;
    float4 Diffuse  : COLOR0;
    float2 TexCoord : TEXCOORD0;
};

PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;

    PS.Position = mul(float4(VS.Position, 1), gWorldViewProjection);
    PS.Diffuse = VS.Diffuse;
    PS.TexCoord = VS.TexCoord;

    return PS;
}

struct Pixel {
    float4 Color : COLOR0;
    float4 Output : COLOR1;
};

Pixel PixelShaderFunction(PSInput PS)
{
    if(!sSunVisible) return (Pixel)0;
    float2 sunPos = sSunPosition / sScrRes;
    float2 sunSize = fSunSize / sScrRes;
    float sunDist = 1 - length(PS.TexCoord - sunPos) / sunSize;

    float depth = tex2D(SamplerDepth, PS.TexCoord).a;
    sunDist = sunDist * (1 - depth);

    Pixel Out;
    Out.Color = float4(sSunColor.rgb, sunDist);
    Out.Output = float4(sSunColor.rgb, sunDist);

    return Out;
}

float4 PixelShaderGodrays(PSInput PS) : COLOR0 {
    float4 finalColor = tex2D(SamplerGodrays, PS.TexCoord);
    float2 sunPos = sSunPosition / sScrRes;
    PS.TexCoord -= sunPos;

    for(int i = 0; i < iGodRaySamples; i++) {
        float scale = fGodRayStartOffset + fGodRayLength * (i / (float)(iGodRaySamples - 1));
        finalColor += tex2D(SamplerGodrays, PS.TexCoord * scale + sunPos);
    }

	finalColor *= fGodRayStrength / (28/(float)iGodRaySamples);
    return finalColor * PS.Diffuse;
}

technique shaded_godrays
{
    pass P0
    {
        VertexShader = compile vs_3_0 VertexShaderFunction();
        PixelShader  = compile ps_3_0 PixelShaderFunction();
    }
    pass P1
    {
        VertexShader = compile vs_3_0 VertexShaderFunction();
        PixelShader  = compile ps_3_0 PixelShaderGodrays();
    }
}