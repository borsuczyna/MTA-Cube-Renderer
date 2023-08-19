// Hey, borsuczyna here
// huge thanks to Ren712, who made this shader

#include "include/matrix.fx"

float3 sElementPosition = float3(0, 0, 0);
float2 fViewportSize = float2(800, 600);
float2 fViewportScale = float2(1, 1);
float2 fViewportPos = float2(0, 0);
float fShadowDepthCompare = -0.5;

float sZRotation = 0;
float2 sZRotationCenterOffset = float2(0, 0);

float2 sPixelSize = float2(0.00125, 0.00166);
float2 sTexSize = float2(800, 600);
float sAspectRatio = 800 / 600;

float3 sCameraPosition = float3(0,0,0);
float3 sCameraForward = float3(0,0,0);
float3 sCameraUp = float3(0,0,0);
float2 sClip = float2(0.3,300);
float2 sScrRes_1 = float2(800,600);
float2 sScrRes_2 = float2(800,600);
float2 sScrRes_3 = float2(800,600);
float2 sScrRes_4 = float2(800,600);

uniform float fMXAOAmbientOcclusionAmount = 2; // 2 Ambient Occlusion Amount (0 - 3)
uniform float fMXAOFadeoutStart = 0.8; // Fadeout start (0 -1)
uniform float fMXAOFadeoutEnd = 0.9; // Fadeout end (0 - 1)

#define AO_BLUR_GAMMA   2
#define fMXAOBlurSteps  2     // Blur Steps. Offset count for AO bilateral blur filter. Higher means smoother but also blurrier AO. (int 2 - 5)
#define fMXAOBlurSharpness 2.00 // 2 Blur Sharpness. AO sharpness, higher means sharper geometry edges but noisier AO, less means smoother AO but blurry in the distance. (0 - 5)

#define iMXAOBayerDitherLevel  5 // Dither Size (int 2 - 8)
uniform float fMXAOSampleRadius = 1.5; // 1.50 Sample radius of GI, higher means more large-scale occlusion with less fine-scale details.  (1 - 8)
#define iMXAOSampleCount 8 // Amount of MXAO samples. Higher means more accurate and less noisy AO at the cost of fps (int 8 - 255)
uniform float fMXAONormalBias = 0.2; // 0.2 Normal bias. Normals bias to reduce self-occlusion of surfaces that have a low angle to each other. (0 - 0.8)

texture sRTColor < string renderTarget = "yes"; >;
texture sRTNormal < string renderTarget = "yes"; >;
texture sRTShadows < string renderTarget = "yes"; >;
texture sRTDepth_1;
texture sRTDepth_2;
texture sRTDepth_3;
texture sRTDepth_4;
int iShadowPlanes = 3;

texture gDepthBuffer : DEPTHBUFFER;
float4x4 gProjection : PROJECTION;
float4x4 gView : VIEW;
float4x4 gViewInverse : VIEWINVERSE;
float3 gCameraPosition : CAMERAPOSITION;
int gFogEnable < string renderState="FOGENABLE"; >;
float4 gFogColor < string renderState="FOGCOLOR"; >;
float gFogStart < string renderState="FOGSTART"; >;
float gFogEnd < string renderState="FOGEND"; >;
int gCapsMaxAnisotropy < string deviceCaps="MaxAnisotropy"; >;
int CUSTOMFLAGS < string skipUnusedParameters = "yes"; >;

sampler2D SamplerColor = sampler_state
{
    Texture = (sRTColor);
    AddressU = Clamp;
    AddressV = Clamp;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
    MaxMipLevel = 0;
    MipMapLodBias = 0;
};

sampler2D SamplerNormal = sampler_state
{
    Texture = (sRTNormal);
    AddressU = Clamp;
    AddressV = Clamp;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
    MaxMipLevel = 0;
    MipMapLodBias = 0;
};

