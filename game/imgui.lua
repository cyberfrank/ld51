default_theme = {
    bg = "#111111",
    fg = "#777777",
    active = "#555555",
    hover = "#333333",
    highlight = "#ffffff",
    accent = "#ff8800",
    backdrop = '#ffffff',
    text = '#000000',
    text_pad_w = 6,
    text_pad_h = 2,
}

game_theme = {
    bg = "#494E87",
    fg = "#7C81BB",
    active = "#282B49",
    hover = "#7C81BB",
    highlight = "#ffffff",
    accent = "#498CFF",
    backdrop = '#78F6B9',
    text = '#38685D',
    text_pad_w = 6,
    text_pad_h = 2,
}

local theme = default_theme

local imgui = {
    num_controls = 0,
    active_id = 0,
    hover_id = 0,
    press_x = 0,
    press_y = 0,
}

function remap(value, min1, max1, min2, max2)
    return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
end

function rect_inset(r, pad_x, pad_y)
    return {x=r.x+pad_x, y=r.y+pad_y, w=r.w-pad_x*2, h=r.h-pad_y*2}
end

function rect_split_h(r, value)
    local left = {x=r.x, y=r.y, w=r.w*value, h=r.h}
    local right = {x=r.x+r.w*value, y=r.y, w=r.w*(1-value), h=r.h}
    return left, right
end

function rect_split_v(r, value)
    local top = {x=r.x, y=r.y, w=r.w, h=r.h*value}
    local bottom = {x=r.x, y=r.y+r.h*value, w=r.w, h=r.h*(1-value)}
    return top, bottom
end

local function point_in_rect(x, y, r)
    return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

function imgui.set_theme(t)
    theme = t
end

function imgui.generate_id()
    imgui.num_controls = 1 + imgui.num_controls
    return imgui.num_controls
end

function imgui.update_control(id, rect)
    local result = false
    local tx, ty = love.graphics.transformPoint(rect.x, rect.y)
    local mx, my = love.mouse.getPosition()

    local mouse_in_rect = point_in_rect(mx, my, { x=tx, y=ty, w=rect.w, h=rect.h })

    if mouse_in_rect then
        if imgui.active_id == 0 then imgui.hover_id = id end
    end

    if imgui.active_id == id then
        if mouse_released(1) then
            if mouse_in_rect then result = true end
            imgui.active_id = 0
        end
    elseif mouse_in_rect then
        if mouse_pressed(1) then 
            imgui.active_id = id 
            imgui.press_x = mx
            imgui.press_y = my
        end
    else
        imgui.hover_id = 0
    end

    return result, mouse_in_rect
end

function imgui.begin_frame(w, h)
    imgui.set_theme(default_theme)
    local viewport_id = imgui.generate_id()
    imgui.update_control(viewport_id, {x=0, y=0, w=w, h=h})
end

function imgui.end_frame()
    imgui.num_controls = 0
end

function imgui.text(text) -- (text, rect, align, color)
    local font = love.graphics.getFont()
    local fw = font:getWidth(text.text)
    local fh = font:getHeight()
    local r = lume.clone(text.rect)

    if text.align == 'left' then end
    if text.align == 'center' then r.x = r.x + (r.w - fw) / 2 end
    if text.align == 'right' then r.x = r.x + (r.w - fw) end

    r.y = r.y + (r.h - fh) / 2
    r.w = fw
    r.h = fh

    if text.color ~= nil then
        love.graphics.setColor(lume.color(text.color))
    else
        love.graphics.setColor(lume.color(theme.text))
    end
    love.graphics.print(text.text, lume.round(r.x), lume.round(r.y))
    
    return r
end

