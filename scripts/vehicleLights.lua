local vehicleLights = {
    -- name, target offset x, y, z, useSecond, theta, phi, falloff, size, color
    {'light_front_main', 0, 1, -0.3, true, 0, 0.5, 0.6, 40, true},
    {'light_rear_main', -0.2, -1, -0.4, true, 0, 1, 1, 4, {555, 0, 0}},
    -- {'light_front_second', 0, 1, -0.5},
}

local customVehicleLights = {
    [481] = {
        {'light_front_main', 0, 1, -0.3, true, 0, 0.5, 0.6, 5, true},
    },
    [606] = {},
    [607] = {},
}

function areVehicleLightsOn(vehicle)
    local hour = getTime()
    return getVehicleOverrideLights(vehicle) == 2 or (getVehicleOverrideLights(vehicle) == 0 and isInTime(21, 6, hour))
end

function updateVehicleLights()
    local cx, cy, cz = getCameraMatrix()

    for _,vehicle in pairs(getElementsWithinRange(cx, cy, cz, settings.objectsLightsRenderDistance, 'vehicle')) do
        if areVehicleLightsOn(vehicle) then
            local lights = customVehicleLights[getElementModel(vehicle)] or vehicleLights
            for _,light in pairs(lights) do
                local x, y, z = getVehicleDummyPosition(vehicle, light[1])
                local tx, ty, tz = getPositionFromElementOffset(vehicle, x + light[2], y + light[3], z + light[4])
                local ex, ey, ez = getPositionFromElementOffset(vehicle, x, y, z)

                local color = light[10]
                if color == true then
                    local r, g, b = getVehicleHeadLightColor(vehicle)
                    local gray = (r + g + b) / 3
                    if gray < 140 then
                        r, g, b = r * 1.5, g * 1.5, b * 1.5
                    end
                    color = {r, g, b}
                end

                queueLight({ex, ey, ez}, color, light[9], {
                    direction = {tx - ex, ty - ey, tz - ez},
                    theta = light[6],
                    phi = light[7],
                    falloff = light[8],
                })

                if light[5] then
                    local tx, ty, tz = getPositionFromElementOffset(vehicle, -x - light[2], y + light[3], z + light[4])
                    local ex, ey, ez = getPositionFromElementOffset(vehicle, -x, y, z)

                    queueLight({ex, ey, ez}, color, light[9], {
                        direction = {tx - ex, ty - ey, tz - ez},
                        theta = light[6],
                        phi = light[7],
                        falloff = light[8],
                    })
                end
                -- local x, y, z = getPositionFromElementOffset(vehicle, 0, 3.3, 0)
                -- local matrix = getElementMatrix(vehicle)

                -- queueLight({x, y, z}, {255, 255, 255}, 15, {
                --     direction = {matrix[2][1], matrix[2][2], matrix[2][3] - 0.3},
                --     theta = 0,
                --     phi = 0.8,
                --     falloff = 0.4,
                -- })
            end
        end
    end
end