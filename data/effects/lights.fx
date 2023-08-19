::Variables
float3 sEmisiveColor = float3(1.0f, 1.0f, 1.0f);
float sEmmisivePower = 1.0f;
float sEmmisivePow = 1.0f;
::end

::PixelShader(float3 color)
texel.rgb *= sEmisiveColor;
texel.rgb = pow(texel.rgb, 0.1);
::end

::Emmisive(float4 emmisive)
emmisive = float4(sEmmisivePower, sEmmisivePower, sEmmisivePower, 1);
::end