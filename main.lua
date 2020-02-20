success = love.window.setMode(731, 411)
-- utils

function RGB(r,g,b)
  if type(r)=="table" then
    r,g,b = unpack(r)
  end
  return r/255,g/255,b/255
end
color = require "color"
function get_color(i,a)
  local r,g,b
  if a then
    r,g,b = RGB(color[i])
    return r,g,b,a
  else
    return RGB(color[i])
  end
end
function set_color(i,a)
  if type(a)=="boolean" and a then
    love.graphics.setBackgroundColor(get_color(i))
  else
    love.graphics.setColor(get_color(i,a))
  end
end
font = love.graphics.newFont("SourceCodePro-Bold.ttf",20)
love.graphics.setFont(font)

function clamp(i,min,max)
  return math.max(math.min(i,max),min)
end
-- "assets" and "design"

a = {}
a.sym = {"β","δ","λ","φ"}
a.symc = {9,10,12,13}
a.num = {"1","2","3","4","5","6","7","8","9","x","J","Q","K"}
a.stats_ord = { "mxa", "hs", "d", "xp" }
d = {}
d.w = love.graphics.getWidth()
d.h = love.graphics.getHeight()
d.hand = { x = 20, y = 300 }
d.card = { w = 48, h = 60 }
d.touch = {}
d.touch.selarea = 20
d.stats = { x = 600, y = 20 }
d.stat = { w = 60, h = 48 }
d.map = { x = 60, y = 20 }
d.tile = { w = 60, h = 52 }

function triangle(x,y,w,h,ss)
  local p1 = { x,y+h, x+w,y+h, x+w/2,y }
  local p2 = { x+8,y+h-4, x+w-8,y+h-4, x+w/2,y+8 }
  set_color(5,0.5)
  love.graphics.polygon("fill",p1)
  set_color(1)
  love.graphics.polygon("line",p2)
end

function rectangle(x,y,w,h,c,s)
  if s then
    set_color(1,0.9)
    love.graphics.rectangle("line", x+2,y+2,w-4,h-4)
    set_color(6,0.5)
    love.graphics.rectangle("fill", x+4,y+4,w-8,h-8)
  else
    set_color(7,0.5)
    love.graphics.rectangle("fill", x,y,w,h)
  end
  set_color(c)
  love.graphics.rectangle("line", x+4,y+4,w-8,h-8)
end
-- gamedata
function new_card()
  return { num = love.math.random(2,13),
           sym = love.math.random(1,4),
           sel = false }
end

function reset()
  g = {}
  g.hand = {}
  g.drop = {}
  g.stats = { xp = 0, d = 1, hs = 5, mxa = 5 }
  g.progress = { i = 0, ac = 0 }
  g.map = {}
  g.mapv = {}
  for i=1,5 do
    g.map[i] = {}
    g.mapv[i] = {}
    for j=1,i do
      g.map[i][j] = 0
      g.mapv[i][j] = 0
    end
  end
  for i=1,10 do
    g.hand[i] = new_card()
  end
end
reset()

held = nil
held_gi = nil
xp_gi = false

function unfetter_card(c)
  return { num = c.num, sym = c.sym, sel = false }
end


-- input

touch = { state = nil }

function love.keypressed(k)
  print(k)
  if k == "escape" then
    reset()
  end
end

function getelem(x,y,next)
  lx = (x-d.hand.x)/d.card.w+1
  ly = (y-d.hand.y)/d.card.h
  if ly>=0 and ly<=1 and ((lx>=1 and lx<=table.getn(g.hand)+1) or next) then
    return clamp(math.floor(lx),1,table.getn(g.hand)+1), "hand"
  end
  return nil
end

function getstat(x,y)
  lx = (x-d.stats.x)/d.stat.w
  ly = (y-d.stats.y)/d.stat.h+1
  if lx >= 0 and lx <= 1 and ly >= 1 and ly <= 5 then
    return a.stats_ord[math.floor(ly)]
  end
  return nil
end

function love.update(dt)
  held_gi = nil
  xp_gi = false
  x, y = love.mouse.getPosition()
  if love.mouse.isDown(1) then
    if not (x-d.touch.selarea<touch.x and x+d.touch.selarea>touch.x and
    y-d.touch.selarea<touch.y and y+d.touch.selarea>touch.y) and touch.state == "touch" then
      touch.state = "drag"
      ei,source = getelem(touch.x, touch.y)
      if ei then
        e = g[source][ei]
        if e.sel then
          -- TODO: select many cards
          held = {}
          new_hand = {}
          for i,cd in ipairs(g.hand) do
            if cd.sel then
              cd.source = "hand"
              table.insert(held,cd)
            else
              table.insert(new_hand,cd)
            end
          end
          g.hand = new_hand
        else
          e.source = source
          e.index = ei
          held = { e }
          table.remove(g[source], ei)
        end
      end
    elseif touch.state == "drag" and held then
      gi = getelem(x,y,true)
      if gi then
        held_gi = gi
      end
      if getstat(x,y)=="xp" then
        xp_gi = true
      end
    end
  end
