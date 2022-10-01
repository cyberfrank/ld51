flux = require "lib/flux"
lume = require "lib/lume"
imgui = require "imgui"
require "input"
require "localize"
require "resources"
require "level1"

mouse_dx = 0
mouse_dy = 0
block_inputs = false

local pattern = {
    {0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0},
    {1,0,1,0,0,0,1,0},
}
local goal_pattern = {}

local time = 0
local cursor_t = 0
local last_update_time = 0
local last_beat = 0
local beat_local_time = 0
local total_beats = 0
-- 96BPM is 10sec
local bpm = 96
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
local body_guide = {}
local head_dir = 0
local head_dir_goal = 0
local is_showdown = false
local is_game_over = false
local misses = 0
local current_level = 1
local bg_col = '#201010'
local fg_col = '#fff0db'

function love.load()
    screen_w, screen_h = love.graphics.getDimensions()
    love.graphics.setBackgroundColor(lume.color(bg_col))
    
    local guy = find_image('guy.png')
    guy:setFilter('nearest', 'nearest')

    body_parts = {
        love.graphics.newQuad(0, 0, 32, 32, guy), -- legs extended
        love.graphics.newQuad(32, 0, 32, 32, guy), -- legs contracted
        love.graphics.newQuad(128, 0, 16, 16, guy), -- torso
        love.graphics.newQuad(64, 0, 14, 17, guy), -- arm
        love.graphics.newQuad(96, 0, 16, 13, guy), -- head
        love.graphics.newQuad(96, 16, 20, 8, guy), -- hat
		love.graphics.newQuad(144, 0, 16, 16, guy), -- heart
    }

	local guide = find_image('guide.png')
	guide:setFilter('nearest', 'nearest')
	body_guide = {
		love.graphics.newQuad(0 * 46, 0, 46, 60, guide),
		love.graphics.newQuad(1 * 46, 0, 46, 60, guide),
		love.graphics.newQuad(2 * 46, 0, 46, 60, guide),
		love.graphics.newQuad(3 * 46, 0, 46, 60, guide),
		love.graphics.newQuad(4 * 46, 0, 46, 60, guide),
		love.graphics.newQuad(5 * 46, 0, 46, 60, guide),
	}

    math.randomseed(os.time())

	goal_pattern = level1_pattern[1]
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

function check_is_game_over()
	if is_game_over then return end
	if is_showdown then return end

	misses = 0
	for y=1,#sound_sources do
		for x=1,8 do
			if pattern[y][x] ~= goal_pattern[y][x] and (pattern[y][x] ~= 0 or goal_pattern[y][x] ~= 0) then
				misses = misses + 1
			end
		end
	end
	is_game_over = misses ~= 0
end

function reset()
	for y=1,#sound_sources do
		for x=1,8 do
			pattern[y][x] = 0
		end
	end
	is_game_over = false
	is_showdown = false
	time = 0
	total_beats = 0
	last_beat = -1
	current_level = 1
	goal_pattern = level1_pattern[current_level]
end

function love.update(dt)
    flux.update(dt)

	if key_pressed('r') then
		reset()
	end

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
		
		total_beats = total_beats + 1
		if total_beats % 32 == 0 then
			check_is_game_over()
		end
		if total_beats % 64 == 0 and not is_game_over then
			current_level = current_level + 1
			goal_pattern = level1_pattern[current_level]
			print('next level!')
		end

		is_showdown = math.ceil((total_beats % 64) / 32) % 2 == 0
		is_showdown = is_showdown or is_game_over

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
	local heart = sequence[1][beat] ~= 0 and not cooldown
    love.graphics.draw(guy, body_parts[3], x + 20, y - 5, 0, scale, scale)
	if heart then
		love.graphics.draw(guy, body_parts[7], x + 20, y - 5, 0, scale, scale)
	end
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
    love.graphics.draw(guy, body_parts[6], x + 44, y - 70 - (bump and 30 or 0), 0, dir, scale, 8, 0)

    love.graphics.pop()
    love.graphics.pop()
end