sampler SamplerDepth = sampler_state
{
    Texture = (gDepthBuffer);
    AddressU = Clamp;
    AddressV = Clamp;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
};

sampler SamplerShadows = sampler_state
{
    Texture = (sRTShadows);
    AddressU = Clamp;
    AddressV = Clamp;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
    MaxMipLevel = 0;
    MipMapLodBias = 0;
};

sampler SamplerCompare_1 = sampler_state 
{
    Texture = (sRTDepth_1);
};

sampler SamplerCompare_2 = sampler_state 
{
    Texture = (sRTDepth_2);
};

sampler SamplerCompare_3 = sampler_state 
{
    Texture = (sRTDepth_3);
};

sampler SamplerCompare_4 = sampler_state 
{
    Texture = (sRTDepth_4);
};

struct VSInput
{
    float3 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float4 Diffuse : COLOR0;
};

struct PSInput
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float2 PixPos : TEXCOORD1;
    float4 Diffuse : COLOR0;
};

PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;

    VS.Position.xyz -= sElementPosition;
	
    VS.Position.xy -= 0.5 + sZRotationCenterOffset;
    VS.Position.xyz = mul(float4(VS.Position.xyz, 1), makeZRotation(sZRotation)).xyz;	
    VS.Position.xy += 0.5 + sZRotationCenterOffset;	
	
    VS.Position.xy *= fViewportSize;

    float4x4 sProjection = createImageProjectionMatrix(fViewportPos, fViewportSize, fViewportScale, 1000, 100, 10000);
	
    float4 viewPos = mul(float4(VS.Position.xyz, 1), makeTranslation(float3(0,0, 1000)));
    PS.Position = mul(viewPos, sProjection);

    PS.TexCoord = float2(1 - VS.TexCoord.x, VS.TexCoord.y);
	
    PS.PixPos = VS.Position.xy;
	
    PS.Diffuse = VS.Diffuse;
	
    return PS;
}

float FetchDepthBufferValue( float2 uv )
{
    float4 texel = tex2D(SamplerDepth, uv);
#if IS_DEPTHBUFFER_RAWZ
    float3 rawval = floor(255.0 * texel.arg + 0.5);
    float3 valueScaler = float3(0.996093809371817670572857294849, 0.0038909914428586627756752238080039, 1.5199185323666651467481343000015e-5);
    return dot(rawval, valueScaler / 255.0);
#else
    return texel.r;
#endif
}

float Linearize(float posZ)
{
    return gProjection[3][2] / (posZ - gProjection[2][2]);
}

float3 GetPosition(float2 coords)
{
    return float3(coords.xy * 2 - 1,1.0) * Linearize(FetchDepthBufferValue(coords.xy));
}

float3 VSPositionFromDepth(float2 vTexCoord, float4x4 g_matInvProjection)
{
    float z = FetchDepthBufferValue(vTexCoord); 
    float x = vTexCoord.x * 2 - 1;
    float y = (1 - vTexCoord.y) * 2 - 1;
    float4 vProjectedPos = float4(x, y, z, 1.0f);
    float4 vPositionVS = mul(vProjectedPos, g_matInvProjection);  
    return vPositionVS.xyz / vPositionVS.w;  
}

float3 GetNormalFromDepth(float2 coords)
{
    float3 offs = float3(sPixelSize.xy, 0);

    float3 f = GetPosition(coords.xy);
    float3 d_dx1 = - f + GetPosition(coords.xy + offs.xz);
    float3 d_dx2 =   f - GetPosition(coords.xy - offs.xz);
    float3 d_dy1 = - f + GetPosition(coords.xy + offs.zy);
    float3 d_dy2 =   f - GetPosition(coords.xy - offs.zy);

    d_dx1 = lerp(d_dx1, d_dx2, abs(d_dx1.z) > abs(d_dx2.z));
    d_dy1 = lerp(d_dy1, d_dy2, abs(d_dy1.z) > abs(d_dy2.z));

    float3 ddxDdy = normalize(cross(d_dy1, d_dx1));
    return  float3(ddxDdy.x, -ddxDdy.y, ddxDdy.z);
}

