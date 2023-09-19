local vehicleLights = {
    -- name, target offset x, y, z, useSecond, theta, phi, falloff, size, color, isRear
    {'light_front_main', 0, 1, -0.3, true, 0, 0.5, 0.6, 40, true},
    {'light_rear_main', -0.2, -1, -0.4, true, 0, 1, 1, 4, {555, 0, 0}, true},
    -- {'light_front_second', 0, 1, -0.5},
}

local customVehicleLights = {
    [481] = {
        {'light_front_main', 0, 1, -0.3, true, 0, 0.5, 0.6, 5, true},
    },
    [446] = {
        -- {'light_rear_main', 0, 1, -0.3, true, 0, 0.5, 0.6, 400, true},
        -- {'light_rear_main', -0.2, 1, -0.4, true, 0, 1, 1, 80, true},
    },
    [453] = {
        -- {'light_rear_main', 0, 1, -0.3, true, 0, 0.5, 0.6, 400, true},
        -- {'light_rear_main', -0.2, 1, -0.4, true, 0, 1, 1, 80, true},
    },
    [606] = {},
    [607] = {},
}

function isVehicleGoingForward(vehicle, inverse)
    local matrix = getElementMatrix(vehicle)
    local vx, vy, vz = getElementVelocity(vehicle)

    local speed = math.sqrt(vx * vx + vy * vy + vz * vz)
    local direction = {vx / speed, vy / speed, vz / speed}

    return matrix[2][1] * direction[1] + matrix[2][2] * direction[2] + matrix[2][3] * direction[3] > 0
end

function areAnyVehicleLightsOn(vehicle)
    if areVehicleLightsOn(vehicle) then
        return 'on'
    else
        local driver = getVehicleOccupant(vehicle)
        if (driver and (getPedControlState(driver, 'brake_reverse') and not getPedControlState(driver, 'handbrake')) and isVehicleGoingForward(vehicle)) then return 'rear' end
        if (driver and (getPedControlState(driver, 'accelerate') and not getPedControlState(driver, 'handbrake')) and not isVehicleGoingForward(vehicle)) then return 'rear' end
    end

    return false
end

function updateVehicleLights()
    local cx, cy, cz = getCameraMatrix()
    
    for _,vehicle in pairs(getElementsWithinRange(cx, cy, cz, settings.objectsLightsRenderDistance, 'vehicle')) do
        local state = areAnyVehicleLightsOn(vehicle)
        if state then
            local lights = customVehicleLights[getElementModel(vehicle)] or vehicleLights
            for _,light in pairs(lights) do
                local canBeLit = (light[11] and state == 'rear') or state == 'on'
                if canBeLit then
                    local x, y, z = getVehicleDummyPosition(vehicle, light[1])
                    local color = light[10]
                    if color == true then
                        local r, g, b = getVehicleHeadLightColor(vehicle)
                        local gray = (r + g + b) / 3
                        if gray < 140 then
                            r, g, b = r * 1.5, g * 1.5, b * 1.5
                        end
                        color = {r, g, b}
                    end

                    if light[11] or getVehicleLightState(vehicle, 1) == 0 then
                        local tx, ty, tz = getPositionFromElementOffset(vehicle, x + light[2], y + light[3], z + light[4])
                        local ex, ey, ez = getPositionFromElementOffset(vehicle, x, y, z)

                        queueLight({ex, ey, ez}, color, light[9], {
                            direction = {tx - ex, ty - ey, tz - ez},
                            theta = light[6],
                            phi = light[7],
                            falloff = light[8],
                        })
                    end

                    if light[5] and (light[11] or getVehicleLightState(vehicle, 0) == 0) then
                        local tx, ty, tz = getPositionFromElementOffset(vehicle, -x - light[2], y + light[3], z + light[4])
                        local ex, ey, ez = getPositionFromElementOffset(vehicle, -x, y, z)

                        queueLight({ex, ey, ez}, color, light[9], {
                            direction = {tx - ex, ty - ey, tz - ez},
                            theta = light[6],
                            phi = light[7],
                            falloff = light[8],
                        })
                    end
                end
            end
        end
    end
end