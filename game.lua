local vector = require 'lib.vector'
local lume = require 'lib.lume'
local serialize = require 'lib.ser'

local game = {}

local keys = {
  up = {curr = false, prev = false},
  down = {curr = false, prev = false},
  left = {curr = false, prev = false},
  right = {curr = false, prev = false},
}

local animspeed = 0.1
local betweenmoves = 0.2
local movetimer = betweenmoves
local level = nil
local resetting = false
local tomenu = false
local textopacity = {0}

local stats = {
  moves = 0,
  time = 0,
  pushes = 0,
  lvl = 0
}

local dir = 'up'

local function reset(lvl)
  resetting = false
  stats = {
    moves = 0,
    time = 0,
    pushes = 0,
    lvl = lvl
  }

  level = loadlevel(lvl)
  level.ents = lume.sort(level.ents, 'z')
  flux.to(textopacity, 0.5, {255})
end

function game:init()
end

function game:enter(prev, lvl)
  tomenu = false
  local textopacity = {0}
  reset(lvl)
  for i,v in ipairs(level.ents) do
    v.shownscale = 0
    v.shownpos = vector(level.width/2, level.height/2)
    flux.to(v.shownpos, math.random()/2 + 0.2, v.pos):ease('quadinout')
    flux.to(v, math.random() + 0.4, {shownscale = v.scale})
  end
end

function game:draw()
  love.graphics.clear(colors[1])

  local dim = width/level.width
  if height/level.height < dim then
    dim = height/level.height
  end
  drawLevel(level, width/2, height/2, dim * 0.8)

  love.graphics.setColor(255, 255, 255, textopacity[1])
  love.graphics.setFont(font.medium)
  local msg = "Level " .. tostring(stats.lvl)
  local margin = 20

  love.graphics.printf(msg, margin,margin, width, 'left')

  local y = height-font.medium:getHeight('A')-margin

  msg = "Moves: " .. tostring(math.floor(stats.moves))
  love.graphics.printf(msg, margin,y, width, 'left')

  msg = "Pushes: " .. tostring(math.floor(stats.pushes))
  love.graphics.printf(msg, margin,y, width, 'center')

  msg = "Time: " .. tostring(math.floor(stats.time))
  love.graphics.printf(msg, -margin,y, width, 'right')
end

function game:update(dt)
  if resetting then return end

  stats.time = stats.time + dt

  for k,v in pairs(keys) do
    v.prev = v.curr
    if love.keyboard.isDown(k) then
      if v.prev == false then
        dir = k
      end
      v.curr = true
    else
      v.curr = false
    end
  end

  if keys[dir].curr then
    movetimer = movetimer - dt
    if movetimer <= 0 or not keys[dir].prev then
      movetimer = betweenmoves

      local movement = vector()
      if dir == 'left' then
        movement.x = -1
      end
      if dir == 'right' then
        movement.x = 1
      end
      if dir == 'up' then
        movement.y = -1
      end
      if dir == 'down' then
        movement.y = 1
      end

      local pos = level.player.pos + movement

      function overlaps(pos, t, disregard)
        for i,v in ipairs(t) do
          if pos ~= v and v.type ~= disregard then
            if pos:equals(v.pos) then return v end
          end
        end
        return false
      end

      local playercol = overlaps(pos, level.ents, 'endpoint')
      if playercol then
        if playercol.type == 'wall' then return end

        if playercol.type == 'box' then
          local bpos = pos + movement
          local boxcol = overlaps(bpos, level.ents, 'endpoint')

          if boxcol then
            if boxcol.type == 'wall' or boxcol.type == 'box' then return end
          end

          stats.pushes = stats.pushes + 1
          playercol.pos = bpos
          flux.to(playercol.shownpos, animspeed, bpos)
          flux.to(playercol, animspeed, {shownscale = playercol.scale*1.2})
          :after(animspeed, {shownscale = playercol.scale})
        end
      end

      stats.moves = stats.moves + 1
      level.player.pos = pos
      flux.to(level.player.shownpos, animspeed, pos)
      flux.to(level.player, animspeed, {shownscale = level.player.scale*0.8})
      :after(animspeed, {shownscale = level.player.scale})


      for i,v in ipairs(level.boxes) do
        if not overlaps(v.pos, level.endpoints) then return end
      end


      completedlevels[stats.lvl] = {
        pushes = stats.pushes,
        time   = stats.time,
        moves  = stats.moves
      }

      -- save here
      local seri = serialize(completedlevels)
      local success = love.filesystem.write('savedata.lua', seri)

      colors.index = colors.index + 1

      if colors.index > #palette then colors.index = 1 end

      local pal = lume.clone(palette[colors.index])

      for i,color in ipairs(colors) do
        flux.to(color, 1, pal[i])
      end

      stats.lvl = stats.lvl + 1
      reset(stats.lvl)
    end
  end
end

function game:keypressed(key)
  if key == 'r' and not resetting then
    resetting = true
    for i,v in ipairs(level.ents) do
      local target = v.originalpos-v.pos
      flux.to(v.shownpos, math.random()/3 + 0.1, v.pos + target*0.7 + vector.randomDirection() * 10)
      :after(math.random()/3 + 0.1, v.originalpos)

      flux.to(v, math.random()/3 + 0.1, {shownscale = v.scale/5})
      :after(math.random()/3 + 0.1, {shownscale = v.scale})
    end
    flux.to(textopacity, 0.5, {0})
    flux.to(stats, 0.8, {moves = 0, pushes = 0, time = 0}):oncomplete(function() reset(stats.lvl) end)
  end

  if key == 'escape' and not tomenu then
    for i,v in ipairs(level.ents) do
      tomenu = true
      --v.shownpos = vector(level.width/2, level.height/2)
      --flux.to(v.shownpos, math.random()/2 + 0.2, v.pos):ease('quadinout')
      local time = math.random()/3 + 0.2
      local away = v.pos - vector(level.width/2, level.height/2)
      flux.to(v.shownpos, time, v.shownpos + away * 4/away:len()
      * (1 + math.random()/2))
      :ease('quadinout')
      flux.to(v, time, {shownscale = 0})
    end
    flux.to(textopacity, 0.5, {0})
    Timer.after(0.5, function() Gamestate.switch(states.menu) end)
  end

  if key == 'x' then
    colors.index = colors.index + 1

    if colors.index > #palette then colors.index = 1 end
    print(colors.index)
    local newcolors = lume.clone(palette[colors.index])

    for i,color in ipairs(colors) do
      flux.to(color, 0.5,newcolors[i])
    end
  end
end

return game
