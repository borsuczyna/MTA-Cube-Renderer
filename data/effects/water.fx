// Hey, borsuczyna here
// Special thanks to Einheit-101
// this shader is modified Open Source Water Shader (osws)
// https://forum.multitheftauto.com/topic/126396-osws-the-new-mta-community-water-shader-project/

::Includes
#include "data/include/reflect.fx"
#include "data/include/matrix.fx"
#include "data/include/depth.fx"
::end

::Variables
int gCapsMaxAnisotropy < string deviceCaps="MaxAnisotropy"; >;

static const int rays = 6;
float deepness = 0.5;
float2 sPixelSize = float2(0.01,0.01);
texture screenInput;
texture normalTexture;
texture foamTexture;
float flowSpeed = 0.5;
float reflectionSharpness = 0.6;
float reflectionStrength = 0.7;
float refractionStrength = 0.1;
float causticSpeed = 0.3;
float causticStrength = 0.2;
float causticIterations = 20;
float4 waterColor = float4(1.5, 1.5, 1.5, 1);
float4 reflectionDiffuse = float4(1.5, 1.5, 1.5, 1);
float dayTime = 1.0;
float specularSize = 6;
float waterShiningPower = 1;

#define mod(x, y) (x - y * floor(x / y))

sampler2D screenSampler = sampler_state
{
	Texture = <screenInput>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = Mirror;
	AddressV = Mirror;
};

sampler2D foamSampler = sampler_state
{
	Texture = <foamTexture>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = Wrap;
	AddressV = Wrap;
};

sampler NormalSampler = sampler_state
{
	Texture = <normalTexture>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = Wrap;
	AddressV = Wrap;
};
::end

::PSInput
float4 RefractionPos : TEXCOORD3;
float4 VertexPos : TEXCOORD4;
::end

::VertexShader
matrix projection = mul(gWorldViewProjection, gWorld);
projection = mul(gWorld, projection);

PS.RefractionPos = mul(VS.Position, projection);
PS.VertexPos = mul(VS.Position, gWorldViewProjection);
::end

::PixelShader(float4 texel)
float2 refractTexCoord;
float timer = (gTime/12) * flowSpeed;
float Depth = PS.VertexPos.z / PS.VertexPos.w;

float2 txcoord = (PS.VertexPos.xy / PS.VertexPos.w) * float2(0.5, -0.5) + 0.5;
txcoord += 0.5 * sPixelSize;

//Add shore foam
float scaling = 0.005;
float speed = 4;
float2 foamCoords = PS.TexCoord*2;// Tile the foam texture to make it look more detailed
foamCoords.x += sin ((foamCoords.x + foamCoords.y) * 22 + gTime * speed) * scaling;
foamCoords.x += cos (foamCoords.y * 22 + gTime * speed) * scaling;
float4 foamColor = tex2D(foamSampler, foamCoords);

// Sample the normal from the normal map texture.
float2 movingTextureCoords = PS.TexCoord*2;
movingTextureCoords.y = movingTextureCoords.y + timer;
float3 normalMap = tex2D(NormalSampler, movingTextureCoords);

// Expand the range of the normal from (0,1) to (-1,+1).
normalMap = normalMap * 2 - 1;

// Calculate the projected refraction texture coordinates.
refractTexCoord.x = PS.RefractionPos.x / PS.RefractionPos.w / 2.0 + 0.5;
refractTexCoord.y = -PS.RefractionPos.y / PS.RefractionPos.w / 2.0 + 0.5;

