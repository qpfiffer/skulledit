local utf8 = require("utf8")
skull_font_width = 12
skull_font_height = 16
skull_str = "0000FFFF \179 00:00 00:00 00:00 00:00 FF:FF FF:FF FF:FF FF:FF \179 \0\1\2\3\4\5\6\7\8\9\10\11\12\13\14\15"
-- White, light gray, dark gray, light red, dark red
skull_pallette = {{255,255,255}, {170,170,170}, {85,85,85}, {255,82,82}, {170,0,0}}
skull_colors = {1,1,0,0,3,3,4,4,0,4,0,
                1,1,4,1,1,0,1,1,4,1,1,
                0,2,2,4,2,2,0,2,2,4,2,2,0,
                1,1,4,1,1,0,1,1,4,1,1,
                0,2,2,4,2,2,0,2,2,4,2,2,
                0,4,0,1,1,1,1,2,2,2,2,1,1,1,1,2,2,2,2}
shift_on = false

max_rows = 25
kern_offset = 3
max_columns = ((8) + 3 + (32 + 8 + 7) + 3 + (16))

padding_x = 4
padding_y = 4

cursor_pos = {0, 0}

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

function love.load()
    love.mouse.setVisible(false)
    skull_font = love.graphics.newImage("font.png")
    local width = (max_columns * skull_font_width) - (max_columns * kern_offset) + (padding_x * 3)
    local height = max_rows * skull_font_height
    love.window.setTitle("Skulledit")
    love.window.setMode(width, height, {resizable=false, vsync=false})
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    if key == "backspace" then
        local byteoffset = utf8.offset(skull_str, -1)

        if byteoffset then
            skull_str = string.sub(skull_str, 1, byteoffset - 1)
        end
    end
end

function love.textinput(key)
    skull_str = skull_str .. key
end

function love.draw()
    local row_iter = 0
    for row_to_draw in range(0, max_rows) do
        local roffset = row_to_draw
        local coffset = 0
        local cur_iter = 0
        for c in skull_str:gmatch"." do
            local current_color_idx = skull_colors[(cur_iter % table.getn(skull_colors)) + 1]
            local current_color = skull_pallette[current_color_idx + 1]
            love.graphics.setColor(current_color[1], current_color[2], current_color[3], 255)
            row_and_col = _row_and_column_for_char(c)
            skull_quad = _skull_quad(row_and_col[1], row_and_col[2])
            love.graphics.draw(skull_font, skull_quad, cur_iter * (skull_font_width - kern_offset) + padding_x, roffset * skull_font_width + (row_iter * 3) + padding_y, 0, 1, 1, 0, 0)
            cur_iter = cur_iter + 1
        end
        row_iter = row_iter + 1
    end
end
