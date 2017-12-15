local utf8 = require("utf8")
skull_font_width = 12
skull_font_height = 16
current_offset = 0
-- White, light gray, dark gray, light red, dark red
skull_pallette = {{255,255,255}, {170,170,170}, {85,85,85}, {255,82,82}, {170,0,0}}
-- These colors are like the following:
-- 0000000 | 11:22 33:44 aa:bb cc:dd 55:66 77:88 ee:ff gg:hh | 12345678911111
skull_colors = {1,1,0,0,3,3,4,4,0,4,0, -- 00000000 | 
                1,1,4,1,1,0,1,1,4,1,1, -- 31:32 33:34
                0,2,2,4,2,2,0,2,2,4,2,2,0, -- 35:36 37:38
                1,1,4,1,1,0,1,1,4,1,1, -- 39:40 41:42
                0,2,2,4,2,2,0,2,2,4,2,2, -- 43:44 45:46
                0,4,0,1,1,1,1,2,2,2,2,1,1,1,1,2,2,2,2} -- | 1234567891111111
shift_on = false

max_rows = 25
kern_offset = 3
max_columns = ((8) + 3 + (32 + 8 + 7) + 3 + (16))

sx = 2
sy = 2

padding_x = 4
padding_y = 4

cursor_x = 12
cursor_y = 0
cursor_color = skull_pallette[2]
cursor_background_color = {0, 0, 0}

global_coords_min_cursor_x = 12
global_coords_max_cursor_x = 48

function range(from, to, step)
    step = step or 1
    return function(_, lastvalue)
        local nextvalue = lastvalue + step
        if step > 0 and nextvalue <= to or step < 0 and nextvalue >= to or
             step == 0
        then
            return nextvalue
        end
    end, nil, from - step
end

function _build_skull_str(row)
    -- The current row we are computing:
    base_number = current_offset + (16 * row)
    offset_str = string.format("%08x", base_number)
    base_string = offset_str
    bytes_string = ""
    values_str = ""
    for i=0,15 do
        char_int = file_data.byte(base_number + i + 1)
        bytes_string = bytes_string .. string.format("%02x", char_int)
        if i % 2 == 0 then
            bytes_string = bytes_string .. ":"
        else
            bytes_string = bytes_string .. " "
        end
    end

    -- I could do this better but I don't care right now.
    for i=0,15 do
        char_int = file_data.byte(base_number + i + 1)
        values_str = values_str .. string.char(char_int)
    end
    --return 00:00 00:00 00:00 00:00 FF:FF FF:FF FF:FF FF:FF
    return base_string .. " \179 ".. bytes_string .. "\179 " .. values_str
end
function _skull_quad(row, column)
    return love.graphics.newQuad(column * skull_font_width, row * skull_font_height + (3 * row),
        skull_font_width, skull_font_height, skull_font:getWidth(), skull_font:getHeight())
end

function _row_and_column_for_char(char)
    -- Everything greater than 20 is ASCII
    local byte = string.byte(char)
    local row = math.floor(byte / 32)
    local column = byte % 32
    return {row, column}
end

function load_file(file_to_open)
    local inp = assert(io.open(file_to_open, "rb"))

    file_data = inp:read("*all")
    assert(inp:close())
end

function love.load(arg)
    file_to_open = arg[2]

    load_file(file_to_open)

    love.mouse.setVisible(false)
    skull_font = love.graphics.newImage("font.png")
    local width = sx * (max_columns * skull_font_width) - (max_columns * kern_offset) + (padding_x * 3)
    local height = sy * max_rows * skull_font_height
    love.window.setTitle("Skulledit")
    love.window.setMode(width, height, {resizable=false, vsync=false})
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    if key == "pagedown" then
        current_offset = current_offset + (16 * max_rows)
    end
    if key == "pageup" then
        current_offset = current_offset - (16 * max_rows)
        if current_offset < 0 then
            current_offset = 0
        end
    end
    if key == "up" then
        cursor_y = cursor_y - 1
    end
    if key == "down" then
        cursor_y = cursor_y + 1
    end
    if key == "left" then
        cursor_x = cursor_x - 1
    end
    if key == "right" then
        cursor_x = cursor_x + 1
    end
    --if key == "backspace" then
    --    local byteoffset = utf8.offset(_build_skull_str(), -1)

    --    if byteoffset then
    --        skull_str = string.sub(skull_str, 1, byteoffset - 1)
    --    end
    --end
end

function love.textinput(key)
    --skull_str = skull_str .. key
end

function love.draw()
    love.graphics.scale(sx, sy)
    local row_iter = 0
    for row_to_draw in range(0, max_rows) do
        local roffset = row_to_draw
        local coffset = 0
        local cur_iter = 0
        for c in _build_skull_str(row_iter):gmatch"." do
            local current_color_idx = skull_colors[(cur_iter % table.getn(skull_colors)) + 1]
            local current_color = skull_pallette[current_color_idx + 1]
            local draw_cursor = false

            local row_and_col = _row_and_column_for_char(c)
            local skull_quad = _skull_quad(row_and_col[1], row_and_col[2])

            local x = cur_iter * (skull_font_width - kern_offset) + padding_x
            local y = roffset * skull_font_width + (row_iter * 3) + padding_y

            if cursor_y == row_iter and cursor_x == cur_iter then
                draw_cursor = true
                love.graphics.setBackgroundColor(cursor_background_color[1], cursor_background_color[2], cursor_background_color[3])
                love.graphics.rectangle("fill", x, y, skull_font_width, skull_font_height)
                love.graphics.setBackgroundColor(0, 0, 0)
            else
                draw_cursor = false
            end

            if draw_cursor == true then
                love.graphics.setColor(cursor_color[1], cursor_color[2], cursor_color[3], 255)
            else
                love.graphics.setColor(current_color[1], current_color[2], current_color[3], 255)
            end

            love.graphics.draw(skull_font,
                skull_quad,
                x,
                y,
                0, 1, 1, 0, 0)
            cur_iter = cur_iter + 1
        end
        row_iter = row_iter + 1
    end
end