end

function love.mousepressed(x,y,button)
  print(getstat(x,y))
  if button == 1 then
    touch.x, touch.y = love.mouse.getPosition()
    touch.state = "touch"
  end
end

function love.mousereleased(x,y,button)
  if button == 1 then
    if touch.state == "touch" then
      ei,source = getelem(x,y)
      if ei and ei == getelem(touch.x, touch.y) then
        e = g[source][ei]
        e.sel = not e.sel
      end
    elseif touch.state == "drag" and held then
      if getstat(x,y)=="xp" then
        g.stats.xp = g.stats.xp + table.getn(held)
      elseif held_gi then
        for k,cd in ipairs(held) do
          table.insert(g.hand,held_gi,unfetter_card(cd))
          held_gi=held_gi+1
        end
      else
        if table.getn(held) == 1 and held[1].index then
          table.insert(g[held[1].source],held[1].index,unfetter_card(held[1]))
        else
          for k,cd in ipairs(held) do
            table.insert(g[cd.source],unfetter_card(cd))
          end
        end
      end
      held = nil
    end
  end
end

-- draw
function draw_card(cd,x,y)
  --[[
  if cd.sel then
    set_color(1,0.9)
    love.graphics.rectangle("line", x+2,y+2,d.card.w-4,d.card.h-4)
    set_color(6,0.5)
    love.graphics.rectangle("fill", x+4,y+4,d.card.w-8,d.card.h-8)
  else
    set_color(7,0.5)
    love.graphics.rectangle("fill", x,y,d.card.w,d.card.h)
  end
  set_color(a.symc[cd.sym])
  love.graphics.rectangle("line", x+4,y+4,d.card.w-8,d.card.h-8)
  --]]
  rectangle(x,y,d.card.w,d.card.h,a.symc[cd.sym],cd.sel)
  love.graphics.print(a.num[cd.num],x+(d.card.w/3),y+(d.card.h/5-4))
  love.graphics.print(a.sym[cd.sym],x+(d.card.w/3),y+(d.card.h/2-4))
end
function draw_stat(i,c,s,x,y)
  --[[
  if s then
    set_color(1,0.9)
    love.graphics.rectangle("line", x+2,y+2,d.stat.w-4,d.stat.h-4)
    set_color(6,0.5)
    love.graphics.rectangle("fill", x+4,y+4,d.stat.w-8,d.stat.h-8)
  else
    set_color(7,0.5)
    love.graphics.rectangle("fill", x,y,d.stat.w,d.stat.h)
  end
  set_color(c)
  love.graphics.rectangle("line", x+4,y+4,d.stat.w-8,d.stat.h-8)
 --]]
  rectangle(x,y,d.stat.w,d.stat.h,c,s)
  love.graphics.print(i,x+(d.stat.w/3),y+(d.stat.h/5))
end


function love.draw()
  set_color(8,true)
  love.graphics.setLineWidth(2)
  if true then
    set_color(1)
    love.graphics.print("tröäänkle\n"..d.h.."+"..d.w.."\n= {β,δ,λ,φ}",0,0)
  end
  gc = 0
  for i,cd in ipairs(g.hand) do
    if held_gi and i == held_gi then
      gc = gc + 1
    end
    draw_card(cd,d.hand.x+d.card.w*(i-1+gc),d.hand.y)
  end
  for i,st in ipairs(a.stats_ord) do
    c = 15
    t = false
    if i == 4 then
      c = 16
      if xp_gi then
        t = true
      end
    end
    draw_stat(g.stats[st],c,t,d.stats.x,d.stats.y+d.stat.h*(i-1))
  end
  draw_stat(table.getn(g.drop),6,false,d.stats.x-d.stat.w,d.stats.y+d.stat.h*(3))
  for i=1,5 do
    for j=1,i do
      if g.mapv[i][j] ~= -1 then
        triangle(d.map.x+d.tile.w*i-(d.tile.w*(j+1)/2), d.map.y+d.tile.h*(5-j), d.tile.w, d.tile.h, g.mapv[i][j])
        if g.mapv == 2 then
          love.graphics.print(g.map[i][v])
        end
      end
    end
  end
  if held then
    for i,cd in ipairs(held) do
      x, y = love.mouse.getPosition()
      draw_card(cd,x-d.card.w/2+(i*4), y-d.card.h/2+(i*4))
    end
  end
  for i=1,548 do
    set_color(love.math.random(1,16))
    love.graphics.points(love.math.random(0,d.w),love.math.random(0,d.h))
  end
end
