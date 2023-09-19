local emmisiveShaders = {}
local emmisiveTextures = {
    {'vehiclelightson128', 255, 255, 255, 0.8, {1, 1}},
    {'lampost_16clr', 255, 255, 255, 0.8, {1, 1}, {0, 2, 1, .01}},
}

function createEmmisiveShaders()
    local mainShader = getMainShader()

    for k,v in pairs(emmisiveTextures) do
        local key = v[1] .. v[2] .. v[3] .. v[4]
        local shader = emmisiveShaders[key]
        if not shader then
            shader = createShader('data/effects/' .. (v[7] and 'texcoord-emmisive' or 'emmisive') .. '.fx')
        end

        mainShader:remove(v[1])
        shader:apply(v[1])
        shader:setValue('sEmisiveColor', v[2] / 255, v[3] / 255, v[4] / 255)
        shader:setValue('sEmmisivePower', v[5])
        shader:setValue('sEmmisivePow', v[6] or {1, 1})
        if v[7] then shader:setValue('sEmmisiveTexCoord', v[7]) end

        emmisiveShaders[key] = shader
        table.insert(emmisiveShaders, shader)
    end
end