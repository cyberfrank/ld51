local pattern = {
    {0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0},
}

local time = 0
local cursor_t = 0
local last_update_time = 0
local last_beat = 0
local period = 60 / 120 / 2
local sound_sources = {
    find_sound('Drumtraks-Closed-4.wav'),
    find_sound('Drumtraks-Closed-4.wav'),
    find_sound('Drumtraks-Closed-4.wav'),
    find_sound('Drumtraks-Claps-7.wav'),
    find_sound('Drumtraks-Snare-4.wav'),
    find_sound('Drumtraks-Bass-4.wav'),
}

local function enter()
    print('enter')
end

local function update(dt)

    -- 96BPM is 10sec
    local beat = math.floor(time / period) % 8 + 1
    if last_beat ~= beat then
        local sources_to_play = {}
        for i=1,#sound_sources do
            if pattern[i][beat] ~= 0 then lume.push(sources_to_play, sound_sources[i]) end
        end
        if #sources_to_play > 0 then love.audio.play(sources_to_play) end
        last_beat = beat
    end

    time = time + dt
end

local function draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle('line', 0, 0, screen_w, screen_h / 2)
    
    local ww = screen_w/9
    local hh = screen_h/2/8
    for y=1,6 do
        for x=1,8 do
            local pad = 3
            local r = {
                x=ww*x + pad,
                y=screen_h/2-hh+y*hh + pad,
                w=ww - pad * 2,
                h=hh - pad * 2,
            }
            if imgui.update_control(imgui.generate_id(), r) then
                pattern[y][x] = pattern[y][x] == 0 and 1 or 0
            end
            local fill = pattern[y][x] ~= 0
            love.graphics.setColor(1, 1, 1, fill and 1 or 0.5)
            love.graphics.rectangle(fill and 'fill' or 'line', r.x, r.y, r.w, r.h)
        end
    end

    love.graphics.setColor(1, 1, 0)
    local cursor_x = lume.lerp(ww, screen_w, (time / period / 8) % 1)
    love.graphics.line(cursor_x, screen_h/2, cursor_x, screen_h-hh*2)
end

local function exit()
    print('exit')
end

return {
    enter=enter,
    update=update,
    draw=draw,
}