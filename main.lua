if pcall(require, "jit.opt") then
    require("jit.opt").start(
        "maxmcode=8192",
        "maxtrace=2000"
        --
    )
end
package.loaded.apu = nil
package.loaded.cpu = nil
package.loaded.nes = nil
package.loaded.pads = nil
package.loaded.palette = nil
package.loaded.ppu = nil
package.loaded.rom = nil
package.loaded.utils = nil
local NES = require "nes"
local UTILS = require "utils"
local PALETTE = require "palette"
local Pad = require "pads".Pad
local PPU = require "ppu"
local APU = require "apu"

local Nes = nil
local width = 256
local height = 240
local pixSize = 1
local lastSource
local joy
--local sound = false
local DEBUG = false
local function _load(arg)
    --[[
    love.profiler = require("libs/profile")
    love.profiler.hookall("Lua")
    love.profiler.start()
    --]]
    local file = shell.resolve(arg[1] or " ")
    --Nes = NES:new({file="tests/hello.nes", loglevel=5})
    Nes =
        NES:new(
        {
            file = file,
            loglevel = 0,
            debug = print,
            pc = nil,
            palette = UTILS.map(
                PALETTE:defacto_palette(),
                function(c)
                    return {c[1] / 256, c[2] / 256, c[3] / 256}
                end
            )
        }
    )
    --Nes:run()
    Nes:reset()
    --love.window.setMode(width, height, {resizable = true, minwidth = width, minheight = height, vsync = false})
    local samplerate = 44100
    local bits = 16
    local channels = 1
    --sound = love.sound.newSoundData(samplerate / 60 + 1, samplerate, bits, channels)
    --QS = love.audio.newQueueableSource(samplerate, bits, channels)