float3 GetNormalFromDepthProjection(float2 coords, float4x4 g_matInvProjection)
{
    float3 offs = float3(sPixelSize.xy, 0);

    float3 f = VSPositionFromDepth(coords.xy, g_matInvProjection);
    float3 d_dx1 = - f + VSPositionFromDepth(coords.xy + offs.xz, g_matInvProjection);
    float3 d_dx2 =   f - VSPositionFromDepth(coords.xy - offs.xz, g_matInvProjection);
    float3 d_dy1 = - f + VSPositionFromDepth(coords.xy + offs.zy, g_matInvProjection);
    float3 d_dy2 =   f - VSPositionFromDepth(coords.xy - offs.zy, g_matInvProjection);

    d_dx1 = lerp(d_dx1, d_dx2, abs(d_dx1.z) > abs(d_dx2.z));
    d_dy1 = lerp(d_dy1, d_dy2, abs(d_dy1.z) > abs(d_dy2.z));

    return (- normalize(cross(d_dy1, d_dx1)));
}

float3 UnitToColor24New(in float depth) 
{
    const float3 scale	= float3(1.0, 256.0, 65536.0);
    const float2 ogb	= float2(65536.0, 256.0) / 16777215.0;
    const float normal	= 256.0 / 255.0;
	
    float3 unit	= (float3)depth;
    unit.gb	-= floor(unit.gb / ogb) * ogb;
	
    float3 color = unit * scale;
    color = frac(color);
    color *= normal;
    color.rg -= color.gb / 256.0;

    return color;
}

float ColorToUnit24New(in float3 color) {
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
    float dist = (unit * (farClip - nearClip)) + nearClip;
    return dist;
}

struct PixelType3
{
    float4 World : COLOR0;      // Render target #0
    float4 Color : COLOR1;      // Render target #1
    float4 Normal : COLOR2;      // Render target #2
    float4 Shadows : COLOR3;      // Render target #3
};

struct PixelType2
{
    float4 World : COLOR0;      // Render target #0
    float4 Color : COLOR1;      // Render target #1
    float4 Normal : COLOR2;      // Render target #2
};

struct PixelType1
{
    float4 World : COLOR0;      // Render target #0
    float4 Color : COLOR1;      // Render target #1
};

float2 GetShadowProjection(float2 sScrRes, float4 viewPosProj) {
    float4x4 sProjectionProj = createOrthographicProjectionMatrix(-sClip.y, sClip.y, sScrRes.x, sScrRes.y);
    float4 projPosProj = mul(viewPosProj, sProjectionProj);
    float projX = (0.5 * (projPosProj.w + projPosProj.x));
    float projY = (0.5 * (projPosProj.w - projPosProj.y));
    return float2(projX, projY) / projPosProj.w;
}

float ProcessShadowProjection(float2 projCoord, sampler2D SamplerCompare, float sClipNear, float sClipFar) {
    if((projCoord.x >= 0) && (projCoord.x <= 1) && (projCoord.y >= 0) && (projCoord.y <= 1)) {
        float3 packedDepth = tex2D(SamplerCompare, projCoord.xy).rgb;
        float unpackedDepth = ColorToUnit24New(packedDepth.rgb);
        return UnitToDist(unpackedDepth, sClipNear, sClipFar);
    } else {
        return UnitToDist(16777215, sClipNear, sClipFar);
    }
}

bool IsInShadowProjectionRange(float2 projCoord) {
    return ((projCoord.x >= 0) && (projCoord.x <= 1) && (projCoord.y >= 0) && (projCoord.y <= 1));
}

