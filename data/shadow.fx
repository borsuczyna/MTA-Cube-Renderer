#include "data/include/mta-helper.fx"
#include "data/include/matrix.fx"
#include "data/include/pack.fx"
::Includes::

float3 sCameraPosition = float3(0,0,0);
float3 sCameraForward = float3(0,0,0);
float3 sCameraUp = float3(0,0,0);
float2 sClip = float2(0.3,300);
float2 sScrRes = float2(800,600);

texture depthRT < string renderTarget = "yes"; >;
float gAlphaRef < string renderState="ALPHAREF"; >;

::Variables::

sampler2D Sampler0 = sampler_state
{
    Texture = (gTexture0);
};

sampler2D SamplerDepth = sampler_state
{
    Texture = (depthRT);
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

PSInput VertexShaderFunction(VSInput VS )
{
    PSInput PS = (PSInput)0;

    float4 worldPos = mul(float4(VS.Position.xyz,1), gWorld);
    ::WorldPosition::
    float3 cameraForward = sCameraForward;
    float3 cameraUp = sCameraUp;
	
    float4x4 sView = createViewMatrix(sCameraPosition, cameraForward, cameraUp);
    float4x4 sProjection = createOrthographicProjectionMatrix(-sClip.y, sClip.y, sScrRes.x, sScrRes.y);
	
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

struct Pixel
{
    float4 World : COLOR0;
    float4 Depth : COLOR1;
};

Pixel PixelShaderFunction(PSInput PS)
{
    Pixel output;

    float4 texel = tex2D(Sampler0, PS.TexCoord);
	
    float2 TexProj = PS.TexProj.xy / PS.TexProj.z;
    TexProj += float2(0.0001, 0.0001);

    output.World = 0;
    output.Depth = 0;
    if (PS.PlaneDist <= 0) return output;
	
    float depth = DistToUnit(PS.Depth.x / PS.Depth.y, sClip.x, sClip.y);
    float3 packedDepth = tex2D(SamplerDepth, TexProj).rgb;
    float depthVal = ColorToUnit24(packedDepth);
	
    if ((depthVal >= depth) && (PS.PlaneDist > 0))
    {
        output.Depth.rgb = UnitToColor24(depth);
		float shadowValue = (texel.a * PS.Diffuse.a) > gAlphaRef ? texel.a * PS.Diffuse.a * 2 : 0;

        output.Depth.a = shadowValue;
    }
    
    return output;
}

technique cube_shadow
{
    pass P0
    {
        VertexShader = compile vs_3_0 VertexShaderFunction();
        PixelShader = compile ps_3_0 PixelShaderFunction();

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