// LOOP TO ADD REFLECTION HERE
float4 reflectionColor = waterColor;
if (gCameraPosition.z > PS.WorldPos.z) {// only reflect when camera is above water
	float3 viewDir = normalize(PS.WorldPos - gCameraPosition);// get to pixel view direction
	float3 reflectDir = normalize(reflect(viewDir, PS.Normal));// reflection direction
	float3 currentRay = 0;
	float2 nuv = 0;
	float d = 0;
	
	// It looks like we need to multiply L with a number that gets manipulated by the angle in which we are looking at the water. Lets call it viewMult
	float camHeight = length(PS.WorldPos.z - gCameraPosition.z);
	float viewMult = 7 * (1+viewDir.y) / max(1, camHeight * 0.5);
	float L = FetchDepthBufferValue(PS.TexCoord) * (6 + viewMult);// This calculation makes literally no sense, but it successfully fights artifacts of vehicles and others
	
	//Maybe someone can come up with a better solution than above or below
	
	for(int i = 0; i < rays; i++)// cast rays for reflection - the used method is by far not perfect
	{
		currentRay = PS.WorldPos + reflectDir * L;
		nuv = GetUV(currentRay, gViewProjection);
		d = FetchDepthBufferValue(nuv);
	
		float3 newPosition = GetPosition(nuv, d);
		L = length(PS.WorldPos - newPosition);
	}
	
	// Currently we get some flickering pixels because 2 pixels from the main view can be merged into our final reflection result and the computer does not know which
	// pixel should prevail. We can solve this by sorting the projection from top-to-bottom so we only write the pixel closer to the water plane. But i dont know how to do this.
	// Ghost recon wildlands reflections use the InterlockedMax function, but i dont know how to implement this here:
	
	// Read-write max when accessing the projection hash UAV
	// uint projectionHash = SrcPosPixel.y << 16 | SrcPosPixel.x;
	// InterlockedMax(ProjectionHashUAV[ReflPosPixel], projectionHash, dontCare);
	
	
	// Re-position the reflection coordinate sampling position by the normal map value to simulate the rippling wave effect.
	nuv = nuv + normalMap.xy * reflectionSharpness;
	
	float err = 0;
	if ((d > 0.9999) || (Depth > 0.9999)) err = 1; // Prevent reflection of background and objects too far away, if you want
	if (Depth > d) err = 1; // Prevent reflection of objects that are actually in front of the water and not behind it

	//TODO -----> implement edge stretching to fill reflection gaps on the screen sides! They do it in ghost recon wildlands, but i have no idea how to implement it here: 
	//http://remi-genin.fr/blog/screen-space-plane-indexed-reflection-in-ghost-recon-wildlands/
	
	
	// create corona-like mask around reflection edges to obscure artifacts
	float dy = 1/2 - (nuv.y - 0.5);
	float dist = pow(dy * dy, 0.5);
	float distFromCenter = 0.5 - dist;
	int fadingStrength = 5;
	float mask = 1 - saturate(distFromCenter * fadingStrength);

	float fresnel = saturate(1.5 * dot(viewDir, -PS.Normal));
	reflectionColor = lerp(tex2D(screenSampler, nuv), waterColor, mask);	// lerp between new reflection and water color with the corona mask
	reflectionColor = lerp(reflectionColor, waterColor, fresnel);			// lerp between reflection and fresnel value to make the reflection slowly lose color
	reflectionColor = lerp(reflectionColor, waterColor, err);				// lerp between reflection and water color to filter out reflection artifacts
	reflectionColor = lerp(waterColor, reflectionColor, reflectionStrength);// lerp between water color and reflection color according to the reflection strength setting
}

//Create water caustics, originally made by genius "Dave Hoskins" @ https://www.shadertoy.com/view/MdlXz8
float2 p = mod(movingTextureCoords * 6.28318530718, 6.28318530718) - 350;
float2 i = p;
float c = 0.3 * causticIterations;
float inten = 0.01;
for (int n = 0; n < causticIterations; n++) 
{
	float t = gTime * causticSpeed * (1 - 3.5 / (n+1));
	i = p + float2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
	c += 1.0/length(float2(p.x / (sin(i.x+t)/inten), p.y / (cos(i.y+t)/inten)));
}
c = 1.17 - pow(c / causticIterations, 1.4);
float colour = saturate(pow(abs(c), 8.0) * causticStrength + 0.1);
float4 causticColor = float4(colour, colour, colour, 1);

float4 refractionColor = tex2D(screenSampler, refractTexCoord + normalMap.xy) * refractionStrength;
// TO DO: Add refraction of stuff below water surface, but i dont think that this is possible


float3 lightDirection = normalize(sLightDir);

// Using Blinn half angle modification for performance over correctness
float specularBase = saturate(dot(float3(0.8,0.8,0.4), normalMap)) * 0.1;
float3 lightRange = normalize(normalize(gCameraPosition - PS.WorldPos) - lightDirection);
float specularLight = pow(saturate(dot(lightRange, normalMap)), specularSize);
float specularAcceleration = pow(saturate(dot(lightRange, normalMap)), 100);
float3 specularColor = sLightColor * specularLight;
specularColor = saturate(specularColor + pow(saturate(dot(lightRange, PS.Normal)), specularSize * 3)) * 0.5 * specularColor;
specularColor = saturate(specularColor + specularAcceleration + float3(specularBase, specularBase, specularBase)) * specularColor;

float cameraDepth = max(0.915, FetchDepthBufferValue(txcoord));// clamp cameraDepth to at least 0.915 to avoid flickering issues close to the camera
Depth = 1.0 / (1 - Depth);
float planardepth = 1.0 / (1 - cameraDepth);
float waterDepth = min(10, planardepth - Depth);// Calculates a value between 0 and 10

foamColor.a = waterDepth * 0.9 * waterColor.a;

// Combine water color, refraction, foam and caustics to the finalColor.
float4 finalColor = (refractionColor + waterColor) * causticColor * reflectionColor;
finalColor.a = waterDepth * deepness * waterColor.a;
finalColor = lerp(foamColor, finalColor, smoothstep(0, 2, waterDepth));
finalColor.rgb *= saturate(0.15 + dayTime);
finalColor.rgb = saturate(finalColor.rgb + specularColor * waterShiningPower);

texel.rgba = finalColor.rgba;
::end

::Emmisive(float4 emmisive)
emmisive.rgb += specularLight/3;
::end