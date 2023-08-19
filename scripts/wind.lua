local windShaders = {}
local windTextures = {
    -- shader, texture, z offset, height, no shadow casting, is tree log
    {'wind', 'bpinud2', 0, 14, false, true},
    {'wind', 'pinebrnch1', 0, 14},
    {'wind', 'trunk3', 0, 15},
    {'wind', 'trunk5', 0, 15},
    {'wind', 'tree19mi', -15, 100},
    {'wind', 'sm_redwood_branch', -15, 100},
    {'wind', 'sm_pinetreebit', -15, 100},
    {'wind', 'gen_log', 0, 100, false, true},
    {'wind', 'sm_redwood_bark', 0, 100, false, true},
    {'wind', 'newtreeleaves128', 0, 20},
    {'wind', 'sm_bark_light', 0, 20, false, true},
    {'wind', 'planta256', 0, 30},
    {'wind', 'kbtree3_test', 0, 30, false, true},
    {'wind', 'vegaspalm01_128', 0, 30, false, true},
    {'wind', 'elm_treegrn', 0, 15},
    {'wind', 'elm_treegrn2', 0, 15},
    {'wind', 'elmtreered', 0, 30},
    {'wind', 'bzelka1', 0, 15, false, true},
    {'wind', 'weeelm', 0, 15, false},
    {'wind', 'hazelbrnch', 0, 30},
    {'wind', 'bcorya0', 0, 30, false, true},
    {'wind', 'ashbrnch', 0, 30},
    {'wind', 'bfraxa1', 0, 30, false, true},
    {'wind', 'sprucbr', 0, 30},
    {'wind', 'hazelbranch', 0, 30},
    {'wind', 'bpiced1', 0, 30, false, true},
    {'wind', 'hazelbranch', 0, 30},
    {'wind', 'bthuja1', 0, 30, false, true},
    {'wind', 'cedarbare', 0, 30},
    {'wind', 'cedarwee', 0, 30},
    {'wind', 'locustbra', 0, 30},
    {'wind', 'bgleda0', 0, 30, false, true},
    {'wind', 'cypress2', 0, 30},
    {'wind', 'cypress1', 0, 30},
    {'wind', 'bchamae', 0, 30, false, true},
    {'wind', 'pinelo128', 0, 30},
    {'wind', 'elm_treegrn4', 0, 30},
    {'wind', 'veg_leaf', 0, 2},
    {'wind', 'veg_bush2', 0, 5},
    {'wind', 'elmdead', 0, 20},
    {'wind', 'sm_des_bush*', 0, 5},
    {'wind', 'sm_josh_leaf', 0, 13},
    {'wind', 'sm_josh_bark', 0, 13},
    {'wind', 'sw_flag01', 1.5, -2},

    -- {'wind', 'txgrass1_1', 0, 10, true},
    -- {'grass', 'txgrass0_1', 0, 10, true},
    -- {'wind', 'txgrass1_0', 0, 10, true},
    -- {'wind', 'oak2b', 0, 10, true},
    -- {'wind', 'sm_agave_*', 0, 2, true},
    -- {'wind', 'starflower*', 0, 2, true},
}

function createWindShaders()
    local mainShader = getMainShader()

    for k,v in pairs(windTextures) do
        local key = v[2] .. v[3] .. tostring(v[4]) .. tostring(v[5])
        local shader = windShaders[key]
        if not shader then
            shader = createShader('data/effects/' .. v[1] .. '.fx')
        end

        mainShader:remove(v[2])
        shader:apply(v[2])
        shader:setValue('fTreeZOffset', v[3])
        shader:setValue('fTreeHeight', v[4])

        shader:setValue('fWindStrength', settings.windStrength)
        shader:setValue('fWindSpeed', settings.windSpeed)
        shader:setValue('fWindDirection', settings.windDirection)
        shader:setValue('fWindNoiseSize', settings.windNoiseSize)

        if v[5] then
            shader:setShadowCastingEnabled(false)
        elseif v[6] then
            shader:setValue('isTreeLog', true)
        end

        windShaders[key] = shader
        table.insert(windShaders, shader)
    end
end