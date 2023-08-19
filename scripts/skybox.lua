local shader = nil

function createSkybox()
    shader = dxCreateShader(compileShader('data/skybox.fx'))
    dxSetShaderValue(shader, 'sSkyTexture', dxCreateTexture('data/skybox/default.jpg'))
    dxSetShaderValue(shader, 'sSkyTarget', buffers.skybox)

    return shader
end

function updateSkybox()
    dxDrawImage(0, 0, sx, sy, shader)
end