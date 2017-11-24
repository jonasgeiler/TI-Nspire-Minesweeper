---- GLOBAL VARS ----
levels = {
    beginner = {
        id = 1,
        rows = 10,
        cols = 10,
        mines = 10
    },
    intermediate = {
        id = 2,
        rows = 10,
        cols = 15,
        mines = 25
    },
    expert = {
        id = 3,
        rows = 10,
        cols = 18,
        mines = 36
    }
}
defaultLevel = 'beginner'
tile = {
    nothing = 0,
    num1 = 1,
    num2 = 2,
    num3 = 3,
    num4 = 4,
    num5 = 5,
    num6 = 6,
    num7 = 7,
    num8 = 8,
    bomb = 9,
    normal = 10,
    flag = 11,
    marked = 12,
    clicked_bomb = 13,
    wrong_bomb = 14
}
smiley = {
    smile = 0,
    dead = 1,
    cool = 2,
    smile_pressed = 3
}
tileSize = 16

field = {}     -- what the player sees
fieldReal = {} -- what is under the tiles
revealed = {}
currentLevel = nil
numRows = nil
numCols = nil
numMines = nil
mineCount = 0
time = 0
marks = false
madeFirstClick = false
smileyState = smiley.smile
gameover = false
cursorX = nil
cursorY = nil
---------------------



---- EVENTS ----
function on.construction()
    images = {}
    for img_name, img_resource in pairs(_R.IMG) do
        images[img_name] = image.new(img_resource)

        if img_name:sub(1, 3) == 'num' then
            images[img_name] = images[img_name]:copy(images[img_name]:width(), images[img_name]:height() - 1)
        end
        if img_name:sub(1, 6) == 'smiley' then
            images[img_name] = images[img_name]:copy(images[img_name]:width() - 4, images[img_name]:height() - 4)
        end
    end

    startGame()
end

function on.timer()
    time = time + 1
    if time >= 999 then
        gameOver(false)
    end

    platform.window:invalidate()
end

function on.arrowUp()
    if gameover then return end

    if cursorY - 1 > 0 then
        cursorY = cursorY - 1
        platform.window:invalidate()
    else
        cursorY = numRows
        platform.window:invalidate()
    end
end

function on.arrowDown()
    if gameover then return end

    if cursorY < numRows then
        cursorY = cursorY + 1
        platform.window:invalidate()
    else
        cursorY = 1
        platform.window:invalidate()
    end
end

function on.arrowLeft()
    if gameover then return end

    if cursorX - 1 > 0 then
        cursorX = cursorX - 1
        platform.window:invalidate()
    else
        cursorX = numCols
        platform.window:invalidate()
    end
end

function on.arrowRight()
    if gameover then return end

    if cursorX < numCols then
        cursorX = cursorX + 1
        platform.window:invalidate()
    else
        cursorX = 1
        platform.window:invalidate()
    end
end

function on.charIn(char)
    if gameover then return end

    if char == '-' or char == 'f' then
        flag()
    end
end

function on.enterKey()
    if gameover then return end

    if not madeFirstClick then
        setMines()
        setHints()
        timer.start(1)
        madeFirstClick = true
    end

    if field[cursorY][cursorX] ~= tile.flag then
        field[cursorY][cursorX] = fieldReal[cursorY][cursorX]
        if field[cursorY][cursorX] == tile.bomb then
            set(cursorX,cursorY,tile.clicked_bomb)
            gameOver(false)
        end
        if field[cursorY][cursorX] == tile.nothing then
            revealAllEmpty(cursorX, cursorY)
            platform.window:invalidate()
        end
    end

    if hasWon() and not gameover then
        gameOver(true)
    end

    platform.window:invalidate()
end

function on.backspaceKey()
    if gameover then
        restart()
    end
end

function on.mouseDown(x,y)
    if x > platform.window:width()/2 - images.smiley_smile:width()/2 - 1 and y > 9 and x < platform.window:width()/2 + images.smiley_smile:width()/2 - 1 and y < 9 + images.smiley_smile:height() then
        if smileyState == smiley.smile then
            smileyState = smiley.smile_pressed
            platform.window:invalidate()
        end
    end
