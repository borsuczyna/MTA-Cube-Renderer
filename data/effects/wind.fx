::Includes
#include "data/include/noise.fx"
::end

::Variables
float Time;
float2 fWindDirection = float2(1, -1);
float fWindStrength = 3;
float fWindSpeed = 2;
float fWindNoiseSize = 0.5;
float fTreeZOffset = 0;
float fTreeHeight = 14;
bool isTreeLog = false;
::end

::WorldPosition(float3 worldPos)
float time = Time%%10000;
float2 windPosition = time * fWindSpeed * float2(fWindDirection.x, -fWindDirection.y) + worldPos.xy / 10;
float2 windPositionSmall = time * 5 * max(1, fWindSpeed/3) * float2(fWindDirection.x, -fWindDirection.y) + worldPos.xy * 5;
float noise = perlinNoise(windPosition * fWindNoiseSize);
float noiseSmall = perlinNoise(windPositionSmall * fWindNoiseSize);
float treeHeight = max((VS.Position.z - fTreeZOffset)/fTreeHeight, 0);
float2 smallWind = fWindDirection * fWindStrength * noiseSmall * treeHeight / 3;
worldPos.xy += fWindDirection * fWindStrength * treeHeight * noise + (isTreeLog ? 0 : smallWind);
::end