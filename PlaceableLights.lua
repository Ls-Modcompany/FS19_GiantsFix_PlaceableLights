-- 
-- Giantsfix: PlaceableLights
-- 
-- @Interface: 1.4.1.0 b5332
-- @Author: LS-Modcompany / kevink98
-- @Date: 25.09.2019
-- @Version: 1.0.0.0
-- 
-- @Support: LS-Modcompany
-- 
-- Changelog:
--		
-- 	v1.0.0.0 (25.09.2019):
-- 		- initial fs19 (kevink98)
-- 
-- Notes:
--
-- 
-- ToDo:
-- 

GiantsFixPlaceableLights = {}

function GiantsFixPlaceableLights:load(xmlFilename, x,y,z, rx,ry,rz, initRandom)
    local xmlFile = loadXMLFile("TempXML", xmlFilename)
    if xmlFile == 0 then
        return false
    end

    if hasXMLProperty(xmlFile, "placeable.dayNightObjects") then
        local i = 0
        while true do
            local key = string.format("placeable.dayNightObjects.dayNightObject(%d)", i)
            if not hasXMLProperty(xmlFile, key) then
                break
            end
            local node = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, key.."#node"))
            if node ~= nil then     
                self.dayNightObjects[i+1].visibleRain = Utils.getNoNil(getXMLBool(xmlFile, key.."#visibleRain"), true)
                self.dayNightObjects[i+1].intensityRain = Utils.getNoNil(getXMLBool(xmlFile, key.."#intensityRain"), self.dayNightObjects[i+1].intensityNight)
            end
            i = i + 1
        end
    end

    delete(xmlFile)
end

function GiantsFixPlaceableLights:weatherChanged(superFunc)
    if g_currentMission ~= nil and g_currentMission.environment ~= nil and self.dayNightObjects ~= nil then
        for i, dayNightObject in pairs(self.dayNightObjects) do
            if dayNightObject.visibleDay ~= nil and dayNightObject.visibleNight ~= nil then
                setVisibility(dayNightObject.node, (g_currentMission.environment.isSunOn and dayNightObject.visibleDay) 
                or (dayNightObject.visibleNight and not g_currentMission.environment.isSunOn)
                or (dayNightObject.visibleRain and g_currentMission.environment.weather:getIsRaining()))
            elseif dayNightObject.intensityDay ~= nil and dayNightObject.intensityNight ~= nil and dayNightObject.intensityRain ~= nil then
                local intensity = dayNightObject.intensityNight
                if g_currentMission.environment.isSunOn then
                    intensity = dayNightObject.intensityDay
                end

                if g_currentMission.environment.weather:getIsRaining() then
                    intensity = dayNightObject.intensityRain
                end

                local _,y,z,w = getShaderParameter(dayNightObject.node, "lightControl")
                setShaderParameter(dayNightObject.node, "lightControl", intensity, y, z, w, false)
            end
        end
    end
end

function Utils.appendedFunctionWithReturn(oldFunc, newFunc)
    if oldFunc ~= nil then
        return function (...)
            local r = oldFunc(...)
            newFunc(...)
            return r
        end;
    else
        return newFunc
    end;
end;

Placeable.load = Utils.appendedFunctionWithReturn(Placeable.load, GiantsFixPlaceableLights.load);
Placeable.weatherChanged = Utils.overwrittenFunction(Placeable.weatherChanged, GiantsFixPlaceableLights.weatherChanged);