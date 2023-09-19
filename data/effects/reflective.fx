::Includes
#include "data/include/reflect.fx"
::end

::Variables
float sReflectPower = 0;
float sNorFac = .5;
texture sScreenTexture;

sampler ScreenSampler = sampler_state
{
    Texture = (sScreenTexture);
};
::end

::PixelShader(float3 texel)
float specular = max(MTACalculateSpecular(gCameraDirection, sLightDir, PS.Normal, 20) / 3, 0);
texel.rgb = texel.rgb + sLightColor * specular;

float3 viewDir = normalize(PS.WorldPos.xyz - gCameraPosition);
float3 reflectDir = normalize(reflect(viewDir, PS.Normal));
float3 currentRay = PS.WorldPos.xyz + reflectDir * sNorFac;
float farClip = gProjection[3][2] / (1 - gProjection[2][2]);
currentRay += 2 * gWorld[2].xyz * (1.0 + (PS.WorldPos.w / farClip));
float3 nuv = GetUV(currentRay, gViewProjection);

float camZFract = 1-dot(gCameraDirection, float3(0, 0, -1));
float zFract = dot(PS.Normal, float3(0, 0, 1));
float camFract = dot(reflectDir, gCameraDirection);

float3 reflectionColor = tex2D(ScreenSampler, nuv.xy).rgb;

for (int i = 0; i < 5; i++) reflectionColor += tex2D(ScreenSampler, nuv.xy + float2(0.001, 0.001) * i).rgb;

reflectionColor /= 5;

texel.rgb = lerp(texel.rgb, reflectionColor, zFract * camZFract * camFract * sReflectPower);
::end

::Emmisive(float4 emmisive)
emmisive.rgb = lerp(emmisive.rgb, float3(1, 1, 1), specular/3 * (texel.r+texel.g+texel.b)/3 * sReflectPower * zFract * camZFract * camFract);
::end