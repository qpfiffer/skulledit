local utf8 = require("utf8")
skull_font_width = 12
skull_font_height = 16
skull_str = "this is a TEST"
shift_on = false
function _skull_quad(row, column)
    return love.graphics.newQuad(column * skull_font_width, row * skull_font_height + (4 * row),
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
    skull_font = love.graphics.newImage("font.png")
end

function love.keypressed(key)
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
    cur_iter = 0
    for c in skull_str:gmatch"." do
        row_and_col = _row_and_column_for_char(c)
        skull_quad = _skull_quad(row_and_col[1], row_and_col[2])
        love.graphics.draw(skull_font, skull_quad, cur_iter * skull_font_width, 0, 0, 1, 1, 0, 0)
        cur_iter = cur_iter + 1
    end
end
