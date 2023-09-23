# MTA-Cube-Renderer
❒ renderer by borsuczyna

# What is cube renderer?
cube renderer is open source custom rendering for Multi Theft Auto, you can feel free to contribute to it!

# Is it finished?
No, it's almost finished, it requires timecyc hours to be added and it will be ready to use!

# What's left?
- Timecyc
- dxDrawMaterialLine3D
- dxDrawPrimitive3D
- dxDrawLine3D

# Special thanks
Ren712, Einheit-101

# Custom shaders
1. Create your .fx file inside effects
2. Add it inside meta.xml
3.
```lua
local mainShader = getMainShader()
shader = createShader('data/effects/your name.fx')
mainShader:remove('your texture name')
shader:apply('your texture name')
```

# Custom shaders compiler
Keywords
```c
::loop(variable name, int start, int stop)
// what to do
::end

::Includes
// what to include
::end

::Variables
// your variables
::end

::VSInput
// vsinput sementics
::end

::PSInput
// psinput sementics
::end

::WorldPosition(float4 worldPos)
// affect world position (shadows too)
::end

::VertexShader
// all vertex shader code
::end

::PixelShader(float4 texel)
// pixel shader
::end

::Emmisive(float4 emmisive)
// emmisive affect code
::end
```

## Example wind shader:
```c
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
float2 windPosition = time * fWindSpeed * float2(-fWindDirection.x, -fWindDirection.y) + worldPos.xy / 10;
float2 windPositionSmall = time * 5 * max(1, fWindSpeed/3) * float2(fWindDirection.x, -fWindDirection.y) + worldPos.xy * 5;
float noise = perlinNoise(windPosition * fWindNoiseSize);
float noiseSmall = perlinNoise(windPositionSmall * fWindNoiseSize);
float treeHeight = max((VS.Position.z - fTreeZOffset)/fTreeHeight, 0);
float2 smallWind = fWindDirection * fWindStrength * noiseSmall * treeHeight / 3;
worldPos.xy += fWindDirection * fWindStrength * treeHeight * noise + (isTreeLog ? 0 : smallWind);
::end
```

# Support server:
https://discord.gg/todo

# Preview
![](https://borsuczyna.github.io/2.png)
![](https://borsuczyna.github.io/4.png)
![](https://borsuczyna.github.io/6.png)
![](https://borsuczyna.github.io/8.png)
![](https://borsuczyna.github.io/10.png)
![](https://borsuczyna.github.io/12.png)
![](https://borsuczyna.github.io/14.png)
![](https://borsuczyna.github.io/16.png)