end
local keyEvents = {}
local keyButtons = {
    ["w"] = Pad.UP,
    ["a"] = Pad.LEFT,
    ["s"] = Pad.DOWN,
    ["d"] = Pad.RIGHT,
    ["p"] = Pad.A,
    ["o"] = Pad.B,
    ["g"] = Pad.SELECT,
    ["enter"] = Pad.START
}
local joyButtons = {
    --["w"] = Pad.UP,
    --["a"] = Pad.LEFT,
    --["s"] = Pad.DOWN,
    --["d"] = Pad.RIGHT,
    [1] = Pad.A,
    [2] = Pad.B,
    [8] = Pad.SELECT,
    [9] = Pad.START
}
local function keypressed(key)
    for k, v in pairs(keyButtons) do
        if k == key then
            keyEvents[#keyEvents + 1] = {"keydown", v}
        end
    end
end

local function keyreleased(key)
    for k, v in pairs(keyButtons) do
        if k == key then
            keyEvents[#keyEvents + 1] = {"keyup", v}
        end
    end
end

local lastJoyState = {0, 0}
local function joypressed(button)
    for k, v in pairs(joyButtons) do
        if k == button then
            keyEvents[#keyEvents + 1] = {"keydown", v}
        end
    end
end

local function joyreleased(button)
    for k, v in pairs(joyButtons) do
        if k == button then
            keyEvents[#keyEvents + 1] = {"keyup", v}
        end
    end
end

local function jstate(n)
    if n > 0.1 then return 1
    elseif n < -0.1 then return -1
    else return 0 end
end

local function joyaxis(x, y)
    x, y = jstate(x), jstate(y)
    if lastJoyState[1] ~= x then
        if lastJoyState[1] == 0 then
            if x == -1 then keyEvents[#keyEvents + 1] = {"keydown", Pad.UP}
            else keyEvents[#keyEvents + 1] = {"keydown", Pad.DOWN} end
        else
            if lastJoyState[1] == -1 then keyEvents[#keyEvents + 1] = {"keyup", Pad.UP}
            else keyEvents[#keyEvents + 1] = {"keyup", Pad.DOWN} end
            if x ~= 0 then
                if x == -1 then keyEvents[#keyEvents + 1] = {"keydown", Pad.UP}
                else keyEvents[#keyEvents + 1] = {"keydown", Pad.DOWN} end
            end
        end
    end
    if lastJoyState[2] ~= y then
        if lastJoyState[2] == 0 then
            if y == -1 then keyEvents[#keyEvents + 1] = {"keydown", Pad.LEFT}
            else keyEvents[#keyEvents + 1] = {"keydown", Pad.RIGHT} end
        else
            if lastJoyState[2] == -1 then keyEvents[#keyEvents + 1] = {"keyup", Pad.LEFT}
            else keyEvents[#keyEvents + 1] = {"keyup", Pad.RIGHT} end
            if y ~= 0 then
                if y == -1 then keyEvents[#keyEvents + 1] = {"keydown", Pad.LEFT}
                else keyEvents[#keyEvents + 1] = {"keydown", Pad.RIGHT} end
            end
        end
    end
    lastJoyState = {x, y}
end

local time = 0
local timeTwo = 0
local rate = 1 / 59.97
local fps = 0
local tickRate = 0
local tickRatetmp = 0
local pixelCount = PPU.SCREEN_HEIGHT * PPU.SCREEN_WIDTH
local function update()
    drawn = true
    tickRatetmp = tickRatetmp + 1
    for i, v in ipairs(keyEvents) do
        Nes.pads[v[1]](Nes.pads, 1, v[2])
    end
    keyEvents = {}
    Nes:run_once()
    --[[local samples = Nes.cpu.apu.output
    for i = 1, #samples do
        sound:setSample(i, samples[i])
    end
    QS:queue(sound)
    QS:play()]]
end
--[[
local function drawScreen()
    local sx = love.graphics.getWidth() / image:getWidth()
    local sy = love.graphics.getHeight() / image:getHeight()
    love.graphics.draw(image, 0, 0, 0, sx, sy)
    love.graphics.print(" Nes Tick Rate: " .. tostring(tickRate), 10, 10)
    love.graphics.print(" FPS: " .. tostring(fps), 10, 30)
end
local function drawPalette()
    local palette = Nes.cpu.ppu.output_color
    local w, h = 10, 10
    local x, y = 0, 50
    local row, column = 4, 8
    for i = 1, #palette do
        local px = palette[i]
        if px then
            local r = px[1]
            local g = px[2]
            local b = px[3]
            love.graphics.setColor(r, g, b, 1)
            love.graphics.rectangle("fill", x + ((i - 1) % row) * w, y + math.floor((i - 1) / 4) * h, w, h)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end
local function drawAPUState()
    local apu = Nes.cpu.apu
    love.graphics.print(" Pulse 1", 10, 140)
    local pulse_0 = apu.pulse_0
    love.graphics.print(
        string.format(
            "F:%d D:%d V:%d  S:%d C:%d",
            pulse_0.freq / 1000,
            pulse_0.duty,
            pulse_0.envelope.output / APU.CHANNEL_OUTPUT_MUL,
            pulse_0.step,
            pulse_0.length_counter.count
        ),
        10,
        160
    )
    love.graphics.print(" Pulse 2", 10, 180)
    local pulse_1 = apu.pulse_1
    love.graphics.print(
        string.format(
            "F:%d D:%d V:%d  S:%d C:%d",
            pulse_1.freq / 1000,
            pulse_1.duty,
            pulse_1.envelope.output / APU.CHANNEL_OUTPUT_MUL,
            pulse_1.step,
            pulse_1.length_counter.count
        ),
        10,
        200
    )
end
local function draw()
    drawScreen()
    if DEBUG then
        drawPalette()
        drawAPUState()
    end
end
]]
local fpsCharacters = {
    ["0"] = {
        "\255\255\255\254",
        "\255\254\255\254",
        "\255\254\255\254",
        "\255\254\255\254",
        "\255\255\255\254"
    },
    ["1"] = {
        "\254\255\254\254\254",
        "\254\255\254\254\254",
        "\254\255\254\254\254",
        "\254\255\254\254\254",
        "\254\255\254\254\254",
    },
    ["2"] = {
        "\255\255\255\254",
        "\254\254\255\254",
        "\255\255\255\254",
        "\255\254\254\254",
        "\255\255\255\254",
    },
    ["3"] = {
        "\255\255\255\254",
        "\254\254\255\254",
        "\255\255\255\254",
        "\254\254\255\254",
        "\255\255\255\254",
    },
    ["4"] = {
        "\255\254\255\254",
        "\255\254\255\254",
        "\255\255\255\254",
        "\254\254\255\254",
        "\254\254\255\254",
    },
    ["5"] = {
        "\255\255\255\254",
        "\255\254\254\254",
        "\255\255\255\254",
        "\254\254\255\254",
        "\255\255\255\254",
    },
    ["6"] = {
        "\255\255\255\254",
        "\255\254\254\254",
        "\255\255\255\254",
        "\255\254\255\254",
        "\255\255\255\254",
    },
    ["7"] = {
        "\255\255\255\254",
        "\254\254\255\254",
        "\254\254\255\254",
        "\254\254\255\254",
        "\254\254\255\254",
    },
    ["8"] = {
        "\255\255\255\254",
        "\255\254\255\254",
        "\255\255\255\254",
        "\255\254\255\254",
        "\255\255\255\254",
    },
    ["9"] = {
        "\255\255\255\254",
        "\255\254\255\254",
        "\255\255\255\254",
        "\254\254\255\254",
        "\255\255\255\254",
    },
    [" "] = {
        "\254\254\254\254",
        "\254\254\254\254",
        "\254\254\254\254",
        "\254\254\254\254",
        "\254\254\254\254",
    },
    ["F"] = {
        "\255\255\255\254",
        "\255\254\254\254",
        "\255\255\255\254",
        "\255\254\254\254",
        "\255\254\254\254",
    },
    ["P"] = {
        "\255\255\255\254",
        "\255\254\255\254",
        "\255\255\255\254",
        "\255\254\254\254",
        "\255\254\254\254",
    },
    ["S"] = {
        "\254\255\255\254",
        "\255\254\254\254",
        "\254\255\254\254",
        "\254\254\255\254",
        "\255\255\254\254",
    },
}

local last_render = os.epoch "utc"
local last_render_ = last_render
local lastFrameUpdate, frameCount = 0, 0
local function draw()
    --[
    time = time + ((os.epoch "utc" - last_render_) / 1000)
    timeTwo = timeTwo + ((os.epoch "utc" - last_render_) / 1000)
    while time > rate do
        time = time - rate
        update()
    end
    if timeTwo > 1 then
        timeTwo = 0
        tickRate = tickRatetmp
        tickRatetmp = 0
    end
    fps = 1 / ((os.epoch "utc" - last_render_) / 1000)
    --]]
    --[[
    timeTwo = timeTwo + love.timer.getDelta()
    if timeTwo > 1 then
        timeTwo = 0
        tickRate = tickRatetmp
        tickRatetmp = 0
    end
    update()
    --]]
    --[
    local pxs = Nes.cpu.ppu.output_pixels
    local palette = {}
    local pixels = {}
    for i = 1, pixelCount do
        local x = (i - 1) % width
        local y = math.floor((i - 1) / width) % height
        local px = pxs[i]
        --[[
        local r = rshift(band(px, 0x00ff0000), 16)
        local g = rshift(band(px, 0x0000ff00), 8)
        local b = band(px, 0x000000ff)
        --]]
        --[[
        local r = px[1]
        local g = px[2]
        local b = px[3]
        for j = 0, pixSize - 1 do
            for k = 0, pixSize - 1 do
                local xx = 1 + pixSize * (x) + j
                local yy = 1 + pixSize * (y) + k
                imageData:setPixel(xx, yy, r, g, b, 1)
            end
        end
        --]]
        --[
        local j = 1
        while j <= #palette do if palette[j][1] == px[1] and palette[j][2] == px[2] and palette[j][3] == px[3] then break end j=j+1 end
        if not palette[j] then
            if j >= 256 then error("Too many colors on screen") end
            palette[j] = px
        end
        --term.setPixel(x + 1, y + 1, j)
        if not pixels[y+1] then pixels[y+1] = "" end
        pixels[y+1] = pixels[y+1] .. string.char(j-1)
        --]]
    end
    for j = 1, #palette do term.setPaletteColor(j-1, palette[j][1], palette[j][2], palette[j][3]) end
    term.drawPixels(0, 0, pixels)
    if math.floor(os.epoch("utc") / 1000) > lastFrameUpdate then
        lastFrameUpdate = math.floor(os.epoch("utc") / 1000)
        local str = tostring(frameCount) .. " FPS"
        term.setPaletteColor(254, 0, 0, 0)
        term.setPaletteColor(255, 1, 1, 1)
        for i = 1, #str do term.drawPixels(256 + i*4, 0, fpsCharacters[str:sub(i, i)]) end
        frameCount = 0
    end
    frameCount=frameCount+1
    --image:replacePixels(imageData)

    --draw()
end

term.setGraphicsMode(2)
term.clear()
if sound then
    for i = 1, 5 do sound.setVolume(i, 0) sound.setPan(i, 0) end
    sound.setWaveType(1, "square")
    sound.setWaveType(2, "square")
    sound.setWaveType(3, "triangle")
    sound.setWaveType(4, "noise")
    sound.setFrequency(4, 1)
end
if joystick and joystick.count() > 0 then joy = joystick.open(0) end

_load({...})
os.queueEvent("update")
local ok, err = pcall(parallel.waitForAny, function()
    while true do
        local ev = {os.pullEvent()}
        if ev[1] == "char" and ev[2] == "q" then break
        elseif ev[1] == "key" and not ev[3] then keypressed(keys.getName(ev[2]))
        elseif ev[1] == "key_up" then keyreleased(keys.getName(ev[2]))
        elseif ev[1] == "joystick_press" and ev[2] == 0 then joypressed(ev[3])
        elseif ev[1] == "joystick_up" and ev[2] == 0 then joyreleased(ev[3])
        elseif ev[1] == "joystick_axis" and ev[2] == 0 then
            if ev[3] == 0 then joyaxis(lastJoyState[1], ev[4])
            elseif ev[3] == 1 then joyaxis(ev[4], lastJoyState[2]) end
        end
    end
end, function()
    while true do
        os.pullEvent("update")
        if os.epoch("utc") - last_render >= 16 then
            last_render = os.epoch("utc")
            draw()
            last_render_ = last_render
        end
        os.queueEvent("update")
    end
end)
if not ok then printError(err) end

term.setGraphicsMode(0)
for i = 0, 15 do term.setPaletteColor(2^i, term.nativePaletteColor(2^i)) end
if sound then for i = 1, 5 do sound.setVolume(i, 0) sound.setFrequency(i, 0) end end
if joy then joy.close() end
--term.setBackgroundColor(colors.black)
--term.setTextColor(colors.white)
--term.clear()
--term.setCursorPos(1, 1)
