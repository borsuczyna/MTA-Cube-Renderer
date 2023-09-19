texture gDepthBuffer : DEPTHBUFFER;

sampler SamplerDepth = sampler_state
{
	Texture = (gDepthBuffer);
	MinFilter = Point;
	MagFilter = Point;
	MipFilter = None;
	AddressU = Clamp;
	AddressV = Clamp;
};

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