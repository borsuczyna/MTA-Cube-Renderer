float textureSize = 256.0f;
float normalPower = 5;

float4 tex2DGrayScale(sampler textureSampler, float2 texCoord)
{
    float4 color = tex2D(textureSampler, texCoord);
    float gray = dot(color.rgb, float3(0.299f, 0.587f, 0.114f));
    return float4(gray, gray, gray, color.a);
}

float3 tex2DNormal(sampler textureSampler, float2 texCoord)
{
    // Sample the height map texture
    float heightCenter = tex2DGrayScale(textureSampler, texCoord).r;
    float heightLeft = tex2DGrayScale(textureSampler, texCoord - float2(1.0f, 0.0f) / textureSize).r;
    float heightRight = tex2DGrayScale(textureSampler, texCoord + float2(1.0f, 0.0f) / textureSize).r;
    float heightUp = tex2DGrayScale(textureSampler, texCoord - float2(0.0f, 1.0f) / textureSize).r;
    float heightDown = tex2DGrayScale(textureSampler, texCoord + float2(0.0f, 1.0f) / textureSize).r;

    // Calculate the gradient in the height map
    // use heightCenter
    float3 gradient = float3(
        0.5f + max(min((heightCenter - heightLeft) * normalPower, 0.02), -0.03),
        0.5f + max(min((heightCenter - heightDown) * normalPower, 0.02), -0.03),
        1
    );

    // Normalize the gradient to get the normal
    float3 normal = normalize(gradient);

    return normal;
}