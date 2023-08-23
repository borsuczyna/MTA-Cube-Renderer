local allShaders = {}

function applyShaderToWorld(shader, isWorld)
	engineApplyShaderToWorldTexture(shader, '*')
	for k,v in pairs(isWorld and textureWorldRemoveList or textureShadowsRemoveList) do
		engineRemoveShaderFromWorldTexture(shader, v)
	end	
	for k,v in pairs(textureApplyList) do
		engineApplyShaderToWorldTexture(shader, v)
	end
end

function compileShader(template, source)
    local file = fileOpen(template)
    local template = fileRead(file, fileGetSize(file))
    fileClose(file)

    local keywords = {
        'WorldPosition',
        'Includes',
        'Variables',
        'PixelShader',
        'Emmisive',
    }

    if source then
        local sourceFile = fileOpen(source)
        local source = fileRead(sourceFile, fileGetSize(sourceFile))
        fileClose(sourceFile)

        for _,keyword in pairs(keywords) do
            local keywordStart = source:find('::' .. keyword)
            if keywordStart then
                local keywordEnd = source:find('::end', keywordStart)
                if keywordEnd then
                    local keywordStr = source:sub(keywordStart, keywordEnd + 4)
                    local lines = split(keywordStr, '\n')
                    table.remove(lines, 1)
                    table.remove(lines, #lines)
                    local content = table.concat(lines, '\n')

                    template = template:gsub('::' .. keyword .. '::', content)
                else
                    outputDebugString('Failed to find end of keyword ' .. keyword .. ' in ' .. source)
                end
            else
                template = template:gsub('::' .. keyword .. '::', '')
            end
        end
    else
        for _,keyword in pairs(keywords) do
            template = template:gsub('::' .. keyword .. '::', '')
        end
    end

    -- variables
    -- ::variable::
    local variables = {
        {'shadowPlanes', #settings.shadowPlanes},
        {'maxLights', settings.maxLights},
    }

    for _,variable in pairs(variables) do
        template = template:gsub('::' .. variable[1] .. '::', variable[2])
    end

    -- loops
    -- ::loop(variable, start, stop)
    -- content (:variable:)
    -- content (:variable-1:)
    -- content (:variable+2:)
    -- ::end
    local loopStart = template:find('::loop')
    while loopStart do
        local loopEnd = template:find('::end', loopStart)
        if loopEnd then
            local loopStr = template:sub(loopStart, loopEnd + 4)
            local lines = split(loopStr, '\n')

            local variable, start, stop = lines[1]:match('::loop%((%w+),%s*(%d+),%s*(%d+)%)')
            if variable and start and stop then
                table.remove(lines, 1)
                table.remove(lines, #lines)
                local content = table.concat(lines, '\n')

                local finalContent = ''
                for i = tonumber(start), tonumber(stop) do
                    finalContent = finalContent .. content:gsub('%(:' .. variable .. ':%)', i) .. '\n'

                    finalContent = finalContent:gsub('%(:' .. variable .. '%-(%d+):%)', function(number)
                        return i - tonumber(number)
                    end)

                    finalContent = finalContent:gsub('%(:' .. variable .. '%+(%d+):%)', function(number)
                        return i + tonumber(number)
                    end)
                end

                finalContent = finalContent:sub(1, #finalContent - 1)

                template = template:sub(1, loopStart - 1) .. finalContent .. template:sub(loopEnd + 5)
            else
                outputDebugString('Failed to parse loop in ' .. template)
            end
        else
            outputDebugString('Failed to find end of loop in ' .. template)
        end

        loopStart = template:find('::loop', loopStart + 1)
    end

    return template
end

-- setClipboard(compileShader('data/world.fx'))

function createShader(path)
    local distance = settings.shadowPlanes[#settings.shadowPlanes]
    local shader = {
        shadows = dxCreateShader(compileShader('data/shadow.fx', path), 0, distance + 50, true, 'all'),
        world = dxCreateShader(compileShader('data/world.fx', path), 0, 0, false, 'all'),
        appliedTo = {},
    }

    dxSetShaderValue(shader.shadows, 'sClip', .3, 600)

    for i = 1, #settings.shadowPlanes do
        dxSetShaderValue(shader.shadows, 'depthRT' .. i, getDepthBuffer(i))
    end

    dxSetShaderValue(shader.world, 'sAlbedo', buffers.albedo)
    dxSetShaderValue(shader.world, 'sDepth', buffers.screenDepth)
    dxSetShaderValue(shader.world, 'sEmmisives', buffers.emmisives)
    dxSetShaderValue(shader.world, 'sLightDir', settings.shadowsDirection)

    shader.apply = function(self, texture, element)
        engineApplyShaderToWorldTexture(self.shadows, texture, element)
        engineApplyShaderToWorldTexture(self.world, texture, element)
    end
    
    shader.defaultApply = function(self)
        applyShaderToWorld(self.shadows, false)
        applyShaderToWorld(self.world, true)
    end

    shader.remove = function(self, texture, element)
        engineRemoveShaderFromWorldTexture(self.shadows, texture, element)
        engineRemoveShaderFromWorldTexture(self.world, texture, element)
    end

    shader.setValue = function(self, name, ...)
        dxSetShaderValue(self.shadows, name, ...)
        dxSetShaderValue(self.world, name, ...)
    end

    shader.destroy = function(self)
        destroyElement(self.shadows)

        for index,shader in pairs(allShaders) do
            if shader == self then
                table.remove(allShaders, index)
                break
            end
        end
    end

    table.insert(allShaders, shader)

    return shader
end

function createFinalShadowShader()
    allShaders.final = dxCreateShader('data/final.fx')

    dxSetShaderValue(allShaders.final, 'sClip', .3, 600)
    dxSetShaderValue(allShaders.final, 'fViewportSize', sx, sy)
    dxSetShaderValue(allShaders.final, 'sPixelSize', 1 / sx, 1 / sy)
    dxSetShaderValue(allShaders.final, 'sAspectRatio', sx / sy)
    dxSetShaderValue(allShaders.final, 'sRTColor', buffers.color)
    dxSetShaderValue(allShaders.final, 'sRTShadows', buffers.shadows)
    dxSetShaderValue(allShaders.final, 'sRTNormal', buffers.normal)

    for i = 1, #settings.shadowPlanes do
        dxSetShaderValue(allShaders.final, 'sRTDepth_' .. i, getDepthBuffer(i))
    end
end

function getFinalShadowShader()
    return allShaders.final
end

function createPostShader()
    allShaders.post = dxCreateShader('data/post.fx')

    dxSetShaderValue(allShaders.post, 'sAlbedo', buffers.albedo)
    dxSetShaderValue(allShaders.post, 'sShadows', buffers.shadows)
    dxSetShaderValue(allShaders.post, 'sSkybox', buffers.skybox)
    dxSetShaderValue(allShaders.post, 'sDepth', buffers.screenDepth)
    dxSetShaderValue(allShaders.post, 'sEmmisives', buffers.emmisives)
    dxSetShaderValue(allShaders.post, 'sTexSize', sx, sy)
end

function getPostShader()
    return allShaders.post
end

function getAllShadowShaders()
    local shadowShaders = {}

    for _,shader in ipairs(allShaders) do
        table.insert(shadowShaders, shader.shadows)
    end

    return shadowShaders
end

local _dxSetShaderValue = dxSetShaderValue
function dxSetShaderValue(shader, name, ...)
    if not isElement(shader) then return end
    return _dxSetShaderValue(shader, name, ...)
end

function destroyShaders()
    for k,v in pairs(getElementsByType('shader', resourceRoot)) do
        destroyElement(v)
    end

    allShaders = {}
end