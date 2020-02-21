success = love.window.setMode(731, 411)

--
-- utils
--

color = require "color"

function RGB(r,g,b)
  if type(r)=="table" then
    r,g,b = unpack(r)
  end
  return r/255,g/255,b/255
end


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

--
-- "assets" and "design"
--

a = {}
a.sym = {"β","δ","λ","φ"}
a.symc = {9,10,12,13}
a.num = {"1","2","3","4","5","6","7","8","9","x","J","Q","K"}
a.stats_ord = { "mxa", "hs", "d", "xp" }
a.draw_data = {{3534, 2426, 1632, 1082, 658, 339, 187, 102, 35, 5, 0, 0}, {615, 1360, 1728, 1757, 1519, 1165, 864, 543, 310, 105, 32, 2}, {43, 315, 681, 1076, 1374, 1566, 1508, 1288, 1082, 692, 323, 52}, {1, 32, 136, 288, 565, 860, 1225, 1497, 1772, 1668, 1435, 521}, {0, 1, 9, 35, 93, 200, 364, 609, 1045, 1649, 2467, 3528}}

function a.stat_cost(s)
  if type(s)=="number" then
    s = a.stats_ord[s]
  end
  local c = g.stats[s]
  if s == "mxa" then
    c=c*5
  end
  return c
end

d = {}
d.w = love.graphics.getWidth()
d.h = love.graphics.getHeight()
d.hand = { x = 20, y = 300 }
d.card = { w = 48, h = 60 }
d.touch = {}
d.touch.selarea = 20
d.stats = { x = 600, y = 20 }
d.stat = { w = 60, h = 48 }
d.map = { x = 100, y = 10 }
d.tile = { w = 60, h = 52 }
d.xp_held_s = 15

function triangle(x,y,w,h,ss)
  local p1 = { x,y+h, x+w,y+h, x+w/2,y }
  local p2 = { x+8,y+h-4, x+w-8,y+h-4, x+w/2,y+8 }
    set_color(7,0.5)
    love.graphics.polygon("fill",p1)
  if ss == 2 then
    set_color(1)
    love.graphics.polygon("line",p2)
  elseif ss == 1 then
    set_color(1,0.5)
    love.graphics.polygon("line",p2)
  end
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

function new_tile(r)
  local dd = a.draw_data[r]
  local o = 10000
  local n = love.math.random(1,o)
  for i=1,12 do
    if n>dd[i] then
      n=n-dd[i]
    else
      return i+1
    end
  end
end

function reset()
  g = {}
  g.hand = {}
  g.drop = {}
  g.stats = { xp = 0, d = 1, hs = 5, mxa = 5 }
  g.progress = { i = 0, ac = 0 }
  g.map = {}
  g.mapv = {}
  for r=1,5 do
    g.map[r] = {}
    g.mapv[r] = {}
    for c=1,(6-r) do
      g.map[r][c] = 0
      g.mapv[r][c] = 0
    end
  end
  for c=1,5 do
    g.mapv[1][c] = 2
  end
  for i=1,5 do
    g.hand[i] = new_card()
    g.drop[i] = new_card()
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

function getstat(x,y,ss)
  lx = (x-d.stats.x)/d.stat.w
  ly = (y-d.stats.y)/d.stat.h+1
  if lx >= 0 and lx <= 1 and ly >= 1 and ly <= 5 then
    if ss then
      return math.floor(ly)
    end
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
      if ei and source then
        e = g[source][ei]
        if e.sel then
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
      elseif getstat(touch.x,touch.y) == "xp" then
        xp_held = true
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
    if xp_held then
      gs = getstat(x,y,true)
      if gs and gs < 4 then
        xp_held = gs
      else
        xp_held = true
      end
    end
  end
end

function love.mousepressed(x,y,button)
  if x>0 and y>0 and x<50 and y<50 and false then
    table.insert(g.hand,new_card())
  end
  if button == 1 then
    touch.x, touch.y = love.mouse.getPosition()
    touch.state = "touch"
  end
