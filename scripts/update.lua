function updateCamera()
    local fwVec = settings.shadowsDirection
    local centerPos = Vector3(getElementPosition(getCamera()))
    local cameraPos = centerPos - fwVec * settings.viewRadius
    local bottomPos = Vector3(centerPos.x, centerPos.y, centerPos.z - settings.viewRadius)
    local rtVec = ((centerPos - cameraPos):cross(bottomPos - cameraPos)):getNormalized()
    local upVec =  -(rtVec:cross(fwVec)):getNormalized()

    cameraPos.x = math.floor(cameraPos.x / 2) * 2
    cameraPos.y = math.floor(cameraPos.y / 2) * 2
    cameraPos.z = math.floor(cameraPos.z / 2) * 2

    -- local shadowShaders = getAllShadowShaders()
    -- for _,shader in ipairs(shadowShaders.all) do
    --     dxSetShaderValue(shader, 'sCameraPosition', cameraPos.x, cameraPos.y, cameraPos.z)
    --     dxSetShaderValue(shader, 'sCameraForward', fwVec.x, fwVec.y, fwVec.z)
    --     dxSetShaderValue(shader, 'sCameraUp', upVec.x, upVec.y, upVec.z)
    -- end

    -- for index,data in ipairs(shadowShaders) do
    --     for _,shader in ipairs(data) do
    --         dxSetShaderValue(shader, 'sScrRes', settings.shadowPlanes[index], settings.shadowPlanes[index])
    --     end
    -- end

    local shadowShaders = getAllShadowShaders()
    for _,shader in ipairs(shadowShaders) do
        dxSetShaderValue(shader, 'sCameraPosition', cameraPos.x, cameraPos.y, cameraPos.z)
        dxSetShaderValue(shader, 'sCameraForward', fwVec.x, fwVec.y, fwVec.z)
        dxSetShaderValue(shader, 'sCameraUp', upVec.x, upVec.y, upVec.z)

        for i = 1, #settings.shadowPlanes do
            dxSetShaderValue(shader, 'sScrRes' .. i, settings.shadowPlanes[i], settings.shadowPlanes[i])
        end
    end

    -- dxSetShaderValue(shader, 'sCameraPosition', cameraPos.x, cameraPos.y, cameraPos.z)
    -- dxSetShaderValue(shader, 'sCameraForward', fwVec.x, fwVec.y, fwVec.z)
    -- dxSetShaderValue(shader, 'sCameraUp', upVec.x, upVec.y, upVec.z)

    local final = getFinalShadowShader()
    dxSetShaderValue(final, 'sCameraPosition', cameraPos.x, cameraPos.y, cameraPos.z)
    dxSetShaderValue(final, 'sCameraForward', fwVec.x, fwVec.y, fwVec.z)
    dxSetShaderValue(final, 'sCameraUp', upVec.x, upVec.y, upVec.z)

    dxSetShaderValue(final, 'iShadowPlanes', #settings.shadowPlanes)
    for i = 1, #settings.shadowPlanes do
        dxSetShaderValue(final, 'sScrRes_' .. i, settings.shadowPlanes[i], settings.shadowPlanes[i])
    end
end

function updateShadows()
    local final = getFinalShadowShader()
    local centerPos = Vector3(getElementPosition(getCamera()))
    dxSetShaderValue(final, "sElementPosition", centerPos.x, centerPos.y, centerPos.z)

    dxDrawMaterialLine3D(centerPos.x + 0.5, centerPos.y, centerPos.z, centerPos.x + 0.5, centerPos.y + 1, centerPos.z,
    final, 1, tocolor(255, 0, 0, 155), centerPos.x + 0.5,centerPos.y + 0.5, centerPos.z + 1)
end

function drawShadows()
end