local function draw_rounded_rect(x, y, w, h, r)
    -- quality
    local q = 32

    if r == nil or r == 0 then
        love.graphics.rectangle('fill', x, y, w, h)
        return
    end

    if r == w/2 and r == h/2 then
        love.graphics.circle('fill', x+r, y+r, r, q)
        return
    end

    local right = 0
    local left = math.pi
    local bottom = math.pi * 0.5
    local top = math.pi * 1.5

    love.graphics.rectangle('fill', x, y+r, w, h-r*2)
    love.graphics.rectangle('fill', x+r, y, w-r*2, r)
    love.graphics.rectangle('fill', x+r, y+h-r, w-r*2, r)
    love.graphics.arc('fill', x+r, y+r, r, left, top, q)
    love.graphics.arc('fill', x + w-r, y+r, r, -bottom, right, q)
    love.graphics.arc('fill', x + w-r, y + h-r, r, right, bottom, q)
    love.graphics.arc('fill', x+r, y + h-r, r, bottom, left, q)
end

function imgui.button(btn) -- (rect={x,y,w,h}, text, align)
    local id = imgui.generate_id()
    local result = imgui.update_control(id, btn.rect)

    local color_hex
    if imgui.hover_id == id then 
        color_hex = theme['hover']
    elseif imgui.active_id == id then
        color_hex = theme['active']
    else
        color_hex = theme['bg']
    end

    love.graphics.setColor(lume.color(color_hex))
    draw_rounded_rect(btn.rect.x, btn.rect.y, btn.rect.w, btn.rect.h, btn.radius)

    if btn.text ~= nil then
        imgui.text({
            text = btn.text,
            rect = rect_inset(btn.rect, theme.text_pad_w, theme.text_pad_h),
            align = btn.align or 'center',
            color = theme.highlight,
        })
    end

    return result, id
end

function imgui.hslider(s) -- (x0, x1, y, value, notches)
    local knob_r = 8
    local slider_r = 2
    
    local x_pos = lume.lerp(s.x0, s.x1, s.value)
    love.graphics.setColor(lume.color(theme.fg))
    draw_rounded_rect(x_pos, s.y-slider_r, s.x1-x_pos, slider_r*2, slider_r)

    love.graphics.setColor(lume.color(theme.bg))
    draw_rounded_rect(s.x0, s.y-slider_r, x_pos-s.x0, slider_r*2, slider_r)

    local slider_rect = {x=s.x0, y=s.y, w=s.x1-s.x0, h=knob_r*2}
    local touched = imgui.update_control(imgui.generate_id(), slider_rect)

    -- love.graphics.rectangle('line', slider_rect.x, slider_rect.y, slider_rect.w, slider_rect.h)

    local _, knob_id = imgui.button({
        rect={x=x_pos-knob_r, y=s.y-knob_r, w=knob_r*2, h=knob_r*2},
        radius=knob_r,
    })

    if touched or imgui.active_id == knob_id then
        local mx = love.mouse.getX()
        local dx = lume.clamp((mx - s.x0) / (s.x1 - s.x0), 0, 1)
        if s.notches ~= nil and s.notches > 1 then
            local scaled = lume.round(dx * (s.notches - 1))
            dx = scaled / (s.notches - 1)
        end
        s.value = dx
    end
    
    return s.value
end

function imgui.vslider(s) -- (y0, y1, x, value, notches)
    local knob_r = 8
    local slider_r = 2

    local y_pos = lume.lerp(s.y0, s.y1, 1-s.value)
    love.graphics.setColor(lume.color(theme.fg))
    draw_rounded_rect(s.x+knob_r-slider_r, s.y0, slider_r*2, y_pos-s.y0, slider_r)
    
    love.graphics.setColor(lume.color(theme.bg))
    draw_rounded_rect(s.x+knob_r-slider_r, y_pos, slider_r*2, s.y1-y_pos, slider_r)

    local slider_rect = {x=s.x, y=s.y0, w=knob_r*2, h=s.y1-s.y0}
    local touched = imgui.update_control(imgui.generate_id(), slider_rect)

    -- love.graphics.rectangle('line', slider_rect.x, slider_rect.y, slider_rect.w, slider_rect.h)

    local _, knob_id = imgui.button({
        rect={x=s.x, y=y_pos-knob_r, w=knob_r*2, h=knob_r*2},
        radius=knob_r,
    })

    if touched or imgui.active_id == knob_id then
        local my = love.mouse.getY()
        local dy = lume.clamp((my - s.y0) / (s.y1 - s.y0), 0, 1)
        if s.notches ~= nil and s.notches > 1 then
            local scaled = lume.round(dy * (s.notches - 1))
            dy = scaled / (s.notches - 1)
        end
        s.value = 1-dy
    end

    return s.value