function draw_sequencer()
	local guide_pad = 6
	local xo = guide_pad
	local yo = 320
    local hh = (screen_h - yo - guide_pad)/#sound_sources

	love.graphics.setColor(lume.color(fg_col))
	local guide = find_image('guide.png')
	for y=0,#sound_sources-1 do
		love.graphics.draw(guide, body_guide[y+1], xo, yo+y*hh+7, 0, 1, 1)
	end

	xo = xo + 46 + guide_pad
	local ww = (screen_w/2 - xo)/8

    for y=0,#sound_sources-1 do
        for x=0,7 do
            local pad = 5
            local r = {
                x=xo + ww*x + pad,
                y=yo + y*hh + pad,
                w=ww - pad * 2,
                h=hh - pad * 2,
            }
			local src = y+1
			local slot = x+1
            if imgui.update_control(imgui.generate_id(), r) then
                pattern[src][slot] = pattern[src][slot] == 0 and 1 or 0
            end

			love.graphics.setColor(lume.color(fg_col, 0.5))
			love.graphics.rectangle('line', r.x, r.y, r.w, r.h)

            local fill = pattern[src][slot] ~= 0

			if fill then
				love.graphics.setColor(lume.color(fg_col, is_showdown and 0.5 or 1.0))
				love.graphics.rectangle('fill', r.x, r.y, r.w, r.h)
			end

			local is_miss = pattern[src][slot] ~= goal_pattern[src][slot]
			if is_showdown and (fill or is_miss) then
				local is_on_beat = (beat - 1) == x
				local alpha = is_on_beat and 1.0 - beat_local_time or 0.0
				local beat_color = is_miss and '#ff0000' or '#00ff00'
				love.graphics.setColor(lume.color(beat_color, alpha))
				love.graphics.rectangle('fill', r.x, r.y, r.w, r.h)
			end
        end
    end

    love.graphics.setColor(0, 1, 0)
    local cursor_x = lume.lerp(xo, ww*9, (time / period / 8) % 1)
    love.graphics.line(cursor_x, yo, cursor_x, screen_h - guide_pad)

	return xo + ww*8 + guide_pad, yo
end

function love.draw()
    imgui.begin_frame(screen_w, screen_h)

	love.graphics.setColor(lume.color(fg_col))
    draw_guy(195, 70, pattern, head_dir)
    local xo, yo = draw_sequencer()
	
	love.graphics.setColor(lume.color(fg_col))
	love.graphics.rectangle('fill', xo, 0, screen_w - xo, screen_h)

	love.graphics.setColor(lume.color(bg_col))
    draw_guy(695, 70, goal_pattern, head_dir_goal)
	
	love.graphics.setFont(find_font('pixel-font.ttf', 36))
	love.graphics.setColor(lume.color(bg_col))
	if is_game_over then
		love.graphics.printf('GAME OVER!', xo, yo, screen_w-xo, 'center')
		love.graphics.setColor(1, 0, 0)
		love.graphics.printf(misses .. ' MISSES', xo, yo + 40, screen_w-xo, 'center')
	else
		local text = is_showdown and 'NEXT LEVEL IN:' or 'SHOWDOWN IN:'
		love.graphics.printf(text, xo, yo, screen_w-xo, 'center')
		local level_countdown = 4 - (math.ceil((total_beats % 64) / 8) - 1) % 4
		love.graphics.printf(level_countdown, xo, yo + 40, screen_w-xo, 'center')
		
		love.graphics.setFont(find_font('pixel-font.ttf', 20))
		local level_countdown_time = string.format("%.1f", 10 - time % 10)
		love.graphics.printf(level_countdown_time .. ' sec', xo, yo + 80, screen_w-xo, 'center')
	end

	love.graphics.setFont(find_font('pixel-font.ttf', 12))
	love.graphics.setColor(1, 1, 1, 1)
    local show_fps = true
    if show_fps then
        love.graphics.print('FPS: ' .. love.timer.getFPS(), 10, 10)
    end

    imgui.end_frame()
    clear_inputs()
end
