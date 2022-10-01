flux = require "lib/flux"
lume = require "lib/lume"
imgui = require "imgui"
require "input"
require "localize"
require "resources"

mouse_dx = 0
mouse_dy = 0
block_inputs = false

local pattern = {
    {0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0},
}

local goal_pattern = {
    {0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0},
    {0,1,0,1,0,1,0,1},
    {0,0,0,0,0,0,0,0},
    {0,0,1,0,0,0,1,0},
    {1,0,1,0,1,0,1,0},
}

local time = 0
local cursor_t = 0
local last_update_time = 0
local last_beat = 0
local beat_local_time = 0
-- 96BPM is 10sec
local bpm = 120
local period = 60 / bpm / 2
local sound_sources = {
    find_sound('Drumtraks-Cabasa-7.wav'),
    find_sound('Drumtraks-Cowbell-7.wav'),
    find_sound('Drumtraks-Closed-4.wav'),
    find_sound('Drumtraks-Claps-7.wav'),
    find_sound('Drumtraks-Snare-4.wav'),
    find_sound('Drumtraks-Bass-4.wav'),
}
local body_parts = {}
local head_dir = 0
local head_dir_goal = 0

function love.load()
    screen_w, screen_h = love.graphics.getDimensions()
    love.graphics.setBackgroundColor(0, 0, 0)
    
    local guy = find_image('guy.png')
    guy:setFilter('nearest', 'nearest')

    body_parts = {
        love.graphics.newQuad(0, 0, 32, 32, guy), -- legs extended
        love.graphics.newQuad(32, 0, 32, 32, guy), -- legs contracted
        love.graphics.newQuad(128, 0, 16, 16, guy), -- torso
        love.graphics.newQuad(64, 0, 14, 17, guy), -- arm
        love.graphics.newQuad(96, 0, 16, 13, guy), -- head
        love.graphics.newQuad(96, 16, 20, 8, guy), -- hat
    }

    math.randomseed(os.time())
end

function love.mousepressed(x, y, button, istouch, presses)
    if block_inputs then return end
	set_mouse_pressed(button)
end

function love.mousemoved(x, y, dx, dy, istouch)
    mouse_dx = dx
    mouse_dy = dy
end

function love.mousereleased(x, y, button, istouch, presses)
    if block_inputs then return end
	set_mouse_released(button)
end

function love.keypressed(key)
    if block_inputs then return end
    set_key_pressed(key)
end

function love.keyreleased(key)
    if block_inputs then return end
    set_key_released(key)
end

function love.update(dt)
    flux.update(dt)

    beat_local_time = beat_local_time + dt
    time = time + dt

    beat = math.floor(time / period) % 8 + 1
    if last_beat ~= beat then
        local sources_to_play = {}
        for i=1,#sound_sources do
            if pattern[i][beat] ~= 0 then lume.push(sources_to_play, sound_sources[i]) end
        end
        if #sources_to_play > 0 then love.audio.play(sources_to_play) end
        last_beat = beat
        

        if pattern[3][beat] ~= 0 then 
            head_dir = head_dir + 1
        end
        if goal_pattern[3][beat] ~= 0 then 
            head_dir_goal = head_dir_goal + 1
        end

        beat_local_time = 0
    end
end

function draw_guy(x, y, sequence, head_dir)
    love.graphics.push()
    love.graphics.translate(25, 86)
    local guy = find_image('guy.png')
    local scale = 3
    local cooldown = beat_local_time > 0.6 * period
    local duck = sequence[6][beat] ~= 0 and not cooldown
    love.graphics.draw(guy, body_parts[duck and 2 or 1], x, y, 0, scale, scale)

    love.graphics.push()
    local legs_offset = (duck and 1 or 5) * scale
    love.graphics.translate(0, -legs_offset)
    -- torso
    love.graphics.draw(guy, body_parts[3], x + 20, y - 5, 0, scale, scale)
    -- arms
    local r_arm_up = sequence[5][beat] ~= 0 and not cooldown
    local l_arm_up = sequence[4][beat] ~= 0 and not cooldown
    love.graphics.draw(guy, body_parts[4], x + 72, y + 16, 0, scale, r_arm_up and -scale or scale, 0, 3)
    love.graphics.draw(guy, body_parts[4], x + 16, y + 16, 0, -scale, l_arm_up and -scale or scale, 0, 3)
    -- head
    local dir = head_dir % 2 == 0 and scale or -scale
    love.graphics.draw(guy, body_parts[5], x + 44, y - 41, 0, dir, scale, 8, 0)
    -- hat
    local bump = sequence[2][beat] ~= 0 and not cooldown
    love.graphics.draw(guy, body_parts[6], x + 44, y - 70 - (bump and 20 or 0), 0, dir, scale, 8, 0)

    love.graphics.pop()
    love.graphics.pop()
end

function draw_sequencer()
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

function love.draw()
    imgui.begin_frame(screen_w, screen_h)

    draw_guy(150, 50, pattern, head_dir)
    draw_guy(450, 50, goal_pattern, head_dir_goal)
    draw_sequencer()

    local show_fps = true
    if show_fps then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print('FPS: ' .. love.timer.getFPS(), 10, 10)
    end

    imgui.end_frame()
    clear_inputs()
end
