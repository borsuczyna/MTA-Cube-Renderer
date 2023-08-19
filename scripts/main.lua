local shaders = {}

function getMainShader()
    return shaders.main
end

function renderCubeRenderer()
    drawShadows()
    dxDrawImage(0, 0, sx, sy, shaders.post)

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
    end

    dxDrawText('Cube Renderer Alpha @borsuczyna', 1, 1, sx + 1, sy - 1, 0xAA000000, 1.5, 'default-bold', 'center', 'bottom')
    dxDrawText('Cube Renderer Alpha @borsuczyna', 0, 0, sx, sy - 2, white, 1.5, 'default-bold', 'center', 'bottom')
end

function updateCubeRenderer()
    updateCamera()
    updateBuffers()
end

function initCubeRenderer()
    initBuffers()
    
    shaders.main = createShader()
    shaders.main:defaultApply()
    
    createFinalShadowShader()
    createPostShader()
    createWindShaders()
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
end

addEventHandler('onClientResourceStart', resourceRoot, initCubeRenderer)

addCommandHandler('elo', function()
    destroyCubeRenderer()
end)