local shader = nil
local skyTextures = {}

function createSkybox()
    shader = dxCreateShader(compileShader('data/skybox.fx'))
    -- dxSetShaderValue(shader, 'sSkyTextureA', dxCreateTexture('data/skybox/1.jpg'))
    -- dxSetShaderValue(shader, 'sSkyTextureB', dxCreateTexture('data/skybox/2.jpg'))
    dxSetShaderValue(shader, 'sSkyInterpolation', 0)
    dxSetShaderValue(shader, 'sSkyTarget', buffers.skybox)

    return shader
end

function setSkyTexture(index, texture)
    if skyTextures[index] and isElement(skyTextures[index]) then
        destroyElement(skyTextures[index])
    end

    skyTextures[index] = dxCreateTexture(texture)
    dxSetShaderValue(shader, 'sSkyTexture' .. (index == 1 and 'A' or 'B'), skyTextures[index])
end

function setSkyInterpolation(value)
    dxSetShaderValue(shader, 'sSkyInterpolation', value)
end

function updateSkybox()
    dxDrawImage(0, 0, sx, sy, shader)
end