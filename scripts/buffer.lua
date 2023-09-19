buffers = {
    depth = {}
}

function getDepthBuffer(id)
    if not buffers.depth[id] then
        buffers.depth[id] = dxCreateRenderTarget(sx, sy, true)
    end

    return buffers.depth[id] 
end

function updateBuffers()
    for _, buffer in pairs(buffers.depth) do
        dxSetRenderTarget(buffer, true)
        dxDrawRectangle(0, 0, sx, sy, 0xFFFFFFFF)
    end
    dxSetRenderTarget(buffers.albedo, true)
    dxSetRenderTarget(buffers.color, true)
    dxSetRenderTarget(buffers.shadows, true)
    dxSetRenderTarget(buffers.normal, true)
    dxSetRenderTarget(buffers.screenDepth, true)
    dxSetRenderTarget(buffers.emmisives, true)
    if settings.godRaysEnabled then dxSetRenderTarget(buffers.godrays, true) end
    dxSetRenderTarget()

    updateSkybox()
end

function initBuffers()
    buffers.albedo = dxCreateRenderTarget(sx, sy, true)
    buffers.shadows = dxCreateRenderTarget(sx, sy, false)
    buffers.color = dxCreateRenderTarget(sx, sy, false)
    buffers.normal = dxCreateRenderTarget(sx, sy, false)
    buffers.skybox = dxCreateRenderTarget(sx, sy, false)
    buffers.screenDepth = dxCreateRenderTarget(sx, sy, true)
    buffers.emmisives = dxCreateRenderTarget(sx, sy, false)
    buffers.reflect = dxCreateRenderTarget(sx, sy, false)
    if settings.godRaysEnabled then buffers.godrays = dxCreateRenderTarget(sx, sy, true) end
end

function destroyBuffers()
    for k,v in pairs(getElementsByType('texture', resourceRoot)) do
        destroyElement(v)
    end

    buffers = {
        depth = {}
    }
end