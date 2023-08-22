local queuedLights = {}

function clearQueue()
    queuedLights = {}
end

function queueLight(position, color, size, spotlightData)
    if type(position) == 'table' then
        position = Vector3(position.x or position[1], position.y or position[2], position.z or position[3])
    end

    if spotlightData and spotlightData.direction and type(spotlightData.direction) == 'table' then
        local d = spotlightData.direction
        spotlightData.direction = Vector3(d.x or d[1], d.y or d[2], d.z or d[3]):getNormalized()
    end

    table.insert(queuedLights, {
        position = position,
        color = color,
        size = size,
        spotlightData = spotlightData
    })
end

function updateLights()
    local maxLights = settings.maxLights
    local cameraPosition = Vector3(getCameraMatrix())

    if #queuedLights > maxLights then
        local sortedLights = {}

        for _,v in pairs(queuedLights) do
            local priority = 0
            local dist = (v.position - cameraPosition).length

            priority = priority + dist / 10
            priority = priority - v.size / 10

            local edgeTolerance = math.max(sx/2-dist*20, 20)
            local x, y = getScreenFromWorldPosition(v.position.x, v.position.y, v.position.z + 0.5, edgeTolerance, true)
            if x and y then
                table.insert(sortedLights, {
                    position = v.position,
                    color = v.color,
                    size = v.size,
                    spotlightData = v.spotlightData,
                    priority = priority
                })
            end
        end

        table.sort(sortedLights, function(a, b)
            return a.priority < b.priority
        end)

        queuedLights = {}

        for i = 1, maxLights do
            local light = sortedLights[i]

            if light then
                table.insert(queuedLights, light)
            end
        end
    end

    if settings.lightsDebugEnabled then
        for _,v in pairs(queuedLights) do
            local r, g, b = math.min(v.color[1], 255), math.min(v.color[2], 255), math.min(v.color[3])

            if not v.spotlightData then
                local x, y = getScreenFromWorldPosition(v.position.x, v.position.y, v.position.z + 0.5, 30, true)
                if x and y then
                    local distance = (v.position - cameraPosition).length
                    local size = math.max(15 - distance / 10, 1)
                    dxDrawCircle(x, y, size, 0, 360, tocolor(r, g, b, 155), tocolor(r, g, b, 255), 32, 1, true)
                end
            else
                dxDrawLine3D(v.position, v.position + v.spotlightData.direction / 2, tocolor(r, g, b, 255), 2, true)
            end
        end
    end

    local mainShader = getMainShader()

    for i = 1, maxLights do
        local v = queuedLights[i]
        if v then
            mainShader:setValue('lightPosition' .. i, v.position.x, v.position.y, v.position.z)
            mainShader:setValue('lightColor' .. i, v.color[1]/255, v.color[2]/255, v.color[3]/255)

            if v.spotlightData then
                mainShader:setValue('lightDirection' .. i, v.spotlightData.direction.x, v.spotlightData.direction.y, v.spotlightData.direction.z, 1)
                mainShader:setValue('lightPhiThetaFalloff' .. i, v.spotlightData.phi or 0, v.spotlightData.theta or 0, v.spotlightData.falloff or 0)
            else
                mainShader:setValue('lightDirection' .. i, 0, 0, 0, 0)
            end
        end

        mainShader:setValue('lightEnabled' .. i, not not v)
        -- mainShader:setValue('lightDirection1', -cameraMatrix[2][1], -cameraMatrix[2][2], -cameraMatrix[2][3] - 0.4)
    end

    clearQueue()
end