end

function love.mousereleased(x,y,button)
  if button == 1 then
    if touch.state == "touch" then
      local ei,source = getelem(x,y)
      if ei and ei == getelem(touch.x, touch.y) then
        e = g[source][ei]
        e.sel = not e.sel
      end
    elseif touch.state == "drag" then
      if held then
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
      elseif xp_held then
        local gs = getstat(x,y,true)
        if gs and gs ~= 4 then
          if g.stats.xp - a.stat_cost(gs) >= 0 then
            g.stats.xp = g.stats.xp - a.stat_cost(gs)
            g.stats[a.stats_ord[gs]] = g.stats[a.stats_ord[gs]] + 1
          end
        end
        xp_held = nil
      end
    end
  end
end

-- draw
function draw_card(cd,x,y)
  rectangle(x,y,d.card.w,d.card.h,a.symc[cd.sym],cd.sel)
  love.graphics.print(a.num[cd.num],x+(d.card.w/3),y+(d.card.h/5-4))
  love.graphics.print(a.sym[cd.sym],x+(d.card.w/3),y+(d.card.h/2-4))
end
function draw_stat(i,c,s,x,y,c2)
  rectangle(x,y,d.stat.w,d.stat.h,c,s)
  if c2 then
    set_color(c2)
  end
  love.graphics.print(i,x+(d.stat.w/3),y+(d.stat.h/5))
end

function love.draw()
  x, y = love.mouse.getPosition()
  devug = getstat(x,y)
  if not devug then
    devug = "nil"
  end
  set_color(8,true)
  love.graphics.setLineWidth(2)
  local gc = 0
  for i,cd in ipairs(g.hand) do
    if held_gi and i == held_gi then
      gc = gc + 1
    end
    draw_card(cd,d.hand.x+d.card.w*(i-1+gc),d.hand.y)
  end
  local sele = nil
  for i,st in ipairs(a.stats_ord) do
    local ie = g.stats[st]
    local c = 15
    local t = false
    if i == 4 then
      c = 16
      if xp_gi then
        t = true
      end
    end
    if i==xp_held then
      t = true
      sele = g.stats.xp - a.stat_cost(i)
    end
    if sele and st=="xp" then
      local ce = 9
      if sele >= 0 then
        ce = 12
      end
      draw_stat(sele,c,t,d.stats.x,d.stats.y+d.stat.h*(i-1),ce)
    else
      draw_stat(ie,c,t,d.stats.x,d.stats.y+d.stat.h*(i-1))
    end
    if i ~= 4 and xp_held then
      love.graphics.print(a.stat_cost(i),d.stats.x-d.stat.w*.8,d.stats.y+d.stat.h*(i-1+.1))
    end
  end
  draw_stat(table.getn(g.drop),6,false,d.stats.x-d.stat.w,d.stats.y+d.stat.h*(3))
  for r=1,5 do
    for c=1,(6-r) do
      if g.mapv[r][c] ~= -1 then
        triangle(d.map.x+d.tile.w*(c-1)+(d.tile.w*(r-1)/2), d.map.y+d.tile.h*(6-r-1), d.tile.w, d.tile.h, g.mapv[r][c])
        if g.mapv[r][c] == 2 then
          if g.map[r][c] == 0 then
            g.map[r][c] = new_tile(r)
          end
          love.graphics.print(g.map[r][c],d.map.x+d.tile.w*(c-1)+(d.tile.w*(r-1)/2)+d.tile.w*.3, d.map.y+d.tile.h*(6-r-1)+d.tile.h*.43)
        end
      end
    end
  end
  x, y = love.mouse.getPosition()
  if held then
    for i,cd in ipairs(held) do
      draw_card(cd,x-d.card.w/2+(i*4), y-d.card.h/2+(i*4))
    end
  elseif xp_held then
    set_color(7,0.5)
    love.graphics.circle("fill",x,y,d.xp_held_s)
    set_color(16)
    love.graphics.circle("line",x,y,d.xp_held_s-4)
  end
end
