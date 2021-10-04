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


----------------
---- EVENTS ----
----------------
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

function goUp()
    if gameover then return end

    if cursorY - 1 > 0 then
        cursorY = cursorY - 1
        platform.window:invalidate()
    else
        cursorY = numRows
        platform.window:invalidate()
    end
end

function goDown()
    if gameover then return end

    if cursorY < numRows then
        cursorY = cursorY + 1
        platform.window:invalidate()
    else
        cursorY = 1
        platform.window:invalidate()
    end
end

function goLeft()
    if gameover then return end

    if cursorX - 1 > 0 then
        cursorX = cursorX - 1
        platform.window:invalidate()
    else
        cursorX = numCols
        platform.window:invalidate()
    end
end

function goRight()
    if gameover then return end

    if cursorX < numCols then
        cursorX = cursorX + 1
        platform.window:invalidate()
    else
        cursorX = 1
        platform.window:invalidate()
    end
end

function on.arrowUp() goUp() end
function on.arrowDown() goDown() end
function on.arrowLeft() goLeft() end
function on.arrowRight() goRight() end

function on.charIn(char)
    if gameover then return end
    
    if char == '−' or char == 'f' then flag() return end
    if char == '8' then goUp() return end
    if char == '2' then goDown() return end
    if char == '4' then goLeft() return end
    if char == '6' then goRight() return end

    if char == '7' then goUp() goLeft() return end
    if char == '9' then goUp() goRight() return end
    if char == '1' then goDown() goLeft() return end
    if char == '3' then goDown() goRight() return end
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
----------------


-------------------
---- FUNCTIONS ----
-------------------
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

function isTileInGrid(x, y)
    return y > 0 and y <=numRows and x <= numCols and x > 0
end

function countMines(y, x)
    number = 0
    for x1 = -1, 1 do
        for y1 = -1, 1 do
            if (not (x1 == 0 and y1 == 0)) and isTileInGrid(x+x1, y+y1) then
                if fieldReal[y+y1][x+x1] == 9 then
                    number = number + 1
                end
            end
        end
    end
    return number
end

function setHints()
    for y,row in pairs(fieldReal) do
        for x,col in pairs(row) do
            if fieldReal[y][x] ~= 9 then
                fieldReal[y][x] = countMines(y, x)
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
        else
            field[cursorY][cursorX] = tile.normal
        end
        mineCount = mineCount + 1
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

function revealAllMines(defaultToFlag)
    for y,row in pairs(fieldReal) do
        for x,col in pairs(row) do
            if col == tile.bomb then
                if field[y][x] ~= tile.clicked_bomb and field[y][x] ~= tile.flag then
                    if defaultToFlag then
                        set(x,y,tile.flag)
                    else
                        set(x,y,tile.bomb)
                    end
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
    return revealedNum + numMines == numRows * numCols
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

function getHighscores()
    local hi_beginner = nil

    if not var.recall("hi_beginner") then
        hi_beginner = -1
        var.store("hi_beginner", hi_beginner)
    else
        hi_beginner = var.recall("hi_beginner")
    end
    
    
    local hi_intermediate = nil
    
    if not var.recall("hi_intermediate") then
        hi_intermediate = -1
        var.store("hi_intermediate", hi_intermediate)
    else
        hi_intermediate = var.recall("hi_intermediate")
    end
    
    
    local hi_expert = nil
    
    if not var.recall("hi_expert") then
        hi_expert = -1
        var.store("hi_expert", hi_expert)
    else
        hi_expert = var.recall("hi_expert")
    end
    
    return hi_beginner, hi_intermediate, hi_expert
end

function checkHighscore()
    local hi_beginner, hi_intermediate, hi_expert = getHighscores()
    
    if currentLevel == 'beginner' then
        if hi_beginner == -1 or time < hi_beginner then
            var.store("hi_beginner", time)
        end
    elseif currentLevel == 'intermediate' then
        if hi_intermediate == -1 or time < hi_intermediate then
            var.store("hi_intermediate", time)
        end
    elseif currentLevel == 'expert' then
        if hi_expert == -1 or time < hi_expert then
            var.store("hi_expert", time)
        end
    end
    
    reloadMenu()
end

function gameOver(win)
    gameover = true
    timer.stop()
    if win then
        smileyState = smiley.cool
        checkHighscore()
        revealAllMines(true)
    else
        smileyState = smiley.dead
        revealAllMines(false)
    end
    platform.window:invalidate()
end
-------------------
-------------------