PixelType2 PixelShaderFunctionShadow(PSInput PS)
{
    PixelType2 Output;

    float BufferValue = FetchDepthBufferValue(PS.TexCoord.xy);
    if (BufferValue > 0.9999) {
        Output.Color = float4(1, 0, 0, 1);
        Output.World = 0;
        Output.Normal = 0;
        return Output;		
    }

    float4x4 sProjectionInverse = inverseMatrix(gProjection);
    float4x4 sViewProjectionInverse = mul(gViewInverse, sProjectionInverse);

    float3 viewPos = VSPositionFromDepth(PS.TexCoord, sProjectionInverse);
    float3 worldPos = mul(float4(viewPos, 1), gViewInverse).xyz;
    float3 viewNormal = GetNormalFromDepthProjection(PS.TexCoord.xy, sProjectionInverse);
    float3 worldNormal = mul(viewNormal, (float3x3)gViewInverse).xyz;
    float3 cameraForward = normalize(sCameraForward);
	
    float camDist = distance( gCameraPosition, worldPos.xyz ) / Linearize(1);
    float3 LDotN =  -dot(cameraForward, worldNormal);

    // Project to screen space
    float4x4 sViewProj = createViewMatrix(sCameraPosition, cameraForward, normalize(sCameraUp));
    float4 viewPosProj = mul(float4(worldPos, 1), sViewProj);

    float2 projCoord_1 = GetShadowProjection(sScrRes_1, viewPosProj);
    float2 projCoord_2 = GetShadowProjection(sScrRes_2, viewPosProj);
    float2 projCoord_3 = GetShadowProjection(sScrRes_3, viewPosProj);
    float2 projCoord_4 = GetShadowProjection(sScrRes_4, viewPosProj);

    // Fetch or compute normal
    float3 normalTex = tex2D(SamplerNormal, PS.TexCoord.xy).xyz;
    if (length(normalTex) < 0.5)
        Output.Normal = float4((worldNormal * 0.5) + 0.5, 1);
    else {
        Output.Normal = 0;
        worldNormal = (normalTex - 0.5) * 2;
    }

    if (IsInShadowProjectionRange(projCoord_4)) {
        float pixDist = viewPosProj.z / viewPosProj.w;
        float linDepth = 0;

        if(IsInShadowProjectionRange(projCoord_1) && iShadowPlanes >= 1) linDepth = ProcessShadowProjection(projCoord_1, SamplerCompare_1, sClip.x, sClip.y);
        else if(IsInShadowProjectionRange(projCoord_2) && iShadowPlanes >= 2) linDepth = ProcessShadowProjection(projCoord_2, SamplerCompare_2, sClip.x, sClip.y);
        else if(IsInShadowProjectionRange(projCoord_3) && iShadowPlanes >= 3) linDepth = ProcessShadowProjection(projCoord_3, SamplerCompare_3, sClip.x, sClip.y);
        else if(IsInShadowProjectionRange(projCoord_4) && iShadowPlanes >= 4) linDepth = ProcessShadowProjection(projCoord_4, SamplerCompare_4, sClip.x, sClip.y);
        else linDepth = UnitToDist(16777215, sClip.x, sClip.y);
        
        float depthDif = max(0, linDepth.x - pixDist.x - fShadowDepthCompare);
        depthDif = min(LDotN, depthDif);
        float inverseDepthDif = min(LDotN + 0.2, depthDif);

        Output.World = 0;
        Output.Color = float4(depthDif, camDist, 0, 1);
    } else {
        Output.World = 0;
        Output.Color = float4(1, camDist, 0, 1);
    }

    return Output;
}

float GetBayerFromCoordLevel(float2 pixelpos)
{
    float finalBayer = 0.0;

    for(float i = 1-iMXAOBayerDitherLevel; i<= 0; i++)
    {
        float bayerSize = exp2(i);
        float2 bayerCoord = floor(pixelpos * bayerSize) % 2.0;
        float bayer = 2.0 * bayerCoord.x - 4.0 * bayerCoord.x * bayerCoord.y + 3.0 * bayerCoord.y;
        finalBayer += exp2(2.0*(i+iMXAOBayerDitherLevel))* bayer;
    }

    float finalDivisor = 4.0 * exp2(2.0 * iMXAOBayerDitherLevel) - 4.0;
    return finalBayer / finalDivisor + 1.0/exp2(2.0 * iMXAOBayerDitherLevel);
}