end

function on.mouseUp(x,y)
    if smileyState == smiley.smile_pressed then
        smileyState = smiley.smile
        platform.window:invalidate()
        restart()
    end
end

function on.mouseMove(x,y)
    --cursor.show()
    if x > platform.window:width()/2 - images.smiley_smile:width()/2 - 1 and y > 9 and x < platform.window:width()/2 + images.smiley_smile:width()/2 - 1 and y < 9 + images.smiley_smile:height() and smileyState == smiley.smile then
        cursor.set("hand pointer")
    else
        cursor.set("default")
    end
end

function on.arrowKey()
    cursor.hide()
end
----------------



function setMines()
    for x = 1,numMines do
        rx = math.random(numCols)
        ry = math.random(numRows)
        while fieldReal[ry][rx] == tile.bomb
                or (ry   == cursorY and rx   == cursorX)
                or (ry-1 == cursorY and rx+1 == cursorX)
                or (ry   == cursorY and rx+1 == cursorX)
                or (ry+1 == cursorY and rx+1 == cursorX)
                or (ry+1 == cursorY and rx   == cursorX)
                or (ry+1 == cursorY and rx-1 == cursorX)
                or (ry   == cursorY and rx-1 == cursorX)
                or (ry-1 == cursorY and rx-1 == cursorX)
                or (ry-1 == cursorY and rx   == cursorX) do
            rx = math.random(numCols)
            ry = math.random(numRows)
        end

        fieldReal[ry][rx] = tile.bomb
    end
end

function setHints()
    for y,row in pairs(fieldReal) do
        for x,col in pairs(row) do
            if fieldReal[y][x] ~= 9 then
                number = 0

                if y-1 > 0 and fieldReal[y-1][x] == 9 then
                    number = number + 1
                end
                if y-1 > 0 and x+1 <= numCols and fieldReal[y-1][x+1] == 9 then
                    number = number + 1
                end
                if x+1 <= numCols and fieldReal[y][x+1] == 9 then
                    number = number + 1
                end
                if y+1 <= numRows and x+1 <= numCols and fieldReal[y+1][x+1] == 9 then
                    number = number + 1
                end
                if y+1 <= numRows and fieldReal[y+1][x] == 9 then
                    number = number + 1
                end
                if y+1 <= numRows and x-1 > 0 and fieldReal[y+1][x-1] == 9 then
                    number = number + 1
                end
                if x-1 > 0 and fieldReal[y][x-1] == 9 then
                    number = number + 1
                end
                if y-1 > 0 and x-1 > 0 and fieldReal[y-1][x-1] == 9 then
                    number = number + 1
                end

                fieldReal[y][x] = number
            end
        end
    end
end

function flag()
    currTile = field[cursorY][cursorX]

    if currTile == tile.normal then
        if mineCount - 1 > -100 then
            field[cursorY][cursorX] = tile.flag
            mineCount = mineCount - 1
        end
    elseif currTile == tile.flag then
        if marks then
            field[cursorY][cursorX] = tile.marked
            mineCount = mineCount + 1
        else
            field[cursorY][cursorX] = tile.normal
            mineCount = mineCount + 1
        end
    elseif currTile == tile.marked then
        field[cursorY][cursorX] = tile.normal
    end

    platform.window:invalidate()
end

function set(x,y,num)
    field[y][x] = num
    if not isRevealed(x,y) then
        table.insert(revealed, {x,y})
    end
end

function isRevealed(x,y)
    for _,coords in pairs(revealed) do
        if x == coords[1] and y == coords[2] then
            return true
        end
    end
    return false
end

