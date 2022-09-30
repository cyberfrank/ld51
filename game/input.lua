local mouse = {
    down = {},
    pressed = {},
    released = {},
}

local keyboard = {
    down = {},
    pressed = {},
    released = {},
}

function key_pressed(k) 
    return keyboard.pressed[k] 
end

function key_released(k) 
    return keyboard.released[k] 
end

function key_down(k)
    return keyboard.down[k]
end

function set_key_pressed(k)
    keyboard.down[k] = true
    keyboard.pressed[k] = true
end

function set_key_released(k)
    keyboard.down[k] = false
    keyboard.released[k] = true
end

function mouse_pressed(btn) 
    return mouse.pressed[btn] 
end

function mouse_released(btn) 
    return mouse.released[btn] 
end

function mouse_down(btn)
    return mouse.down[btn]
end

function set_mouse_pressed(btn)
    mouse.down[btn] = true
    mouse.pressed[btn] = true
end

function set_mouse_released(btn)
    mouse.down[btn] = false
    mouse.released[btn] = true
end

function clear_inputs()
    for i, _ in pairs(keyboard.pressed) do
        keyboard.pressed[i] = false
    end
    for i, _ in pairs(keyboard.released) do
        keyboard.released[i] = false
    end
    for i, _ in pairs(mouse.pressed) do
        mouse.pressed[i] = false
    end
    for i, _ in pairs(mouse.released) do
        mouse.released[i] = false
    end
end