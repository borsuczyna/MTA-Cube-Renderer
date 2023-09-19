#define GENERATE_NORMALS
#include "data/include/mta-helper.fx"
#include "data/include/normal.fx"
#include "data/include/light.fx"

texture sAlbedo < string renderTarget = "yes"; >;
texture sDepth < string renderTarget = "yes"; >;
texture sEmmisives < string renderTarget = "yes"; >;

float3 sLightDir = float3(0.5, 0.5, -0.5);
float3 sLightColor = float3(1, 0, 0);

sampler Sampler0 = sampler_state
{
    Texture = (gTexture0);
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MaxMipLevel = 0.5;
    MipMapLodBias = -2;
};

sampler AlbedoSampler = sampler_state
{
    Texture = (sAlbedo);
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MaxMipLevel = 0;
    MipMapLodBias = 0;
};

struct VSInput
{
    float3 Position : POSITION0;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
    float3 Normal : NORMAL0;
};

struct PSInput
{
    float4 Position : POSITION;
    float2 TexCoord : TEXCOORD0;
    float4 RefractionPos : TEXCOORD1;
	float4 WorldPos : TEXCOORD2;
	float3 LightDir : TEXCOORD3;
	float3 Normal : TEXCOORD4;
	float4 VertexPos : TEXCOORD5;
};

struct Pixel
{
    float4 World : COLOR0;
    float4 Albedo : COLOR1;
    float4 Depth : COLOR2;
    float4 Emissive : COLOR3;
};

PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;

    // Create the view projection world matrix for reflection.
	matrix projection = mul(gWorldViewProjection, gWorld);
	projection = mul(gWorld, projection);

	// Calculate the position of the vertex against the world, view, and projection matrices.
    PS.WorldPos = mul(float4(VS.Position,1), gWorld);
    float4 viewPos = mul(PS.WorldPos, gView);
    PS.WorldPos.w = viewPos.z / viewPos.w;
    PS.Position = mul(viewPos, gProjection);
    PS.LightDir = normalize(sLightDir);
	MTAFixUpNormal(VS.Normal);
	PS.Normal = MTACalcWorldNormal(VS.Normal);

    PS.TexCoord = VS.TexCoord;
	PS.RefractionPos = mul(VS.Position, projection);
	PS.VertexPos = mul(VS.Position, gWorldViewProjection);

    return PS;
}

Pixel PixelShaderFunction(PSInput PS)
{
    Pixel Output;
    float4 texel = tex2D(Sampler0, PS.TexCoord);
    float depth = distance(gCameraPosition, PS.WorldPos.xyz) / 1000;

    float Depth = PS.VertexPos.z / PS.VertexPos.w;

    Output.World = texel;
    Output.Albedo = texel;
    Output.Depth = float4(depth, depth, depth, Output.Albedo.a);
    Output.Emissive = float4(0, 0, 0, 1);
    Output.Albedo = float4(pow(Depth, 100), 0, 0, 1);

    return Output;
}

technique cube_world_fast
{
    pass P0
    {
        VertexShader = compile vs_3_0 VertexShaderFunction();
        PixelShader = compile ps_3_0 PixelShaderFunction();
        FogEnable = false;
        AlphaBlendEnable = true;
        AlphaTestEnable = true;
        
        AlphaRef = 1;
        SeparateAlphaBlendEnable = true;
        SrcBlendAlpha = SrcAlpha;
        DestBlendAlpha = One;
    }
}

technique fallback { pass P0 {} }