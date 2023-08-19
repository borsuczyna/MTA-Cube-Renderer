local shader = nil

function createGodRays()
    shader = dxCreateShader(compileShader('data/godrays.fx'))
    dxSetShaderValue(shader, 'sRTDepth', buffers.albedo)
    dxSetShaderValue(shader, 'sGodraysTexture', buffers.godrays)

    return shader
end

function updateGodRays()
    local camMat = getCameraMatrix()
    local centerPos = Vector3(getElementPosition(getCamera()))
    local sunWorldPos = centerPos - settings.shadowsDirection * 5
    local sunScreenX, sunScreenY = getScreenFromWorldPosition(sunWorldPos.x, sunWorldPos.y, sunWorldPos.z, settings.sunSize/2)
    if sunScreenX and sunScreenY then
        dxSetShaderValue(shader, 'sSunPosition', sunScreenX, sunScreenY)
        dxSetShaderValue(shader, 'fSunSize', settings.sunSize)
        dxSetShaderValue(shader, 'sScrRes', sx, sy)
    end

    dxSetShaderValue(shader, 'sSunVisible', sunScreenX and sunScreenY)
end