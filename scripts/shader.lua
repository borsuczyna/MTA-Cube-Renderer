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
        'Variables'
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

    return template
end

function createShader(path)
    local shader = {
        shadows = {},
        world = dxCreateShader(compileShader('data/world.fx', path), 0, 0, false, 'all'),
        appliedTo = {},
    }

    for i = 1, #settings.shadowPlanes do
        local distance = settings.shadowPlanes[i]

        local shadowShader = dxCreateShader(compileShader('data/shadow.fx', path), 0, distance + 50, true, 'all')
        dxSetShaderValue(shadowShader, 'sClip', .3, 600)
        dxSetShaderValue(shadowShader, 'depthRT', getDepthBuffer(i))

        table.insert(shader.shadows, shadowShader)
    end

    dxSetShaderValue(shader.world, 'sAlbedo', buffers.albedo)
    dxSetShaderValue(shader.world, 'sDepth', buffers.screenDepth)

    shader.apply = function(self, texture, element)
        for _,shader in pairs(self.shadows) do
            engineApplyShaderToWorldTexture(shader, texture, element)
        end
        engineApplyShaderToWorldTexture(self.world, texture, element)
    end
    
    shader.defaultApply = function(self)
        for _,shader in pairs(self.shadows) do
            applyShaderToWorld(shader, false)
        end
        applyShaderToWorld(self.world, true)
    end

    shader.remove = function(self, texture, element)
        for _,shader in pairs(self.shadows) do
            engineRemoveShaderFromWorldTexture(shader, texture, element)
        end
        engineRemoveShaderFromWorldTexture(self.world, texture, element)
    end

    shader.setValue = function(self, name, ...)
        for _,shader in pairs(self.shadows) do
            dxSetShaderValue(shader, name, ...)
        end

        dxSetShaderValue(self.world, name, ...)
    end

    shader.destroy = function(self)
        for _,shader in pairs(self.shadows) do
            destroyElement(shader)
        end

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
    dxSetShaderValue(allShaders.post, 'sTexSize', sx, sy)
end

function getPostShader()
    return allShaders.post
end

function getAllShadowShaders()
    local shadowShaders = {
        all = {}
    }

    for _,shader in ipairs(allShaders) do
        for index,shadow in ipairs(shader.shadows) do
            if not shadowShaders[index] then shadowShaders[index] = {} end
            table.insert(shadowShaders[index], shadow)
            table.insert(shadowShaders.all, shadow)
        end
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