-----------------
---- DRAWING ----
-----------------
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
    if numStr:sub(1,1) == '-' then
        numStr = numStr:sub(2)
        if numStr:len() == 1 then
            numStr = '0'..numStr
        end
        
        gc:drawImage(images.numMinus, x, y)
        gc:drawImage(images['num'..numStr:sub(1,1)], x + images.num0:width() - 1, y)
        gc:drawImage(images['num'..numStr:sub(2,2)], x + images.num0:width()*2 - 2, y)
    else
        numStr = '00'..numStr
        numStr = numStr:sub(numStr:len()-2,numStr:len());
        
        gc:drawImage(images['num'..numStr:sub(1,1)], x, y)
        gc:drawImage(images['num'..numStr:sub(2,2)], x + images.num0:width() - 1, y)
        gc:drawImage(images['num'..numStr:sub(3,3)], x + images.num0:width()*2 - 2, y)
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

    fieldX = platform.window:width()/2 - fieldWidth/2
    fieldY = platform.window:height() - fieldHeight - 10

    gc:drawImage(images.border_split_left,          fieldX - images.border_corner_top_left:width(),         fieldY - images.border_corner_top_left:height())
    gc:drawImage(images.border_split_right,         fieldX + numCols * tileSize,                            fieldY - images.border_corner_top_right:height())
    gc:drawImage(images.border_corner_bottom_left,  fieldX - images.border_corner_bottom_left:width(),      fieldY + numRows * tileSize)
    gc:drawImage(images.border_corner_bottom_right, fieldX + numCols * tileSize,                            fieldY + numRows * tileSize)

    for i = 0, 4 do
        gc:drawImage(images.border_vertical, fieldX - images.border_vertical:width(),   fieldY + images.border_vertical:height() * i)
        gc:drawImage(images.border_vertical, fieldX + numCols * tileSize,               fieldY + images.border_vertical:height() * i)
    end
    
    for i = 0, numCols-1 do
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * i, fieldY - images.border_horizontal:height())
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * i, fieldY + numRows * tileSize)
        gc:drawImage(images.border_horizontal, fieldX + images.border_horizontal:width() * i, 0)
    end

    drawField(gc, fieldX, fieldY)

    gc:drawImage(images.border_vertical,            fieldX - images.border_vertical:width(),        0)
    gc:drawImage(images.border_vertical,            fieldX + numCols * tileSize,                    0)
    gc:drawImage(images.border_corner_top_left,     fieldX - images.border_corner_top_left:width(), 0)
    gc:drawImage(images.border_corner_top_right,    fieldX + numCols * tileSize,                    0)

    drawNum(gc,     mineCount,  fieldX - 1,                                                     10 - 1)
    drawNum(gc,     time,       fieldX + numCols * tileSize - 3 * (images.num0:width() - 1),    10 - 1)
    drawSmiley(gc,  platform.window:width()/2 - images.smiley_smile:width()/2 - 1,              10 - 1)

    drawCursor(gc, fieldX, fieldY)
end
-----------------
-----------------



----------------------
---- TOOL PALETTE ----
----------------------
function setLevel(_, level)
    timer.stop()
    currentLevel = level:lower()
    startGame()
    platform.window:invalidate()
end

function getHighscoreStrings()
    local hi_beginner, hi_intermediate, hi_expert = getHighscores()
    
    local hi_beginner_str, hi_intermediate_str, hi_expert_str
    
    if hi_beginner == -1 then
        hi_beginner_str = "None"
    else
        hi_beginner_str = hi_beginner .. " sec"
    end
    
    if hi_intermediate == -1 then
        hi_intermediate_str = "None"
    else
        hi_intermediate_str = hi_intermediate .. " sec"
    end
        
    if hi_expert == -1 then
        hi_expert_str = "None"
    else
        hi_expert_str = hi_expert .. " sec"
    end
    
    return hi_beginner_str, hi_intermediate_str, hi_expert_str
end

function restart()
    timer.stop()
    startGame()
    platform.window:invalidate()
end

function toggleMarks(_, toggle)
    marks = toggle == "Enable"
    toolpalette.enable("Marks", "Enable", not marks)
    toolpalette.enable("Marks", "Disable", marks)

    if toggle == "Disable" then
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

function reloadMenu()
    hi_beginner_str, hi_intermediate_str, hi_expert_str = getHighscoreStrings()
    
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
        },
        {"Highscores",
            {"Beginner - " .. hi_beginner_str, function() end},
            {"Intermediate - " .. hi_intermediate_str, function() end},
            {"Expert - " .. hi_expert_str, function() end}
        }
    }
    
    toolpalette.register(menu)
    
    if marks then
        toolpalette.enable("Marks", "Enable", false)
    else
        toolpalette.enable("Marks", "Disable", false)
    end
end

reloadMenu()

----------------------
----------------------