PixelType1 PixelShaderFunctionAO(PSInput PS)
{
    PixelType1 Output;

    float4x4 sProjectionInverse = inverseMatrix(gProjection);
	
    float3 viewPos = VSPositionFromDepth(PS.TexCoord.xy, sProjectionInverse);
    float4 worldPos = mul(float4(viewPos.xyz, 1), gViewInverse);
	
    float camDist = distance( gCameraPosition, worldPos.xyz ) / Linearize(1);

    float3 ScreenSpaceNormals = GetNormalFromDepth(PS.TexCoord.xy);
    ScreenSpaceNormals.y = - ScreenSpaceNormals.y;

    float radiusJitter	= GetBayerFromCoordLevel(PS.PixPos.xy);

    float3 ScreenSpacePosition = GetPosition(PS.TexCoord.xy);

    float scenedepth = ScreenSpacePosition.z / Linearize(1);
    ScreenSpacePosition += ScreenSpaceNormals * scenedepth;

    float SampleRadiusScaled  = 0.2 * fMXAOSampleRadius * fMXAOSampleRadius / (iMXAOSampleCount * ScreenSpacePosition.z);
    float mipFactor = SampleRadiusScaled * 3200.0;

    float2 currentVector;
    sincos(2.0*3.14159274*radiusJitter, currentVector.y, currentVector.x);
    static const float fNegInvR2 = -1.0 / (fMXAOSampleRadius * fMXAOSampleRadius);
    currentVector *= SampleRadiusScaled;			  
			  
    float AO = 0.0;
    float2 currentOffset;

    for(int iSample=0; iSample < iMXAOSampleCount; iSample++)
    {
        currentVector = mul(currentVector.xy, float2x2(0.575, 0.81815, -0.81815, 0.575));
        currentOffset = PS.TexCoord.xy + currentVector.xy * float2(1.0, sAspectRatio) * (iSample + radiusJitter);

        float mipLevel = saturate(log2(mipFactor * iSample) * 0.2 - 0.6) * 5.0;
		
        float3 posLod = GetPosition(currentOffset.xy);
        float3 occlVec = -ScreenSpacePosition + posLod;

        float  occlDistanceRcp 	= rsqrt(dot(occlVec, occlVec));
        float  occlAngle = dot(occlVec, ScreenSpaceNormals) * occlDistanceRcp;

        float fAO = saturate(1.0 + fNegInvR2 / occlDistanceRcp)  * saturate(occlAngle - fMXAONormalBias);

        AO += fAO;
    }

    float res = saturate(AO/(0.4 * (1.0 - fMXAONormalBias)*iMXAOSampleCount * sqrt(fMXAOSampleRadius)));			  
		  
    res = pow(abs(res), 1.0 / AO_BLUR_GAMMA);
	
    float Color = tex2D(SamplerColor, PS.TexCoord.xy).x;
    float AOLevel = res;
    float isInShadow = 1-Color*2;
    res = saturate(1  - 1.7 * res) * Color;
	
    Output.Color = float4(res, isInShadow, AOLevel, 1);
    Output.World = 0;
    return Output;
}

float GetBlurWeight(float4 tempKey, float4 centerKey, float surfacealignment)
{
    float depthdiff = abs(tempKey.w-centerKey.w) * Linearize(1);
    float normaldiff = 1 - saturate(dot(normalize(tempKey.xyz),normalize(centerKey.xyz)));

    float depthweight = saturate(rcp(fMXAOBlurSharpness*depthdiff*5.0*surfacealignment));
    float normalweight = saturate(rcp(fMXAOBlurSharpness*normaldiff*10.0));
	
    return min(normalweight,depthweight);
}

