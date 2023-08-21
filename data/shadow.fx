#include "data/include/mta-helper.fx"
#include "data/include/matrix.fx"
#include "data/include/pack.fx"
::Includes::

float3 sCameraPosition = float3(0,0,0);
float3 sCameraForward = float3(0,0,0);
float3 sCameraUp = float3(0,0,0);
float2 sClip = float2(0.3,300);

::loop(i, 1, ::shadowPlanes::)
float2 sScrRes(:i:) = float2(800,600);
::end

texture depthRT1 < string renderTarget = "yes"; >;
texture depthRT2 < string renderTarget = "yes"; >;
texture depthRT3 < string renderTarget = "yes"; >;
float gAlphaRef < string renderState="ALPHAREF"; >;

::Variables::

sampler2D Sampler0 = sampler_state
{
    Texture = (gTexture0);
};

::loop(i, 1, ::shadowPlanes::)
sampler2D SamplerDepth(:i:) = sampler_state
{
    Texture = (depthRT(:i:));
    AddressU = Clamp;
    AddressV = Clamp;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
    MaxMipLevel = 0;
    MipMapLodBias = 0;
};
::end

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

::loop(i, 1, ::shadowPlanes::)
PSInput VertexShaderFunction(:i:)(VSInput VS) {
    return ProcessShadowMapVS(VS, sScrRes(:i:));
}

Pixel PixelShaderFunction(:i:)(PSInput PS) {
    Pixel output = (Pixel)0;
    output.Depth(:i:) = ProcessShadowMapPS(PS, SamplerDepth(:i:), sScrRes(:i:));
    
    return output;
}
::end

technique cube_shadow
{
    ::loop(i, 1, ::shadowPlanes::)
    pass P(:i-1:)
    {
        VertexShader = compile vs_3_0 VertexShaderFunction(:i:)();
        PixelShader = compile ps_3_0 PixelShaderFunction(:i:)();

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
    ::end
}