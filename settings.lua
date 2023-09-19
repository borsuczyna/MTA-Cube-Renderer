settings = {
    shadowPlanes = {30, 200}, -- max 3!
    vehicleShadowPlane = 50,
    shadowsDirection = Vector3(-0.45, 0.277, -0.34):getNormalized(),
    viewRadius = 150,

    sunSize = 500,
    sunColor = {1, 1, 1},

    windStrength = 3,
    windSpeed = 2,
    windDirection = {1, -1},
    windNoiseSize = 0.5,
    maxLights = 14,
    objectsLightsRenderDistance = 300,
    
    godRaysEnabled = true,
    windShadersEnabled = true,
    lightsDebugEnabled = false,
    objectLightsEnabled = true,
    vehicleLightsEnabled = true,
    replaceDefaultObjects = true,

    debugRender = 0,
}

addCommandHandler('debugrender', function(cmd, value)
    settings.debugRender = tonumber(value) or 0

    if value == 'shadowmaps' then
        settings.debugRender = 1
    elseif value == 'albedo' then
        settings.debugRender = 2
    elseif value == 'shadows' then
        settings.debugRender = 3
    elseif value == 'depth' then
        settings.debugRender = 4
    elseif value == 'emmisive' then
        settings.debugRender = 5
    elseif value == 'skybox' then
        settings.debugRender = 6
    end
end)