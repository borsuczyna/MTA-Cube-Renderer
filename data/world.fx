#define GENERATE_NORMALS
#include "data/include/mta-helper.fx"
#include "data/include/normal.fx"
#include "data/include/light.fx"
::Includes::

texture sAlbedo < string renderTarget = "yes"; >;
texture sDepth < string renderTarget = "yes"; >;
texture sEmmisives < string renderTarget = "yes"; >;

float3 sLightDir = float3(0.5, 0.5, -0.5);
float3 sLightColor = float3(1, 0, 0);

::Variables::

::loop(i, 1, ::maxLights::)
float4 lightPosition(:i:) = float4(-694.71515, 958.76672, 12.25529, 6); // 4th = size
float4 lightColor(:i:) = float4(3.5, 0, 0, 1); // 4th = pow
float4 lightDirection(:i:) = float4(0, 1, 0, 1); // 4th = 1 - directional, 0 - point
float3 lightPhiThetaFalloff(:i:) = float3(3, 0, 1);
bool lightEnabled(:i:) = false;
::end

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
    float4 Position : POSITION;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
    float3 Normal : NORMAL0;
    ::VSInput::
};

struct PSInput
{
    float4 Position : POSITION;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
    float4 WorldPos : TEXCOORD1;
    float3 Normal : TEXCOORD2;
    ::PSInput::
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

    float4 worldPos = mul(VS.Position, gWorld);
    ::WorldPosition::
    float4 worldPosView = mul(worldPos, gView);
    PS.Position = mul(worldPosView, gProjection);

    PS.TexCoord = VS.TexCoord;
    PS.Diffuse = MTACalcGTABuildingDiffuse(VS.Diffuse);
    PS.WorldPos = worldPos;
    PS.Normal = mul(VS.Normal, (float3x3)gWorld);
    MTAFixUpNormal(PS.Normal);

    ::VertexShader::

    return PS;
}

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

    float depth = distance(gCameraPosition, PS.WorldPos.xyz) / 1000;
    Output.Depth = float4(depth, depth, depth, Output.Albedo.a);
    float4 emmisive = float4(0, 0, 0, Output.Albedo.a > 0.78 ? Output.Albedo.a : 0);
    ::Emmisive::

    float inverseDot = pow(dot(sLightDir, PS.Normal), 2);
    Output.Albedo.rgb *= lerp(1, 0.6, inverseDot * (1-emmisive));

    float3 normalTexel = tex2DNormal(Sampler0, PS.TexCoord);
    PS.Normal -= normalTexel - 0.5;

    // float3 lightColor = (float3)0;
    float3 lightColors = (float3)0;
    float lightDistance;

    ::loop(i, 1, ::maxLights::)
    if(lightEnabled(:i:)) {
        Output.Albedo.rgb = AffectByLight(
            Output.Albedo.rgb,
            PS.WorldPos.xyz,
            PS.Normal,
            lightPosition(:i:).xyz,
            lightColor(:i:).rgb,
            lightPosition(:i:).w,
            lightDirection(:i:).xyz,
            lightDirection(:i:).w == 1,
            lightPhiThetaFalloff(:i:).x,
            lightPhiThetaFalloff(:i:).y,
            lightPhiThetaFalloff(:i:).z,
            lightColors
        );

        lightDistance = min(distance(PS.WorldPos.xyz, lightPosition(:i:).xyz)/lightPosition(:i:).w, 1);
        // Output.Albedo.rgb = lerp(Output.Albedo.rgb, pow(Output.Albedo.rgb, lightColor(:i:).a), 1 - lightDistance);
        // emmisive.rgb = lerp(emmisive.rgb, lightColor, 1 - lightDistance);
    }
    ::end
    emmisive.rgb += lightColors / 2;

    Output.Emissive = emmisive;

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