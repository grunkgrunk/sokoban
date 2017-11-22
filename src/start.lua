local lume = require 'lib.lume'
local vector = require 'lib.vector'

local start = {}

local textopacity = {0}

local tiles = {}

local startgame = false

local function movearound(o)
  if startgame then return end
  local time = math.random() * 2 + 0.4
  o.tweenscale = flux.to(o, time/2, {shownscale = 1.3})
  o.tweenpos   = flux.to(o.shownpos, time, o.originalpos + vector.randomDirection(1,3))
  :onstart(function() o.ready = false end)
  :oncomplete(function() o.ready = true end)
end

function start:update(dt)
  for k,o in ipairs(tiles.ents) do
    if o.ready then movearound(o) end
  end
end

function start:enter()
  startgame = false
  flux.to(textopacity, 0.5, {255}):delay(0.5)

  -- generate a bunch of random tiles to play around with
  tiles = {ents = {}, width = 1, height = 1}
  local colori = {6,4,9,5}
  for i = 1, 2000 do
    local pos = vector.randomDirection(35, 200)
    local o = {
      shownpos = pos,
      originalpos = pos:clone(),
      color = lume.randomchoice(colori),
      shownscale = 0,
    }

    flux.to(o, math.random()*3 + 0.5, {shownscale = 1})
    :oncomplete(function() movearound(o) end)

    tiles.ents[i] = o
  end
end

function start:draw()
  love.graphics.clear(colors[1])

  drawLevel(tiles, width/2, height/2, 10)

  love.graphics.setColor(255, 255, 255, textopacity[1])
  love.graphics.setFont(font.large)
  local y = height/2-font.large:getHeight('S')/2 - 70
  printfshadow('Sokoban', 0,y, width, 'center', textopacity[1])
  love.graphics.setFont(font.medium)

  printfshadow('By grunkgrunk', 0,y + 70, width, 'center', textopacity[1])

  printfshadow("Controls", 0,y+140, width, 'center', textopacity[1])

  love.graphics.setFont(font.small)
  printfshadow("Space and arrow keys.\nEscape to go back or quit.", 0,y+180, width, 'center', textopacity[1])
end

function start:keypressed(key)
  if key == 'space' and not startgame then
    startgame = true
    flux.to(textopacity, 0.5, {0}):delay(0.5)
    for k,o in ipairs(tiles.ents) do
      if o.tweenpos then
        o.tweenpos:stop()
      end
      if o.tweenscale then
        o.tweenscale:stop()
      end

      local away = o.shownpos - vector(tiles.width/2, tiles.height/2)
      local time = math.random() + 1
      flux.to(o.shownpos, time, o.shownpos + vector.randomDirection(1, 100))
      flux.to(o, time, {shownscale = 0})
    end

    Timer.after(2.1, function() Gamestate.switch(states.menu) end)
  end

  if key == 'escape' then
    love.event.quit()
  end
end

return start
