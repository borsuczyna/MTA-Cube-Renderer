::Variables
float3 sEmisiveColor = float3(1.0f, 1.0f, 1.0f);
float sEmmisivePower = 1.0f;
float2 sEmmisivePow = float2(1, 1);
float4 sEmmisiveTexCoord = float4(0, 0, 1, 1);
::end

::PixelShader(float3 texel)
if(PS.TexCoord.x >= sEmmisiveTexCoord.x && PS.TexCoord.x <= sEmmisiveTexCoord.x + sEmmisiveTexCoord.z && PS.TexCoord.y >= sEmmisiveTexCoord.y && PS.TexCoord.y <= sEmmisiveTexCoord.y + sEmmisiveTexCoord.w) {
    texel.rgb *= sEmisiveColor;
    texel.rgb = pow(texel.rgb/sEmmisivePow.x, sEmmisivePow.y);
}
::end

::Emmisive(float4 emmisive)
if(PS.TexCoord.x >= sEmmisiveTexCoord.x && PS.TexCoord.x <= sEmmisiveTexCoord.x + sEmmisiveTexCoord.z && PS.TexCoord.y >= sEmmisiveTexCoord.y && PS.TexCoord.y <= sEmmisiveTexCoord.y + sEmmisiveTexCoord.w) 
    emmisive = float4(sEmmisivePower, sEmmisivePower, sEmmisivePower, 1);
::end