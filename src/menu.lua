local levels      = require 'assets.levels'
local vector      = require 'lib.vector'
local lume        = require 'lib.lume'

local menu        = {}

local currlevel   = 1
local timepassed  = 0

local scale       = 20

local displaying  = {}

local textopacity = { 0 }
local message

-- how many levels we want to display on each side of the middle level
local minmax      = 5

local function reset(dir)
  currlevel = (currlevel - 1) % #levels + 1
  for i = -minmax, minmax do
    displaying[i] = loadlevel((currlevel + i - 1) % #levels + 1)
  end

  local to = vector(scale * 1.5, 0)

  -- explode
  if not dir then
    for i = -minmax, minmax do
      local level = displaying[i]
      local offset = to * i
      for j, v in ipairs(level.ents) do
        v.shownscale = 0
        v.shownpos = v.pos + vector.randomDirection(100)
        local time = math.random() + 0.5
        local target = v.pos + offset * -1
        flux.to(v.shownpos, time, target)
        flux.to(v, time, { shownscale = v.scale * 1 / (math.abs(i) + 1) })
      end
    end
    return
  end

  for i = -minmax, minmax do
    local level = displaying[i]
    local offset = to * i

    for j, v in ipairs(level.ents) do
      local target = v.pos + offset
      v.shownpos = target + to * dir * -1
      flux.to(v, 0.2, { shownscale = v.shownscale / 2 })
          :after(v, 0.2, { shownscale = v.shownscale * 1 / (math.abs(i) + 1) })
      flux.to(v.shownpos, 0.2, target)
    end
  end
end

function menu:enter(prev, msg)
  haschosenlvl = false
  reset()
  textopacity = { 0 }
  flux.to(textopacity, 1, { 1 })
  message = msg
end

function menu:draw()
  local margin = 20
  love.graphics.clear(colors[1])

  for i = -minmax, minmax do
    drawLevel(displaying[i], width / 2, height / 2, scale + math.abs(math.sin(timepassed * 2)))
  end

  love.graphics.setFont(font.large)
  printfshadow("Level " .. tostring(currlevel), 0, 50, width, 'center', textopacity[1])

  love.graphics.setFont(font.medium)
  local y = height - font.medium:getHeight('A') - margin

  -- if we can display some information about how the player did on last play-through
  if completedlevels[currlevel] then
    local completed = completedlevels[currlevel]
    msg = "Moves: " .. tostring(math.floor(completed.moves))
    printfshadow(msg, margin + width / 10, y, width, 'left', textopacity[1])

    msg = "Pushes: " .. tostring(math.floor(completed.pushes))
    printfshadow(msg, margin, y, width, 'center', textopacity[1])

    msg = "Time: " .. tostring(math.floor(completed.time))
    printfshadow(msg, -margin - width / 10, y, width, 'right', textopacity[1])
  else
    printfshadow('Not completed.', -margin, y, width, 'center', textopacity[1])
  end

  if message then
    love.graphics.setFont(font.large)
    local y = math.floor(height / 2 - font.large:getHeight('L') / 2)
    printfshadow(message.txt, 0, y, width, 'center', message.opacity)
  end
end

function menu:update(dt)
  timepassed = timepassed + dt
end

function menu:keypressed(key)
  if message and
      (key == 'left' or key == 'right' or key == 'space' or key == 'escape') then
    flux.to(message, 0.2, { opacity = 0 })
  end

  if key == 'left' then
    currlevel = currlevel - 1
    reset(1)
  end

  if key == 'right' then
    currlevel = currlevel + 1
    reset(-1)
  end

  if key == 'space' and not haschosenlvl then
    haschosenlvl = true
    for i = -minmax, minmax do
      local level = displaying[i]
      if i == 0 then
        for i, v in ipairs(level.ents) do
          local time = math.random() / 2 + 0.1
          flux.to(v, time * 1.3, { shownscale = 0 })
          flux.to(v.shownpos, time / 2, v.shownpos + vector.randomDirection() * 10)
              :after(v.shownpos, time / 2, vector(level.width / 2, level.height / 2))
        end
      else
        for i, v in ipairs(level.ents) do
          local time = math.random() / 2 + 0.1
          flux.to(v, time * 0.6, { shownscale = v.scale * math.random() })
              :after(time * 0.4, { shownscale = 0 })

          flux.to(v.shownpos, time / 2, v.shownpos + vector.randomDirection() * 2)
        end
      end
    end

    flux.to(textopacity, 0.5, { 0 })
    Timer.after(0.6, function() Gamestate.switch(states.game, currlevel) end)
  end

  if key == 'escape' then
    for i = -2, 2 do
      local level = displaying[i]
      for i, v in ipairs(level.ents) do
        local time = math.random() / 2 + 0.1
        flux.to(v, time * 1.3, { shownscale = 0 })
      end
    end
    flux.to(textopacity, 0.5, { 0 })
    Timer.after(0.6, function() Gamestate.switch(states.start, currlevel) end)
  end
end

return menu
