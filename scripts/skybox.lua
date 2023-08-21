local shader = nil
local skyTextures = {}

function createSkybox()
    shader = dxCreateShader(compileShader('data/skybox.fx'))
    dxSetShaderValue(shader, 'sSkyTarget', buffers.skybox)

    return shader
end

function setSkyTexture(index, texture)
    if getSkyTexture(index) == texture then return end

    if skyTextures[index] and isElement(skyTextures[index].texture) then
        destroyElement(skyTextures[index].texture)
    end

    skyTextures[index] = {
        texture = dxCreateTexture(texture),
        name = texture
    }
    dxSetShaderValue(shader, 'sSkyTexture' .. (index == 1 and 'A' or 'B'), skyTextures[index].texture)
end

function setSkyInterpolation(value)
    dxSetShaderValue(shader, 'sSkyInterpolation', value)
end

function getSkyTexture(index)
    return skyTextures[index] and skyTextures[index].name or false
end

function updateSkybox()
    dxDrawImage(0, 0, sx, sy, shader)
end