PixelType1 PixelShaderFunctionBlur1(PSInput PS)
{
    PixelType1 Output;

    float4 tempsample;
    float4 centerkey , tempkey;
    float  centerweight, tempweight;
    float surfacealignment;
    float4 blurcoord = 0.0;
    float AO = 0.0;
	
    float3 normalTex = tex2D(SamplerNormal, PS.TexCoord.xy).xyz;
    float3 ScreenSpaceNormals = (normalTex - 0.5) * 2;
	
    float camDist = tex2D(SamplerColor, PS.TexCoord.xy).y;

    float LinearDepth = Linearize(FetchDepthBufferValue(PS.TexCoord.xy)) / Linearize(1);

    centerkey = float4(ScreenSpaceNormals, LinearDepth);
    centerweight  = 0.5;
    AO = tex2D(SamplerColor, PS.TexCoord.xy).x * 0.5;
    surfacealignment = saturate(-dot(centerkey.xyz, normalize(float3(PS.TexCoord.xy * 2.0 - 1.0, 1.0) * centerkey.w)));

    for(int orientation=-1; orientation<=1; orientation+=2)
    {
        for(float iStep = 1.0; iStep <= fMXAOBlurSteps; iStep++)
        {
            blurcoord.xy = (2.0 * iStep - 0.5) * orientation * float2(1.0,0.0) * sPixelSize + PS.TexCoord.xy;
					
            tempsample.xyz = (tex2D(SamplerNormal, blurcoord.xy).xyz - 0.5) * 2;

            tempsample.w = tex2D(SamplerColor, blurcoord.xy).x;
            float blurDepth = Linearize(FetchDepthBufferValue(blurcoord.xy)) / Linearize(1);
            tempkey = float4(tempsample.xyz, blurDepth);
            tempweight = GetBlurWeight(tempkey, centerkey, surfacealignment);
            AO += tempsample.w * tempweight;
            centerweight   += tempweight;
        }
    }

    float AOLevel = tex2D(SamplerColor, PS.TexCoord.xy).z;
    Output.Color = float4(AO / centerweight, 1, AOLevel, 1);
    Output.World = float4(0, 0, 0, 0.01);

    return Output;
}

PixelType3 PixelShaderFunctionBlur2(PSInput PS)
{
    PixelType3 Output;
    Output.World = float4(0, 0, 0, 0);
    Output.Color = float4(0, 0, 0, 0);
    Output.Normal = float4(0, 0, 0, 0);
    Output.Shadows = float4(0, 0, 0, 0);

    float Depth = FetchDepthBufferValue(PS.TexCoord);
    if (Depth > 0.99999) return Output;
	
    float4 tempsample;
    float4 centerkey , tempkey;
    float  centerweight, tempweight;
    float surfacealignment;
    float4 blurcoord = 0.0;
    float AO  = 0.0;

    float2 addSampler = float2(0.001, 0.001);
    float3 ScreenSpaceNormals = (tex2D(SamplerNormal, PS.TexCoord.xy).xyz - 0.5) * 2;
	
    float LinearDepth = Linearize(Depth) / Linearize(1);

    centerkey = float4(ScreenSpaceNormals, LinearDepth);
    centerweight  = 0.5;
    AO = tex2D(SamplerColor,PS.TexCoord.xy).x * 0.5;
    surfacealignment = saturate(-dot(centerkey.xyz, normalize(float3(PS.TexCoord.xy * 2.0 - 1.0, 1.0)*centerkey.w)));

    for(int orientation=-1; orientation<=1; orientation+=2)
    {
        for(float iStep = 1.0; iStep <= fMXAOBlurSteps; iStep++)
        {
            blurcoord.xy = (2.0 * iStep - 0.5) * orientation * float2(0.0,1.0) * sPixelSize + PS.TexCoord.xy;
			
            tempsample.xyz = (tex2D(SamplerNormal, blurcoord.xy).xyz - 0.5) * 2;
			
            tempsample.w = tex2D(SamplerColor, blurcoord.xy).x;
            float blurDepth = Linearize(FetchDepthBufferValue(blurcoord.xy))/ Linearize(1);
            tempkey = float4(tempsample.xyz, blurDepth);
            tempweight = GetBlurWeight(tempkey, centerkey, surfacealignment);
            AO += tempsample.w * tempweight;
            centerweight += tempweight;
        }
    }

    AO = pow(AO / centerweight,AO_BLUR_GAMMA);

    AO = 1.0-pow(1.0-AO, fMXAOAmbientOcclusionAmount*4.0);

    // float fadeStart = min(fMXAOFadeoutStart, gFogStart / Linearize(1));
    // AO = lerp(AO, 0.0,smoothstep(fadeStart, fMXAOFadeoutEnd, LinearDepth));
    // if(AO > gFogEnd) 

    float GI = AO;
    GI = max(0.0,1-GI);
	
    float FogAmount = 1;

    float AOLevel = tex2D(SamplerColor, PS.TexCoord.xy).z;
    float isInShadow = .9;
    Output.Shadows = float4(1, AOLevel, GI*FogAmount, 1);
    // Output.World = lerp(float4(0, 0, 0, 1), float4(1, AOLevel, isInShadow, 1), GI*FogAmount);
    Output.World = float4(0, 0, 0, 0.01);
	return Output;
}

