function updateSkybox()
    dxSetRenderTarget(buffers.skybox)
    dxDrawRectangle(0, 0, sx, sy, tocolor(188, 225, 249))
    dxSetRenderTarget()
end