local data = {
    images = {},
    sounds = {},
    fonts = {},
}

function find_image(name)
    if data.images[name] == nil then
        data.images[name] = love.graphics.newImage('data/images/' .. name)
    end
    return data.images[name]
end

function find_sound(name)
    if data.sounds[name] == nil then
        data.sounds[name] = love.audio.newSource('data/sounds/' .. name, 'static')
    end
    return data.sounds[name]
end

function find_font(name, size)
    local id = name .. '_' .. size
    if data.fonts[id] == nil then
        data.fonts[id] = love.graphics.newFont('data/fonts/' .. name, size)
    end
    return data.fonts[id]
end