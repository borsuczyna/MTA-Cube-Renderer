::Variables
float3 sEmisiveColor = float3(1.0f, 1.0f, 1.0f);
float sEmmisivePower = 1.0f;
float2 sEmmisivePow = float2(1, 1);
::end

::PixelShader(float3 texel)
texel.rgb *= sEmisiveColor;
texel.rgb = pow(texel.rgb/sEmmisivePow.x, sEmmisivePow.y);
::end

::Emmisive(float4 emmisive)
emmisive = float4(sEmmisivePower, sEmmisivePower, sEmmisivePower, 1);
::end