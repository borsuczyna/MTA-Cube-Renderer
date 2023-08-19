float4x4 gWorldViewProjection : WORLDVIEWPROJECTION;

texture sAlbedo;
texture sShadows;
texture sSkybox;
texture sDepth;
texture sEmmisives;

float4 fAmbientColor = float4(0.3, 0.3, 0.3, 1.0);
float4 fLightColor = float4(1.05, 0.95, 0.85, 1.0);
float4 fAOColor = float4(0.3, 0.3, 0.3, 1.0);
float4 fAOShadowColor = float4(0.1, 0.1, 0.1, 1.0);

float4 fFogColor = float4(188.0/255, 225.0/255, 249.0/255, 1.0);
float fFogStart = 0.05;
float fFogDistance = 0.4;

sampler AlbedoSampler = sampler_state {
    Texture = (sAlbedo);
};

sampler ShadowSampler = sampler_state {
    Texture = (sShadows);
};

sampler SkyboxSampler = sampler_state {
    Texture = (sSkybox);
};

sampler DepthSampler = sampler_state {
    Texture = (sDepth);
};

sampler EmmisivesSampler = sampler_state {
    Texture = (sEmmisives);
};

struct VSInput
{
    float3 Position : POSITION0;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
};

struct PSInput
{
    float4 Position : POSITION0;
    float4 Diffuse : COLOR0;
    float2 TexCoord: TEXCOORD0;
};

PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;

    PS.Position = mul(float4(VS.Position, 1), gWorldViewProjection);
    PS.Diffuse = VS.Diffuse;
    PS.TexCoord = VS.TexCoord;

    return PS;
}

float4 PixelShaderFunction(PSInput PS) : COLOR0
{	
    float4 albedoColor = tex2D(AlbedoSampler, PS.TexCoord);
    float4 shadowColor = tex2D(ShadowSampler, PS.TexCoord);
    float4 skyboxColor = tex2D(SkyboxSampler, PS.TexCoord);
    float emmisivesColor = tex2D(EmmisivesSampler, PS.TexCoord).r;
    float depth = tex2D(DepthSampler, PS.TexCoord).r;
    
    float AOLevel = shadowColor.g;
    float isInShadow = shadowColor.b;
    isInShadow *= (1-emmisivesColor);
    
    float4 AOColor = lerp(fAOColor, fAOShadowColor, isInShadow);
    float4 ambientColor = lerp(fAmbientColor, AOColor, AOLevel);
    albedoColor.rgb = lerp(albedoColor.rgb * ambientColor, albedoColor.rgb * fLightColor.rgb, 1-isInShadow);

    albedoColor.rgb = lerp(albedoColor.rgb, skyboxColor.rgb, 1-albedoColor.a);
    albedoColor.a = 1;
    
    // add fog
    float fogFactor = saturate((depth - fFogStart) / fFogDistance);
    albedoColor.rgb = lerp(albedoColor.rgb, fFogColor.rgb, fogFactor);

    return albedoColor;
}

technique cube_post
{
    pass P0
    {
        VertexShader = compile vs_3_0 VertexShaderFunction();
        PixelShader  = compile ps_3_0 PixelShaderFunction();
    }
}