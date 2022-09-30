-- global active scene
active_scene = nil
-- previous scene shown
last_scene = nil

scene_manager = {
    -- time spent in the active scene
    scene_t = 0,
    -- fade alpha between scenes
    fade_t = 0,
}

local scenes = {}

function register_scene(name, scene) -- { enter, update, draw, exit }
    scenes[name] = scene
end

function set_active_scene_by_id(scene, fade_time)
    last_scene = active_scene

    local function change_scene()
        if last_scene ~= nil and last_scene.exit ~= nil then
            last_scene.exit()
        end
        local next_scene = scene
        if next_scene.enter ~= nil then
            next_scene.enter()
        end
        active_scene = next_scene
        scene_manager.scene_t = 0
    end

    if fade_time == nil or fade_time == 0 then
        change_scene()
    else
        flux.to(scene_manager, fade_time, { fade_t = 1 })
            :onstart(function() block_inputs = true end)
            :ease('quadout')
            :oncomplete(change_scene)
            :after(scene_manager, fade_time, { fade_t = 0 })
            :ease('quadin')
            :onstart(function() block_inputs = false end)
    end
end

function set_active_scene_by_name(name, fade_time)
    set_active_scene_by_id(scenes[name], fade_time)
end