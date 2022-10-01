local imgui = {
    num_controls = 0,
    active_id = 0,
    hover_id = 0,
    press_x = 0,
    press_y = 0,
}

function rect_inset(r, pad_x, pad_y)
    return {x=r.x+pad_x, y=r.y+pad_y, w=r.w-pad_x*2, h=r.h-pad_y*2}
end

local function point_in_rect(x, y, r)
    return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
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
        love.graphics.setColor(lume.color(bg_col))
    end
    love.graphics.print(text.text, lume.round(r.x), lume.round(r.y))
    
    return r
end

function imgui.button(btn) -- (rect={x,y,w,h}, text, align)
    local id = imgui.generate_id()
    local result = imgui.update_control(id, btn.rect)

    love.graphics.setColor(lume.color(bg_col))
    love.graphics.rectangle(imgui.hover_id == id and 'fill' or 'line', btn.rect.x, btn.rect.y, btn.rect.w, btn.rect.h)

    if btn.text ~= nil then
        imgui.text({
            text = btn.text,
            rect = rect_inset(btn.rect, 6, 4),
            align = btn.align or 'center',
            color = imgui.hover_id == id and fg_col or bg_col
        })
    end

    return result, id
end

return imgui