technique dxDrawMaterial2DShadowMapping
{
    pass P0
    {
        ZEnable = false;
        ZWriteEnable = false;
        CullMode = 2;
        ShadeMode = Gouraud;
        AlphaBlendEnable = true;
        SrcBlend = SrcAlpha;
        DestBlend = InvSrcAlpha;
        AlphaTestEnable = false;
        AlphaRef = 1;
        AlphaFunc = GreaterEqual;
        Lighting = false;
        FogEnable = false;
        VertexShader = compile vs_3_0 VertexShaderFunction();
        PixelShader  = compile ps_3_0 PixelShaderFunctionShadow();
    }
    pass P1
    {
        ZEnable = false;
        ZWriteEnable = false;
        CullMode = 2;
        ShadeMode = Gouraud;
        AlphaBlendEnable = true;
        SrcBlend = SrcAlpha;
        DestBlend = InvSrcAlpha;
        AlphaTestEnable = false;
        AlphaRef = 1;
        AlphaFunc = GreaterEqual;
        Lighting = false;
        FogEnable = false;
        VertexShader = compile vs_3_0 VertexShaderFunction();
        PixelShader  = compile ps_3_0 PixelShaderFunctionAO();
    }
    pass P2
    {
        ZEnable = false;
        ZWriteEnable = false;
        CullMode = 2;
        ShadeMode = Gouraud;
        AlphaBlendEnable = true;
        SrcBlend = SrcAlpha;
        DestBlend = InvSrcAlpha;
        AlphaTestEnable = false;
        AlphaRef = 1;
        AlphaFunc = GreaterEqual;
        Lighting = false;
        FogEnable = false;
        VertexShader = compile vs_3_0 VertexShaderFunction();
        PixelShader  = compile ps_3_0 PixelShaderFunctionBlur1();
    }
    pass P3
    {
        ZEnable = false;
        ZWriteEnable = false;
        CullMode = 2;
        ShadeMode = Gouraud;
        AlphaBlendEnable = true;
        SrcBlend = SrcAlpha;
        DestBlend = InvSrcAlpha;
        AlphaTestEnable = true;
        AlphaRef = 1;
        AlphaFunc = GreaterEqual;
        Lighting = false;
        FogEnable = false;
        VertexShader = compile vs_3_0 VertexShaderFunction();
        PixelShader  = compile ps_3_0 PixelShaderFunctionBlur2();
    }
} 

technique fallback {
    pass P0 {}
}