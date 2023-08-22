float3 AffectByLight(float3 inColor, float3 worldPos, float3 worldNormal, float3 lightPos, float3 lightColor, float lightSize, float3 lightDir, bool spotlight, float lLightPhi, float lightTheta, float lightFalloff, in out float3 color)
{
    float fDistance = distance(lightPos, worldPos);
    float fAttenuation = 1 - saturate(fDistance / lightSize);
    fAttenuation = pow(fAttenuation, 2);

    float3 vLight = normalize(lightPos - worldPos);
    float angle = acos(dot(-vLight, normalize(lightDir.xyz)));

    if(spotlight) {
        float fSpotAtten = 0.0f;
        if(angle > lLightPhi) fSpotAtten = 0.0f;
        else if(angle < lightTheta) fSpotAtten = 1.0f;
        else fSpotAtten = pow(smoothstep(lLightPhi, lightTheta, angle), lightFalloff);
        
        fAttenuation *= fSpotAtten;
    }

    float dotProduct = dot(worldNormal, vLight);
    fAttenuation *= max(dotProduct, 0);

    inColor = lerp(inColor*lightColor, inColor, 1-fAttenuation);
    color = lerp(lightColor, float3(0, 0, 0), 1-fAttenuation);

    return inColor;
}