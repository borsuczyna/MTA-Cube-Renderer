local brokenObjects = {}
local lightPositions = {}
local lights = {
    -- start time, end time, x, y, z, r, g, b, size, directional data, is static
    [1232] = {20, 6, 0, 0, 2.2, 255, 255, 255, 20, nil, true},
    [1297] = {20, 6, -0.5, 0, 3.2, 700, 400, 0, 30, {
        direction = {'toOffset', -2.5, 0, 0},
        theta = 0,
        phi = 3,
        falloff = 1,
    }, true},
    [1226] = {20, 6, -1.3, 0, 3.5, 800, 500, 0, 30, {
        direction = {'toOffset', -7, 0, 0},
        theta = 0,
        phi = 1.2,
        falloff = 0.4,
    }, true},
    [1294] = {20, 6, -1.3, 0, 4.1, 800, 500, 0, 30, {
        direction = {'toOffset', -7, 0, 0},
        theta = 0,
        phi = 1.2,
        falloff = 0.4,
    }, true},
}

function updateObjectLights()
    local cx, cy, cz = getCameraMatrix()
    local hour, minutes = getTime()

    for _,object in pairs(getElementsWithinRange(cx, cy, cz, settings.objectsLightsRenderDistance, 'object')) do
        local x, y, z
        local model = getElementModel(object)
        local lightData = lights[model]

        if lightData and not brokenObjects[object] and isInTime(lightData[1], lightData[2], hour) then
            local directionalData = lightData[10] and {
                direction = lightData[10].direction,
                theta = lightData[10].theta,
                phi = lightData[10].phi,
                falloff = lightData[10].falloff,
            }

            if lightData[11] and lightPositions[object] then
                x, y, z = unpack(lightPositions[object].position)
                directionalData = lightPositions[object].directionalData
            else
                x, y, z = getPositionFromElementOffset(object, lightData[3], lightData[4], lightData[5])
                if directionalData and directionalData.direction[1] == 'toOffset' then
                    local tx, ty, tz = getPositionFromElementOffset(object, directionalData.direction[2], directionalData.direction[3], directionalData.direction[4])
                    directionalData.direction = Vector3(tx - x, ty - y, tz - z):getNormalized()
                end

                if lightData[11] then
                    lightPositions[object] = {
                        position = {x, y, z},
                        directionalData = directionalData,
                    }
                end
            end

            queueLight({x, y, z}, {lightData[6], lightData[7], lightData[8]}, lightData[9], directionalData)
        end
    end
end

addEventHandler('onClientObjectBreak', root, function()
    brokenObjects[source] = true
end)

function unbrokeObject()
    if getElementType(source) == 'object' then
        brokenObjects[source] = nil
        lightPositions[source] = nil
    end
end

addEventHandler('onClientElementStreamIn', root, unbrokeObject)
addEventHandler('onClientElementStreamOut', root, unbrokeObject)