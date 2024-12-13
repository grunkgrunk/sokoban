-- Libraries
local inspect = require 'lib.inspect'

function pp(...)
  print(inspect(...))
end

local vector = require 'lib.vector'

local lume = require 'lib.lume'
local levels = require 'assets.levels'

palette = require 'assets.palette'

flux = require 'lib.flux'
Timer = require 'lib.timer'

Gamestate = require 'lib.gamestate'

states = {
  game = require 'game',
  menu = require 'menu',
  start = require 'start'
}

colors = {}
colors.index = 1
for i, v in ipairs(palette[colors.index]) do
  colors[i] = lume.clone(v)
end

width, height = love.graphics.getDimensions()

function drawLevel(level, x, y, scale)
  love.graphics.push()
  love.graphics.translate(x - scale * level.width / 2 - scale, y - scale * level.height / 2 - scale)

  lume.each(level.ents, function(o)
    love.graphics.setColor(colors[o.color])
    local side = scale * o.shownscale

    love.graphics.rectangle('fill',
      o.shownpos.x * scale + scale / 2 - side / 2,
      o.shownpos.y * scale + scale / 2 - side / 2, side, side)
  end)

  love.graphics.pop()
end

function loadlevel(lvl)
  local boxes = {}
  local endpoints = {}
  local player = {}
  local ents = {}

  local level = levels[lvl]

  for y, str in ipairs(level) do
    for x = 1, #str do
      local char = str:sub(x, x)

      local function create(type)
        local o = {
          shownpos = vector(x, y),
          pos = vector(x, y),
          originalpos = vector(x, y),
          type = type,
          scale = 1,
          shownscale = 1
        }

        local entprops = {
          wall     = { z = 1, color = 6 },
          player   = { z = 2, color = 4, shownscale = 0.7, scale = 0.7 },
          box      = { z = 2, color = 9, shownscale = 0.7, scale = 0.7 },
          endpoint = { z = 1, color = 5 },
        }

        o = lume.merge(o, entprops[type])

        ents[#ents + 1] = o

        return o
      end

      if char ~= ' ' then
        if char == 'X' then
          create('wall')
        elseif char == '@' then
          player = create('player')
        elseif char == '*' then
          boxes[#boxes + 1] = create('box')
        elseif char == '.' then
          endpoints[#endpoints + 1] = create('endpoint')
        elseif char == '&' then
          endpoints[#endpoints + 1] = create('endpoint')
          local box = create('box')
          flux.to(box, 0.1, { shownscale = box.scale * 0.5 }):delay(0.5)
          boxes[#boxes + 1] = box
        end
      end
    end
  end

  local width = lume.reduce(level, function(prev, curr)
    if #curr > prev then
      return #curr
    end
    return prev
  end, #level[1])

  local height = #level

  return {
    width = width,
    height = height,

    boxes = boxes,
    endpoints = endpoints,
    player = player,
    ents = ents,
  }
end

loadedlevels = {}
for i = 1, #levels do
  loadedlevels[i] = loadlevel(i)
end

function printfshadow(txt, x, y, w, align, opacity)
  local c = lume.clone(colors[9])
  c[4] = opacity
  x, y, w = math.floor(x), math.floor(y), math.floor(w)
  love.graphics.setColor(c)
  love.graphics.printf(txt, x + 2, y + 2, w, align)
  love.graphics.setColor(1, 1, 1, opacity)
  love.graphics.printf(txt, x, y, w, align)
end

function love.load()
  math.randomseed(os.time())
  love.mouse.setVisible(false)
  local f = lume.fn(love.graphics.newFont, 'assets/thin.ttf')
  font = {
    small = f(16),
    medium = f(32),
    large = f(64),
  }

  completedlevels = (function()
    if love.filesystem.getInfo('savedata.lua') then
      return love.filesystem.load('savedata.lua')()
    end
    return {}
  end)()


  Gamestate.registerEvents()
  Gamestate.switch(states.start)
end

function love.update(dt)
  flux.update(dt)
  Timer.update(dt)
end
