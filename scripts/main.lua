local shaders = {}
local fps = {0, 0}
local dayCycleTimer = nil

setTimer(function()
    fps[2] = fps[1] * 4
    fps[1] = 0
end, 250, 0)

function getMainShader()
    return shaders.main
end

function renderCubeRenderer()
    drawShadows()
    if settings.godRaysEnabled then updateGodRays() end

    dxDrawImage(0, 0, sx, sy, shaders.post)
    if settings.godRaysEnabled then dxDrawImage(0, 0, sx, sy, shaders.godrays) end

    if settings.debugRender == 1 then -- draw shadow depth buffers
        local x, y = 0, 0
        for i = 1, #settings.shadowPlanes do
            local depth = getDepthBuffer(i)
            dxDrawImage(x, y, 450, 450, depth)
            x = x + 450
            if x + 450 > sx then x = 0; y = y + 450 end
        end
    elseif settings.debugRender == 2 then
        dxDrawRectangle(0, 0, sx, sy, 0xFF000000)
        dxDrawImage(0, 0, sx, sy, buffers.albedo)
    elseif settings.debugRender == 3 then
        dxDrawImage(0, 0, sx, sy, buffers.shadows)
    elseif settings.debugRender == 4 then
        dxDrawImage(0, 0, sx, sy, buffers.screenDepth)
    elseif settings.debugRender == 5 then
        dxDrawImage(0, 0, sx, sy, buffers.emmisives)
    elseif settings.debugRender == 6 then
        dxDrawImage(0, 0, sx, sy, buffers.skybox)
    end

    dxDrawText('Cube Renderer Alpha @borsuczyna', 1, 1, sx + 1, sy - 1, 0xAA000000, 1.5, 'default-bold', 'center', 'bottom')
    dxDrawText('Cube Renderer Alpha @borsuczyna', 0, 0, sx, sy - 2, white, 1.5, 'default-bold', 'center', 'bottom')

    dxDrawText('fps: ' .. fps[2], 0, 0, sx, sy - 25, white, 1, 'default-bold', 'center', 'bottom')

    -- debug
    -- queueLight({375.16501, -2068.24268, 7.83594}, {855, 0, 0}, 8)
    -- queueLight({382.57190, -2065.37402, 7.83594}, {0, 855, 0}, 8, {
    --     direction = {math.cos(getTickCount()/400), math.sin(getTickCount()/400), -0.5},
    --     theta = 0,
    --     phi = 1,
    --     falloff = 0.1,
    -- })
end

function updateCubeRenderer()
    updateCamera()
    updateBuffers()

    if settings.objectLightsEnabled then
        updateObjectLights()
    end

    updateLights()

    fps[1] = fps[1] + 1
end

function initCubeRenderer()
    destroyCubeRenderer()

    initBuffers()
    
    shaders.main = createShader(nil, true)
    shaders.main:defaultApply()
    shaders.generic = createShader('data/effects/generic.fx')
    shaders.generic:apply('vehiclegeneric256')
    
    createFinalShadowShader()
    createPostShader()
    createEmmisiveShaders()
    createSkybox()
    setSkyTexture(1, 'data/skybox/1.jpg')

    if settings.replaceDefaultObjects then
        createReplacedObjects()
    end

    dayCycleTimer = setTimer(updateDayCycle, getMinuteDuration(), 0)
    dayCycleTimer = setTimer(updateDayCycle, 1000, 1)
    updateDayCycle()

    if settings.windShadersEnabled then createWindShaders() end
    if settings.godRaysEnabled then shaders.godrays = createGodRays() end
    
    shaders.post = getPostShader()
    
    addEventHandler('onClientPreRender', root, updateCubeRenderer, true, 'high+1')
    addEventHandler('onClientPreRender', root, updateShadows, true, 'high')
    addEventHandler('onClientHUDRender', root, renderCubeRenderer)
end

function destroyCubeRenderer()
    removeEventHandler('onClientPreRender', root, updateCubeRenderer)
    removeEventHandler('onClientPreRender', root, updateShadows)
    removeEventHandler('onClientHUDRender', root, renderCubeRenderer)
    
    destroyShaders()
    destroyBuffers()

    if isTimer(dayCycleTimer) then killTimer(dayCycleTimer) end
end

addEventHandler('onClientResourceStart', resourceRoot, initCubeRenderer)

addCommandHandler('elo', function()
    destroyCubeRenderer()
end)

addCommandHandler('elo2', function()
    initCubeRenderer()
end)