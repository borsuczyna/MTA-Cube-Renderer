local reflectiveShaders = {}
local reflectiveTextures = {
    {'vehiclegrunge256', 0.8},
}

function createReflectiveShaders()
    local mainShader = getMainShader()

    for k,v in pairs(reflectiveTextures) do
        local key = v[1] .. v[2] .. tostring(v[3])
        local shader = reflectiveShaders[key]
        if not shader then
            shader = createShader('data/effects/reflective.fx')
        end

        mainShader:remove(v[1])
        shader:apply(v[1])
        shader:setValue('sScreenTexture', buffers.reflect)
        shader:setValue('sReflectPower', v[2])

        reflectiveShaders[key] = shader
        table.insert(reflectiveShaders, shader)
    end
end

function updateReflectiveShaders()
    for _, shader in pairs(reflectiveShaders) do
        shader:setValue('sLightDir', settings.shadowsDirection)
        shader:setValue('sLightColor', settings.sunColor)
    end
end