function revealAllEmpty(x,y)
    if not isRevealed(x,y) and x > 0 and y > 0 and x <= numCols and y <= numRows and fieldReal[y][x] <= 8 then
        if field[y][x] == tile.flag then
            mineCount = mineCount + 1
        end

        set(x,y,fieldReal[y][x])

        if fieldReal[y][x] == tile.nothing then
            for nx = -1,1 do
                for ny = -1,1 do
                    if not (nx == 0 and ny == 0) then
                        revealAllEmpty(x+nx,y+ny)
                    end
                end
            end
        end
    end
end

function revealAllMines()
    for y,row in pairs(fieldReal) do
        for x,col in pairs(row) do
            if col == tile.bomb then
                if field[y][x] ~= tile.clicked_bomb then
                    set(x,y,tile.bomb)
                end
            end
            if field[y][x] == tile.flag and fieldReal[y][x] ~= tile.bomb then
                set(x,y,tile.wrong_bomb)
            end
        end
    end
end

function hasWon()
    revealedNum = 0
    for y,row in pairs(field) do
        for x,row in pairs(row) do
            if field[y][x] ~= tile.normal and field[y][x] ~= tile.flag and field[y][x] ~= tile.marked then
                revealedNum = revealedNum + 1
            end
        end
    end

    if revealedNum + numMines == numRows * numCols then
        return true
    end
    return false
end

function startGame()
    if currentLevel == nil then
        currentLevel = defaultLevel
    end

    numRows = levels[currentLevel].rows
    numCols = levels[currentLevel].cols
    numMines = levels[currentLevel].mines
    fieldWidth = numCols * tileSize
    fieldHeight = numRows * tileSize
    mineCount = numMines

    cursorX = math.floor(numCols/2)
    cursorY = math.floor(numRows/2)

    smileyState = smiley.smile
    gameover = false
    madeFirstClick = false
    time = 0
    field = {}
    fieldReal = {}
    revealed = {}

    for y = 1,numRows do
        field[y] = {}
        fieldReal[y] = {}
        for x = 1,numCols do
            field[y][x] = tile.normal
            fieldReal[y][x] = 0
        end
    end
end

function gameOver(win)
    if win then
        gameover = true
        timer.stop()
        smileyState = smiley.cool
        platform.window:invalidate()
    else
        gameover = true
        timer.stop()
        smileyState = smiley.dead
        revealAllMines()
        platform.window:invalidate()
    end
end



---- DRAWING ----
function drawField(gc, x, y)
    dy = y
    for y, row in pairs(field) do
        dx = x
        for x, cell in pairs(row) do
            for tileName,tileNum in pairs(tile) do
                if cell == tileNum then
                    gc:drawImage(images['tile_' .. tileName], dx, dy)
                end
            end

            dx = dx + tileSize
            if x == numCols then
                dy = dy + tileSize
            end
        end
    end
end

function drawNum(gc, num, x, y)
    numStr = tostring(num)
    prefix = ''

    if numStr:sub(1,1) ~= '-' then
        if numStr:len() == 1 then
            prefix = '00'
        end

        if numStr:len() == 2 then
            prefix = '0'
        end

        numStr = prefix .. numStr

        gc:drawImage(images['num'..numStr:sub(1,1)], x, y)
        gc:drawImage(images['num'..numStr:sub(2,2)], x + images.num0:width() - 1, y)
        gc:drawImage(images['num'..numStr:sub(3,3)], x + images.num0:width()*2 - 2, y)
    else
        numStr = numStr:sub(2)

        if numStr:len() == 1 then
            prefix = '0'
        end

        numStr = prefix .. numStr

        gc:drawImage(images.numMinus, x, y)
        gc:drawImage(images['num'..numStr:sub(1,1)], x + images.num0:width() - 1, y)
        gc:drawImage(images['num'..numStr:sub(2,2)], x + images.num0:width()*2 - 2, y)
    end
end

function drawSmiley(gc, x, y)
    for smileyStateName, smileyStateNum in pairs(smiley) do
        if smileyState == smileyStateNum then
            gc:drawImage(images['smiley_' .. smileyStateName], x, y)
        end
    end
end

