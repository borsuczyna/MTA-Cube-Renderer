local shader = nil

function createSkybox()
    shader = dxCreateShader(compileShader('data/skybox.fx'))
    dxSetShaderValue(shader, 'sSkyTexture', dxCreateTexture('data/skybox/default.jpg'))
    dxSetShaderValue(shader, 'sSkyTarget', buffers.skybox)

    return shader
end

function updateSkybox()
    -- dxSetRenderTarget(buffers.skybox)
    -- dxDrawRectangle(0, 0, sx, sy, tocolor(188, 225, 249))
    -- dxSetRenderTarget()
end