end

function imgui.rotary(s) -- (x, y, r, value, notches)
    local rotary_r = {x=s.x, y=s.y, w=s.r*2, h=s.r*2}
    local id = imgui.generate_id()
    local tapped, mouse_in_rect = imgui.update_control(id, rotary_r)

    local seg = 64
    local gap = 0.32
    local inner_r = s.r * 0.8
    local line_r = s.r * 0.06

    love.graphics.setColor(lume.color(theme.bg))
    love.graphics.arc('fill', s.x+s.r, s.y+s.r, s.r, -math.pi*(1+gap), math.pi*gap, seg)

    local progress = remap(s.value, 0, 1, -math.pi*(1+gap), math.pi*gap)
    love.graphics.setColor(lume.color(theme.accent))
    love.graphics.arc('fill', s.x+s.r, s.y+s.r, s.r, -math.pi*(1+gap), progress, seg)

    love.graphics.setColor(lume.color(theme.backdrop))
    love.graphics.circle('fill', s.x+s.r, s.y+s.r, inner_r, seg)

    love.graphics.setColor(lume.color(theme.bg))
    love.graphics.setLineWidth(line_r*2)
    local mapped_value = remap(s.value, 0, 1, -math.pi*(1+gap), math.pi*gap)
    local xa, ya = lume.vector(mapped_value, s.r)
    love.graphics.line(s.x+s.r, s.y+s.r, s.x+s.r+xa, s.y+s.r+ya)

    -- love.graphics.rectangle('line', rotary_r.x, rotary_r.y, rotary_r.w, rotary_r.h)

    if mouse_in_rect and mouse_pressed(1) then
        -- hack
        rotary_mem = s.value 
    end

    if imgui.active_id == id then
        local drag_r = s.r * 4
        local my = love.mouse.getY()
        local dy = lume.clamp((imgui.press_y - my) / drag_r + rotary_mem, 0, 1)
        if s.notches ~= nil and s.notches > 1 then
            local scaled = lume.round(dy * (s.notches - 1))
            dy = scaled / (s.notches - 1)
        end
        s.value = dy
    end

    love.graphics.setLineWidth(1.0)
    return s.value
end

function imgui.checkbox(t) -- {x, y, r, value, text, radius}
    local r = t.r or 8
    if imgui.button({
        rect={x=t.x, y=t.y, w=r*2, h=r*2},
        radius=radius,
    }) then
        t.value = not t.value
    end

    if t.value then
        local inner_r = r * 0.6
        love.graphics.setColor(lume.color(theme.highlight))
        love.graphics.draw(find_image('icon-check.png'), t.x + r, t.y + r, 0, 1, 1, 8, 8)
    end

    return t.value
end

function imgui.segmented(t) -- {rect={x,y,w,h}, options={}, value}
    local r = t.rect
    local count = lume.count(t.options)
    local item_w = r.w / count

    for i, k in ipairs(t.options) do
        local ri = {x=r.x+item_w*(i-1), y=r.y, w=item_w, h=r.h}
        if imgui.update_control(imgui.generate_id(), ri) then
            t.value = i
        end

        local is_selected = (t.value == i)
        love.graphics.setColor(lume.color(theme.bg))
        love.graphics.rectangle('line', ri.x, ri.y, ri.w, ri.h)

        if is_selected then
            love.graphics.rectangle('fill', ri.x, ri.y, ri.w, ri.h)
        end

        imgui.text({
            rect=ri,
            text=k,
            color=(is_selected and theme.highlight or theme.bg),
            align='center',
        })
    end

    return t.value
end

return imgui