function drawCursor(gc, fieldX, fieldY)
    x = fieldX + tileSize * (cursorX-1)
    y = fieldY + tileSize * (cursorY-1)


    gc:setPen('medium')
    gc:drawRect(x-1, y-1, tileSize+1, tileSize+1)
end

function on.paint(gc)
    gc:setColorRGB(192, 192, 192)
    gc:fillRect(0, 0, platform.window:width(), platform.window:height())
    gc:setColorRGB(0, 0, 0)
    if currentLevel == 'beginner' then
        fieldX = platform.window:width()/2 - fieldWidth/2
        fieldY = platform.window:height() - fieldHeight - 10

        gc:drawImage(images.border_split_left, fieldX - images.border_corner_top_left:width(), fieldY - images.border_corner_top_left:height())
        gc:drawImage(images.border_split_right, fieldX + numCols * tileSize, fieldY - images.border_corner_top_right:height())
        gc:drawImage(images.border_corner_bottom_left, fieldX - images.border_corner_bottom_left:width(), fieldY + numRows * tileSize)
        gc:drawImage(images.border_corner_bottom_right, fieldX + numCols * tileSize, fieldY + numRows * tileSize)

        gc:drawImage(images.border_vertical, fieldX - images.border_vertical:width(), fieldY)
        gc:drawImage(images.border_vertical, fieldX - images.border_vertical:width(), fieldY + images.border_vertical:height() * 1)
        gc:drawImage(images.border_vertical, fieldX - images.border_vertical:width(), fieldY + images.border_vertical:height() * 2)
        gc:drawImage(images.border_vertical, fieldX - images.border_vertical:width(), fieldY + images.border_vertical:height() * 3)
        gc:drawImage(images.border_vertical, fieldX - images.border_vertical:width(), fieldY + images.border_vertical:height() * 4)

        gc:drawImage(images.border_vertical, fieldX + numCols * tileSize, fieldY)
        gc:drawImage(images.border_vertical, fieldX + numCols * tileSize, fieldY + images.border_vertical:height() * 1)
        gc:drawImage(images.border_vertical, fieldX + numCols * tileSize, fieldY + images.border_vertical:height() * 2)
        gc:drawImage(images.border_vertical, fieldX + numCols * tileSize, fieldY + images.border_vertical:height() * 3)
        gc:drawImage(images.border_vertical, fieldX + numCols * tileSize, fieldY + images.border_vertical:height() * 4)

        gc:drawImage(images.border_horizontal, fieldX, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 1, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 2, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 3, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 4, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 5, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 6, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 7, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 8, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 9, fieldY - images.border_horizontal:height())

        gc:drawImage(images.border_horizontal, fieldX, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 1, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 2, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 3, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 4, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 5, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 6, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 7, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 8, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 9, fieldY + numRows * tileSize)

        drawField(gc, fieldX, fieldY)

        gc:drawImage(images.border_vertical, fieldX - images.border_vertical:width(), 0)
        gc:drawImage(images.border_vertical, fieldX + numCols * tileSize, 0)
        gc:drawImage(images.border_corner_top_left, fieldX - images.border_corner_top_left:width(), 0)
        gc:drawImage(images.border_corner_top_right, fieldX + numCols * tileSize, 0)

        gc:drawImage(images.border_horizontal, fieldX, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 1, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 2, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 3, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 4, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 5, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 6, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 7, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 8, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 9, 0)

        drawNum(gc, mineCount, fieldX - 1, 10 - 1)
        drawNum(gc, time, fieldX + numCols * tileSize - 3 * (images.num0:width() - 1), 10 - 1)
        drawSmiley(gc, platform.window:width()/2 - images.smiley_smile:width()/2 - 1, 10 - 1)

        drawCursor(gc, fieldX, fieldY)
    elseif currentLevel == 'intermediate' then
        fieldX = platform.window:width()/2 - fieldWidth/2
        fieldY = platform.window:height() - fieldHeight - 10

        gc:drawImage(images.border_split_left, fieldX - images.border_corner_top_left:width(), fieldY - images.border_corner_top_left:height())
        gc:drawImage(images.border_split_right, fieldX + numCols * tileSize, fieldY - images.border_corner_top_right:height())
        gc:drawImage(images.border_corner_bottom_left, fieldX - images.border_corner_bottom_left:width(), fieldY + numRows * tileSize)
        gc:drawImage(images.border_corner_bottom_right, fieldX + numCols * tileSize, fieldY + numRows * tileSize)

        gc:drawImage(images.border_vertical, fieldX - images.border_vertical:width(), fieldY)
        gc:drawImage(images.border_vertical, fieldX - images.border_vertical:width(), fieldY + images.border_vertical:height() * 1)
        gc:drawImage(images.border_vertical, fieldX - images.border_vertical:width(), fieldY + images.border_vertical:height() * 2)
        gc:drawImage(images.border_vertical, fieldX - images.border_vertical:width(), fieldY + images.border_vertical:height() * 3)
        gc:drawImage(images.border_vertical, fieldX - images.border_vertical:width(), fieldY + images.border_vertical:height() * 4)

        gc:drawImage(images.border_vertical, fieldX + numCols * tileSize, fieldY)
        gc:drawImage(images.border_vertical, fieldX + numCols * tileSize, fieldY + images.border_vertical:height() * 1)
        gc:drawImage(images.border_vertical, fieldX + numCols * tileSize, fieldY + images.border_vertical:height() * 2)
        gc:drawImage(images.border_vertical, fieldX + numCols * tileSize, fieldY + images.border_vertical:height() * 3)
        gc:drawImage(images.border_vertical, fieldX + numCols * tileSize, fieldY + images.border_vertical:height() * 4)

        gc:drawImage(images.border_horizontal, fieldX, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 1, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 2, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 3, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 4, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 5, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 6, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 7, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 8, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 9, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 10, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 11, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 12, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 13, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 14, fieldY - images.border_horizontal:height())

        gc:drawImage(images.border_horizontal, fieldX, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 1, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 2, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 3, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 4, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 5, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 6, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 7, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 8, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 9, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 10, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 11, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 12, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 13, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 14, fieldY + numRows * tileSize)

        drawField(gc, fieldX, fieldY)

        gc:drawImage(images.border_vertical, fieldX - images.border_vertical:width(), 0)
        gc:drawImage(images.border_vertical, fieldX + numCols * tileSize, 0)
        gc:drawImage(images.border_corner_top_left, fieldX - images.border_corner_top_left:width(), 0)
        gc:drawImage(images.border_corner_top_right, fieldX + numCols * tileSize, 0)

        gc:drawImage(images.border_horizontal, fieldX, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 1, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 2, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 3, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 4, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 5, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 6, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 7, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 8, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 9, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 10, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 11, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 12, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 13, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 14, 0)

        drawNum(gc, mineCount, fieldX - 1, 10 - 1)
        drawNum(gc, time, fieldX + numCols * tileSize - 3 * (images.num0:width() - 1), 10 - 1)
        drawSmiley(gc, platform.window:width()/2 - images.smiley_smile:width()/2 - 1, 10 - 1)

        drawCursor(gc, fieldX, fieldY)
    elseif currentLevel == 'expert' then
        fieldX = platform.window:width()/2 - fieldWidth/2
        fieldY = platform.window:height() - fieldHeight - 10

        gc:drawImage(images.border_split_left, fieldX - images.border_corner_top_left:width(), fieldY - images.border_corner_top_left:height())
        gc:drawImage(images.border_split_right, fieldX + numCols * tileSize, fieldY - images.border_corner_top_right:height())
        gc:drawImage(images.border_corner_bottom_left, fieldX - images.border_corner_bottom_left:width(), fieldY + numRows * tileSize)
        gc:drawImage(images.border_corner_bottom_right, fieldX + numCols * tileSize, fieldY + numRows * tileSize)

        gc:drawImage(images.border_vertical, fieldX - images.border_vertical:width(), fieldY)
        gc:drawImage(images.border_vertical, fieldX - images.border_vertical:width(), fieldY + images.border_vertical:height() * 1)
        gc:drawImage(images.border_vertical, fieldX - images.border_vertical:width(), fieldY + images.border_vertical:height() * 2)
        gc:drawImage(images.border_vertical, fieldX - images.border_vertical:width(), fieldY + images.border_vertical:height() * 3)
        gc:drawImage(images.border_vertical, fieldX - images.border_vertical:width(), fieldY + images.border_vertical:height() * 4)

        gc:drawImage(images.border_vertical, fieldX + numCols * tileSize, fieldY)
        gc:drawImage(images.border_vertical, fieldX + numCols * tileSize, fieldY + images.border_vertical:height() * 1)
        gc:drawImage(images.border_vertical, fieldX + numCols * tileSize, fieldY + images.border_vertical:height() * 2)
        gc:drawImage(images.border_vertical, fieldX + numCols * tileSize, fieldY + images.border_vertical:height() * 3)
        gc:drawImage(images.border_vertical, fieldX + numCols * tileSize, fieldY + images.border_vertical:height() * 4)

        gc:drawImage(images.border_horizontal, fieldX, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 1, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 2, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 3, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 4, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 5, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 6, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 7, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 8, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 9, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 10, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 11, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 12, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 13, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 14, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 15, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 16, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 17, fieldY - images.border_horizontal:height())

        gc:drawImage(images.border_horizontal, fieldX, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 1, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 2, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 3, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 4, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 5, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 6, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 7, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 8, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 9, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 10, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 11, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 12, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 13, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 14, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 15, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 16, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 17, fieldY + numRows * tileSize)

        drawField(gc, fieldX, fieldY)

        gc:drawImage(images.border_vertical, fieldX - images.border_vertical:width(), 0)
        gc:drawImage(images.border_vertical, fieldX + numCols * tileSize, 0)
        gc:drawImage(images.border_corner_top_left, fieldX - images.border_corner_top_left:width(), 0)
        gc:drawImage(images.border_corner_top_right, fieldX + numCols * tileSize, 0)

        gc:drawImage(images.border_horizontal, fieldX, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 1, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 2, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 3, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 4, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 5, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 6, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 7, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 8, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 9, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 10, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 11, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 12, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 13, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 14, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 15, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 16, 0)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * 17, 0)

        drawNum(gc, mineCount, fieldX - 1, 10 - 1)
        drawNum(gc, time, fieldX + numCols * tileSize - 3 * (images.num0:width() - 1), 10 - 1)
        drawSmiley(gc, platform.window:width()/2 - images.smiley_smile:width()/2 - 1, 10 - 1)

        drawCursor(gc, fieldX, fieldY)
    end
end
-----------------



---- TOOL PALETTE ----
function setLevel(_, level)
    currentLevel = level:lower()
    startGame()
    platform.window:invalidate()
end

function restart()
    timer.stop()
    startGame()
    platform.window:invalidate()
end

function toggleMarks(_, toggle)
    if toggle == "Enable" then
        marks = true
        toolpalette.enable("Marks", "Enable", false)
        toolpalette.enable("Marks", "Disable", true)
    elseif toggle == "Disable" then
        marks = false
        toolpalette.enable("Marks", "Enable", true)
        toolpalette.enable("Marks", "Disable", false)

        for y,row in pairs(field) do
            for x,col in pairs(row) do
                if col == tile.marked then
                    field[y][x] = tile.normal
                end
            end
        end
        platform.window:invalidate()
    end
end

menu = {
    {"Level",
        {"Restart", restart},
        "-",
        {"Beginner", setLevel},
        {"Intermediate", setLevel},
        {"Expert", setLevel}
    },
    {"Marks",
        {"Enable", toggleMarks},
        {"Disable", toggleMarks}
    }
}

toolpalette.register(menu)
toolpalette.enable("Marks", "Disable", false)
----------------------





