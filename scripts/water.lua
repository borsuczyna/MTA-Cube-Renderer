local waterShaders = {}
local waterTextures = {
    {'waterclear256', 1},
}
local textures = {}

local function getTexture(name, mipmaps)
    local texture = textures[name]
    if not texture then
        texture = dxCreateTexture(name, 'dxt5', mipmaps)
        textures[name] = texture
    end
    return texture
end

function createWaterShaders()
    local mainShader = getMainShader()

    for k,v in pairs(waterTextures) do
        local key = v[1] .. v[2] .. tostring(v[3])
        local shader = waterShaders[key]
        if not shader then
            shader = createShader('data/effects/water.fx')
        end

        mainShader:remove(v[1])
        shader:apply(v[1])
        shader:setValue('sPixelSize', {1/sx, 1/sy})
        shader:setValue('normalTexture', getTexture('data/water/normal.png'))
        shader:setValue('foamTexture', getTexture('data/water/foam.png'))
        shader:setValue('screenInput', buffers.reflect)

        waterShaders[key] = shader
        table.insert(waterShaders, shader)
    end
end

function updateWaterShaders()
    -- main:setValue('sLightDir', settings.shadowsDirection)

    for _, shader in pairs(waterShaders) do
        shader:setValue('sLightDir', settings.shadowsDirection)
        shader:setValue('sLightColor', settings.sunColor)
        -- shader:setValue('sLightColor', 0.9, 0.7, 0.6)
    end
end