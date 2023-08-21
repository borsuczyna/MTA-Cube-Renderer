#include "data/include/mta-helper.fx"
#include "data/include/matrix.fx"
#include "data/include/pack.fx"
::Includes::

float3 sCameraPosition = float3(0,0,0);
float3 sCameraForward = float3(0,0,0);
float3 sCameraUp = float3(0,0,0);
float2 sClip = float2(0.3,300);
float2 sScrRes1 = float2(800,600);
float2 sScrRes2 = float2(800,600);
float2 sScrRes3 = float2(800,600);

texture depthRT1 < string renderTarget = "yes"; >;
texture depthRT2 < string renderTarget = "yes"; >;
texture depthRT3 < string renderTarget = "yes"; >;
float gAlphaRef < string renderState="ALPHAREF"; >;

::Variables::

sampler2D Sampler0 = sampler_state
{
    Texture = (gTexture0);
};

sampler2D SamplerDepth1 = sampler_state
{
    Texture = (depthRT1);
    AddressU = Clamp;
    AddressV = Clamp;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
    MaxMipLevel = 0;
    MipMapLodBias = 0;
};

sampler2D SamplerDepth2 = sampler_state
{
    Texture = (depthRT2);
    AddressU = Clamp;
    AddressV = Clamp;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
    MaxMipLevel = 0;
    MipMapLodBias = 0;
};

sampler2D SamplerDepth3 = sampler_state
{
    Texture = (depthRT3);
    AddressU = Clamp;
    AddressV = Clamp;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
    MaxMipLevel = 0;
    MipMapLodBias = 0;
};

struct VSInput
{
    float3 Position : POSITION0;
    float3 Normal : NORMAL0;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
};

struct PSInput
{
    float4 Position : POSITION0;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
    float3 TexProj : TEXCOORD1;
    float PlaneDist : TEXCOORD2;
    float4 Depth : TEXCOORD3;
    float3 WorldPos : TEXCOORD4;
};

struct Pixel
{
    float4 World : COLOR0;
    float4 Depth1 : COLOR1;
    float4 Depth2 : COLOR2;
    float4 Depth3 : COLOR3;
};

PSInput ProcessShadowMapVS(VSInput VS, float2 scrRes) {
    PSInput PS = (PSInput)0;

    float4 worldPos = mul(float4(VS.Position.xyz,1), gWorld);
    ::WorldPosition::
    float3 cameraForward = sCameraForward;
    float3 cameraUp = sCameraUp;
	
    float4x4 sView = createViewMatrix(sCameraPosition, cameraForward, cameraUp);
    float4x4 sProjection = createOrthographicProjectionMatrix(-sClip.y, sClip.y, scrRes.x, scrRes.y);
	
    float4 viewPos = mul(worldPos, sView);
    PS.Position = mul(viewPos, sProjection);
	
    PS.PlaneDist = dot(cameraForward, worldPos.xyz - sCameraPosition);
    PS.TexCoord = VS.TexCoord;

    float projectedX = (0.5 * (PS.Position.w + PS.Position.x));
    float projectedY = (0.5 * (PS.Position.w - PS.Position.y));
    PS.TexProj.xyz = float3(projectedX, projectedY, PS.Position.w);  
	
    PS.Diffuse = MTACalcGTABuildingDiffuse(VS.Diffuse);
    PS.Depth = float4(viewPos.z, viewPos.w, sClip[0], sClip[1]);

    PS.WorldPos = worldPos.xyz;
	
    return PS;
}

float4 ProcessShadowMapPS(PSInput PS, sampler2D depthSampler, float2 scrRes) {
    float4 output = (float4)0;
    float4 texel = tex2D(Sampler0, PS.TexCoord);

    float2 TexProj = PS.TexProj.xy / PS.TexProj.z;
    TexProj += float2(0.0001, 0.0001);

    if (PS.PlaneDist <= 0) return output;

    float depth = DistToUnit(PS.Depth.x / PS.Depth.y, sClip.x, sClip.y);
    float3 packedDepth = tex2D(depthSampler, TexProj).rgb;
    float depthVal = ColorToUnit24(packedDepth);

    if ((depthVal >= depth) && (PS.PlaneDist > 0)) {
        output.rgb = UnitToColor24(depth);
        output.a = (texel.a * PS.Diffuse.a) > gAlphaRef ? texel.a * PS.Diffuse.a : 0;
    }

    return output;
}

PSInput VertexShaderFunction_1(VSInput VS) {
    return ProcessShadowMapVS(VS, sScrRes1);
}

PSInput VertexShaderFunction_2(VSInput VS) {
    return ProcessShadowMapVS(VS, sScrRes2);
}

PSInput VertexShaderFunction_3(VSInput VS) {
    return ProcessShadowMapVS(VS, sScrRes3);
}

Pixel PixelShaderFunction_1(PSInput PS) {
    Pixel output = (Pixel)0;
    output.Depth1 = ProcessShadowMapPS(PS, SamplerDepth1, sScrRes1);
    
    return output;
}

Pixel PixelShaderFunction_2(PSInput PS) {
    Pixel output = (Pixel)0;
    output.Depth2 = ProcessShadowMapPS(PS, SamplerDepth2, sScrRes2);
    
    return output;
}

Pixel PixelShaderFunction_3(PSInput PS) {
    Pixel output = (Pixel)0;
    output.Depth3 = ProcessShadowMapPS(PS, SamplerDepth3, sScrRes3);
    
    return output;
}

technique cube_shadow
{
    pass P0
    {
        VertexShader = compile vs_3_0 VertexShaderFunction_1();
        PixelShader = compile ps_3_0 PixelShaderFunction_1();

        AlphaBlendEnable = true;
        AlphaTestEnable = false;
        AlphaFunc = GreaterEqual;
        ShadeMode = Gouraud;
        ZEnable = false;
        FogEnable = false;
        SrcBlend = SrcAlpha;
        DestBlend = InvSrcAlpha;
        DitherEnable = false;
        StencilEnable = false;
    }
    pass P1
    {
        VertexShader = compile vs_3_0 VertexShaderFunction_2();
        PixelShader = compile ps_3_0 PixelShaderFunction_2();

        AlphaBlendEnable = true;
        AlphaTestEnable = false;
        AlphaFunc = GreaterEqual;
        ShadeMode = Gouraud;
        ZEnable = false;
        FogEnable = false;
        SrcBlend = SrcAlpha;
        DestBlend = InvSrcAlpha;
        DitherEnable = false;
        StencilEnable = false;
    }
    pass P2
    {
        VertexShader = compile vs_3_0 VertexShaderFunction_3();
        PixelShader = compile ps_3_0 PixelShaderFunction_3();

        AlphaBlendEnable = true;
        AlphaTestEnable = false;
        AlphaFunc = GreaterEqual;
        ShadeMode = Gouraud;
        ZEnable = false;
        FogEnable = false;
        SrcBlend = SrcAlpha;
        DestBlend = InvSrcAlpha;
        DitherEnable = false;
        StencilEnable = false;
    }
}