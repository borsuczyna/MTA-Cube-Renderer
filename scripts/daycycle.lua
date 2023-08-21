local shaders = {}
local timeCycle = {
    [12] = {
        fogStart = 0.05,
        fogDistance = 0.6,
        skyboxTexture = '1',
        skyboxInterpolation = 0,
    },
    [13] = {
        fogStart = 0.05,
        fogDistance = 0.6,
        skyboxTexture = '2',
        skyboxInterpolation = .5,
        godRayStartOffset = 0.3,
        godRayLength = 0.7,

        ambientColor = {0.3, 0.3, 0.3},
        lightColor = {1.05, 0.95, 0.85},
        aoColor = {0.3, 0.3, 0.3},
        aoShadowColor = {0.1, 0.1, 0.1},
    },
    [20] = {
        fogStart = 0.05,
        fogDistance = 0.6,
        skyboxTextureA = '3',
        skyboxTextureB = '4',
        skyboxInterpolationStart = 0,
        skyboxInterpolationEnd = 1,

        sunDirection = {1, 0.05, -0.2},
        sunColor = {1, 0.8, 0.6, 1},
        sunSize = 500,
        godraysAlpha = 1,
        godRayStartOffset = 0.3,
        godRayLength = 0.7,

        ambientColor = {0.3, 0.3, 0.3},
        lightColor = {1.05, 0.85, 0.75},
        aoColor = {0.3, 0.3, 0.3},
        aoShadowColor = {0.1, 0.1, 0.1},
    },
    [21] = {
        fogStart = 0.05,
        fogDistance = 0.6,
        skyboxTextureA = '4',
        skyboxTextureB = '5',
        skyboxInterpolationStart = 0,
        skyboxInterpolationEnd = 1,

        sunDirection = {1, 0, -0.1},
        sunColor = {1, 0.8, 0.5, 1},
        sunSize = 400,
        godraysAlpha = 0.5,
        godRayStartOffset = 0.3,
        godRayLength = 0.7,

        ambientColor = {0.25, 0.17, 0.15},
        lightColor = {0.85, 0.5, 0.4},
        aoColor = {0.3, 0.3, 0.3},
        aoShadowColor = {0.1, 0.1, 0.1},
    },
    [22] = {
        fogStart = 0.05,
        fogDistance = 0.5,
        skyboxTextureA = '5',
        skyboxTextureB = '5',
        skyboxInterpolationStart = 0,
        skyboxInterpolationEnd = 1,

        sunDirection = {1, -0.05, 0.2},
        sunColor = {0.8, 0.6, 0.4, 0},
        sunSize = 100,
        godraysAlpha = 0,
        godRayStartOffset = 0,
        godRayLength = 1,

        ambientColor = {0.12, 0.12, 0.22},
        lightColor = {0.12, 0.12, 0.22},
        aoColor = {0.3, 0.3, 0.3},
        aoShadowColor = {0.01, 0.01, 0.03},
    },
}

function getShaders()
    shaders.post = getPostShader()
    shaders.godrays = getGodRaysShader()
end

function areAllShadersLoaded()
    return (
        (shaders.post and isElement(shaders.post)) and
        (not settings.godRaysEnabled or (shaders.godrays and isElement(shaders.godrays)))
    )
end

function updateDayCycle()
    if not areAllShadersLoaded() then getShaders() end
    if not areAllShadersLoaded() then return end

    local h,m = getTime()
    local hour, minute = 21, 0
    local start = timeCycle[hour]
    local finish = timeCycle[hour + 1] or timeCycle[1] or timeCycle[hour]
    local progress = (minute / 60)

    local data = interpolateBetween(start, finish, progress, 'Linear')
    dxSetShaderValue(shaders.post, 'fFogStart', data.fogStart)
    dxSetShaderValue(shaders.post, 'fFogDistance', data.fogDistance)
    dxSetShaderValue(shaders.post, 'fAmbientColor', data.ambientColor)
    dxSetShaderValue(shaders.post, 'fLightColor', data.lightColor)
    dxSetShaderValue(shaders.post, 'fAoColor', data.aoColor)
    dxSetShaderValue(shaders.post, 'fAoShadowColor', data.aoShadowColor)

    dxSetShaderValue(shaders.godrays, 'sSunColor', data.sunColor or {255, 255, 255})
    dxSetShaderValue(shaders.godrays, 'fGodRayStartOffset', data.godRayStartOffset or 0.3)
    dxSetShaderValue(shaders.godrays, 'fGodRayLength', data.godRayLength or 0.7)
    dxSetShaderValue(shaders.godrays, 'fGodRayAlpha', data.godraysAlpha or 1)

    setSkyTexture(1, 'data/skybox/' .. start.skyboxTextureA .. '.jpg')
    setSkyTexture(2, 'data/skybox/' .. start.skyboxTextureB .. '.jpg')

    local skyboxInterpolation = interpolateBetween(start.skyboxInterpolationStart, finish.skyboxInterpolationEnd, progress)
    setSkyInterpolation(skyboxInterpolation)

    settings.shadowsDirection = Vector3(unpack(data.sunDirection or {0, 0, 0}))
    settings.sunSize = data.sunSize or 500
end

function interpolateBetween(a, b, progress)
    if type(a) == 'number' then
        return a + (b - a) * progress
    elseif type(a) == 'table' then
        local t = {}
        for i, v in pairs(a) do
            t[i] = interpolateBetween(v, b[i], progress)
        end
        return t
    else
        return a
    end
end