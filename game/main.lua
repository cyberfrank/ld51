flux = require "lib/flux"
lume = require "lib/lume"
imgui = require "imgui"
require "input"
require "localize"
require "resources"
require "scene_manager"
-- game_scene = require "scenes/game"

t = 0
mouse_dx = 0
mouse_dy = 0
block_inputs = false

function love.load()
    screen_w, screen_h = love.graphics.getDimensions()
    love.graphics.setBackgroundColor(1, 1, 1)

    math.randomseed(os.time())
end

function love.quit()
    local save_data = {
        -- options = options,
        -- mixer = mixer,
    }
    -- love.filesystem.write('save.lua', lume.serialize(save_data))
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
    t = t + dt

    if active_scene.update ~= nil then 
        active_scene.update(dt) 
        scene_manager.scene_t = scene_manager.scene_t + dt
    end
end

function love.draw()
    imgui.begin_frame(screen_w, screen_h)

    if active_scene.draw ~= nil then 
        active_scene.draw() 
    end
    love.graphics.setColor(0, 0, 0, scene_manager.fade_t)
    love.graphics.rectangle('fill', 0, 0, screen_w, screen_h)

    if options.show_fps then
        love.graphics.setFont(find_font('Sen-Regular.ttf', 14))
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print('FPS: ' .. love.timer.getFPS(), 10, 10)
    end

    imgui.end_frame()
    clear_inputs()
end
