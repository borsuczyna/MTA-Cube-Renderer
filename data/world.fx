#define GENERATE_NORMALS
#include "data/include/mta-helper.fx"
::Includes::

texture sAlbedo < string renderTarget = "yes"; >;
texture sDepth < string renderTarget = "yes"; >;
texture sEmmisives < string renderTarget = "yes"; >;

float3 sLightDir = float3(0.5, -0.5, 0.5);

::Variables::

// ::loop(i, 1, 5)
// float3 lightPosition(:i:) = float3(0, 0, 0);
// ::end

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
    float4 Position : POSITION0;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
    float3 WorldPos : TEXCOORD1;
    float3 Normal : TEXCOORD2;
};

PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;

    float4 worldPos = mul(float4(VS.Position,1), gWorld);
    ::WorldPosition::
    float4 worldPosView = mul(worldPos, gView);
    PS.Position = mul(worldPosView, gProjection);

    PS.TexCoord = VS.TexCoord;
    PS.Diffuse = MTACalcGTABuildingDiffuse(VS.Diffuse);
    PS.WorldPos = worldPos.xyz;
    PS.Normal = mul(VS.Normal, (float3x3)gWorld);

    return PS;
}

struct Pixel
{
    float4 World : COLOR0;
    float4 Albedo : COLOR1;
    float4 Depth : COLOR2;
    float4 Emissive : COLOR3;
};

Pixel PixelShaderFunction(PSInput PS)
{
    Pixel Output;
    float4 texel = tex2D(Sampler0, PS.TexCoord);
    texel.a *= PS.Diffuse.a;
    texel *= gMaterialDiffuse * gGlobalAmbient + gMaterialAmbient;
    ::PixelShader::

    float4 albedo = tex2D(AlbedoSampler, PS.TexCoord);

    Output.World = texel;
    Output.Albedo = texel;
    if(albedo.a == 0) // it's sky, multiply alpha
        Output.Albedo.a *= 3;

    float depth = distance(gCameraPosition, PS.WorldPos) / 1000;
    Output.Depth = float4(depth, depth, depth, Output.Albedo.a);
    float4 emmisive = float4(0, 0, 0, Output.Albedo.a > 0.78 ? Output.Albedo.a : 0);
    ::Emmisive::
    Output.Emissive = emmisive;

    float inverseDot = pow(dot(sLightDir, PS.Normal), 2);
    Output.Albedo.rgb *= lerp(1, 0.6, inverseDot * (1-emmisive));

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