function love.load()
    debug = true

    -- Preload assets
    playerSheet = love.graphics.newImage("spr/player.png")
    playerSheet:setFilter("nearest", "nearest")

    song = love.audio.newSource("mus/menu.ogg", "static")
    song:setVolume(0.5)
    song:setLooping(true)
    -- song:play()
    -- Audio is broken on Wii U
    
    -- --- DIMENSIONS ---
    player = {
        x = 400,
        y = 240,
        -- Sub-pixel variables to prevent the player getting sent to the edge of the universe
        subX = 0,
        subY = 0,
        speed = 100,
        runningSpeed = 250
    }
    
    local frameW = 19   -- Kris width
    local frameH = 38   -- Kris height
    local gapX   = 5    -- Horizontal border
    local gapY   = 6    -- Vertical border
    local margin = 0   

    -- 2. Create Quads
    animations       = {}
    animations.down  = {}
    animations.left  = {}
    animations.right = {}
    animations.up    = {}

    local sw, sh = playerSheet:getDimensions()

    for col = 1, 4 do
        local x = margin + (col - 1) * (frameW + gapX)
        table.insert(animations.down,  love.graphics.newQuad(x, margin + 0*(frameH+gapY), frameW, frameH, sw, sh))
        table.insert(animations.left,  love.graphics.newQuad(x, margin + 1*(frameH+gapY), frameW, frameH, sw, sh))
        table.insert(animations.right, love.graphics.newQuad(x, margin + 2*(frameH+gapY), frameW, frameH, sw, sh))
        table.insert(animations.up,    love.graphics.newQuad(x, margin + 3*(frameH+gapY), frameW, frameH, sw, sh))
    end

    -- 3. Animation State
    currentDir = "down"
    currentFrame = 1
    animTimer = 0
    isMoving = false
    
    pWidth = frameW
    pHeight = frameH
end

function love.update(dt)
    -- Setup variables
    local dx, dy = 0, 0
    local isRunning = false
    local joysticks = love.joystick.getJoysticks()

    -- Process inputs
    for i, joystick in ipairs(joysticks) do
        if joystick:isGamepadDown("dpleft")  then dx = dx - 1 end
        if joystick:isGamepadDown("dpright") then dx = dx + 1 end
        if joystick:isGamepadDown("dpup")    then dy = dy - 1 end
        if joystick:isGamepadDown("dpdown")  then dy = dy + 1 end

        if joystick:isGamepadDown("b") then isRunning = true end
    end

    -- Normalizization
    if dx > 0 then dx = 1 elseif dx < 0 then dx = -1 end
    if dy > 0 then dy = 1 elseif dy < 0 then dy = -1 end

    isMoving = false
    local moveX, moveY = 0, 0

    if dx ~= 0 or dy ~= 0 then
        isMoving = true
        
        -- Prioritize up/down over left/right
        if dy ~= 0 then
            currentDir = dy > 0 and "down" or "up"
        else
            currentDir = dx > 0 and "right" or "left"
        end

        -- Correct diagonal speed
        if dx ~= 0 and dy ~= 0 then
            moveX = dx * 0.7071
            moveY = dy * 0.7071
        else
            moveX = dx
            moveY = dy
        end

        -- Apply movement
        local speed = isRunning and player.runningSpeed or player.speed
        
        player.subX = player.subX + (moveX * speed * dt)
        player.subY = player.subY + (moveY * speed * dt)

        -- Fix for the bug where left/up moves slower than right/down
        local intX, fracX = math.modf(player.subX)
        local intY, fracY = math.modf(player.subY)

        local nextX = player.x + intX
        local nextY = player.y + intY

        -- Prevent NaN coords
        if nextX == nextX and nextY == nextY then
            player.x = nextX
            player.y = nextY
            player.subX = fracX
            player.subY = fracY
        else
            player.subX, player.subY = 0, 0
        end
    end

    -- Animation logic
    if isMoving then
        animTimer = animTimer + dt
        local limit = isRunning and 0.15 or 0.25 
        if animTimer > limit then 
            currentFrame = (currentFrame % 4) + 1
            animTimer = 0
        end
    else
        currentFrame = 1
        animTimer = 0
    end
end

-- Touch to move player for debug
function love.touchpressed(id, x, y, dx, dy, pressure)
    player.x = x
    player.y = y
    player.subX = 0
    player.subY = 0
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    player.x = x
    player.y = y
    player.subX = 0
    player.subY = 0
end

function love.draw()
    local quad = animations[currentDir][currentFrame]
    
    -- Draw Kris at whole pixel coordinates
    local drawX = math.floor(player.x)
    local drawY = math.floor(player.y)

    local scale = 2 

    love.graphics.draw(
        playerSheet, 
        quad, 
        drawX, 
        drawY, 
        0, 
        scale, scale, 
        pWidth / 2, 
        pHeight / 2
    )

    -- Debug info
    if debug then love.graphics.printf("FPS: "  .. love.timer.getFPS() .. "\nX: " .. player.x .. " Y: " .. player.y, 10, 10, 300) end
end