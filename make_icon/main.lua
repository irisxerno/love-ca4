-- utils
function RGB(r,g,b)
  if type(r)=="table" then
    r,g,b = unpack(r)
  end
  return r/255,g/255,b/255
end

function clamp(i,min,max)
  return math.max(math.min(i,max),min)
end



font = love.graphics.newFont("SourceCodePro-Bold.ttf",34)
love.graphics.setFont(font)

-- "assets"
a = {}
a.sym = {"β","δ","λ","φ"}
a.symc = {9,10,12,13}
a.num = {"1","2","3","4","5","6","7","8","9","x","J","Q","K"}

-- color
color = {}
color.table = require "color"

function color:get(i,a)
  local r,g,b
  if a then
    r,g,b = RGB(self.table[i])
    return r,g,b,a
  else
    return RGB(self.table[i])
  end
end

function color:set(i,a)
  if type(a)=="boolean" and a then
    love.graphics.setBackgroundColor(self:get(i))
  else
    love.graphics.setColor(self:get(i,a))
  end
end

debug = {string = "",show = true}
function debug:set(s)
  debug.string = inspect(s).."\n"
  print(inspect(s))
end
function debug:add(s)
  debug.string = debug.string .. inspect(s) .. "\n"
  print(inspect(s))
end


-- shapes
shapes = {}
function shapes.triangle(x,y,w,h,ss)
  if ss == -1 then
    do return end
  end
  local p1 = { x,y+h, x+w,y+h, x+w/2,y }
  local p2 = { x+8,y+h-4, x+w-8,y+h-4, x+w/2,y+8 }
    color:set(7,0.5)
    love.graphics.polygon("fill",p1)
  if ss == 2 then
    color:set(1)
    love.graphics.polygon("line",p2)
  elseif ss == 1 then
    color:set(1,0.5)
    love.graphics.polygon("line",p2)
  end
end

function shapes.rectangle(x,y,w,h,c,ss)
  if ss then
    color:set(1,0.9)
    love.graphics.rectangle("line", x+2,y+2,w-4,h-4)
    color:set(6,0.5)
    love.graphics.rectangle("fill", x+4,y+4,w-8,h-8)
  else
    color:set(7,0.5)
    love.graphics.rectangle("fill", x,y,w,h)
  end
  color:set(c)
  love.graphics.rectangle("line", x+4,y+4,w-8,h-8)
end

u = 6
c = love.math.random(1,4)
n = love.math.random(2,13)
function shapes.circle(x,y,d)
  color:set(7,0.5)
  love.graphics.circle("fill",x,y,d)
  color:set(a.symc[c])
  love.graphics.circle("line",x,y,d-u*2)
  love.graphics.print(a.sym[c], x-d/4,y-d/2 )
  love.graphics.print(n, x-d/4,y )
end

sw = 192

love.window.setMode(sw,sw)

function love.draw()
  color:set(8,true)
  love.graphics.setLineWidth(u)
  shapes.circle(sw/2,sw/2,sw/2)
end

