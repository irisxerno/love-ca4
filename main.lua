-- fail leaderboard
-- keyboard controls

-- new/generate split

debugmode = false

function table_shuf(t)
  for i = #t, 2, -1 do
    local j = love.math.random(i)
    t[i], t[j] = t[j], t[i]
  end
end

function table_take(t,m)
  local newt = {}
  l = 1
  for i,v in ipairs(t) do
    if l > m then
      return newt
    end
    newt[i] = t[i]
    l = l + 1
  end
  return newt
end

function sortbyprops(p, n)
  return function (t1, t2)
    for i,v in ipairs(p) do
      if t1[v] and t2[v] then
        if t1[v] ~= t2[v] then
          if n and n[i] then
            return t1[v] > t2[v]
          else
            return t1[v] < t2[v]
          end
        end
      end
    end
    return false
  end
end

function pretty_time(t)
  sec = (t * 60) % 60
  return string.format("%02d:%02d", t, sec)
end

function RGB(r,g,b)
  if type(r)=="table" then
    r,g,b = unpack(r)
  end
  return r/255,g/255,b/255
end

-- Converts HSL to RGB. (input and output range: 0 - 255)
function HSL(h, s, l, a)
	if s<=0 then return l,l,l,a end
	h, s, l = h*6, s, l
	local c = (1-math.abs(2*l-1))*s
	local x = (1-math.abs(h%2-1))*c
	local m,r,g,b = (l-.5*c), 0,0,0
	if h < 1     then r,g,b = c,x,0
	elseif h < 2 then r,g,b = x,c,0
	elseif h < 3 then r,g,b = 0,c,x
	elseif h < 4 then r,g,b = 0,x,c
	elseif h < 5 then r,g,b = x,0,c
	else              r,g,b = c,0,x
	end return (r+m),(g+m),(b+m),a
end

function clamp(i,min,max)
  return math.max(math.min(i,max),min)
end

osString = love.system.getOS()
if osString == "Android" or osString == "iOS" then
  love.window.setFullscreen(true,"desktop")
else
  love.window.setMode(731, 411)
end

inspect = require "inspect"
binser = require "binser"
love.filesystem.setIdentity("antsuke.ca4")

font = love.graphics.newFont("SourceCodePro-Bold.ttf",20)
font_small = love.graphics.newFont("NotoSansJP-Regular.otf",14)
love.graphics.setFont(font)

-- "assets"
a = {}
a.maxgeno = 100
a.sym = {"β","δ","λ","φ"}
a.symc = {9,10,12,13}
a.num = {"1","2","3","4","5","6","7","8","9","x","J","Q","K"}
a.draw_data = require "draw_data"
a.scale_color = {[-1] = 9, [0] = 7, [1] = 5}

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
end
function debug:add(s)
  debug.string = debug.string .. inspect(s) .. "\n"
end


-- shapes
shapes = {}
function shapes.triangle(x,y,w,h,ss, sss)
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
  if sss then
    color:set(1,0.9)
    love.graphics.polygon("line",p1)
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

function shapes.circle(x,y,d,c, sss)
  color:set(7,0.5)
  love.graphics.circle("fill",x,y,d)
  color:set(c)
  love.graphics.circle("line",x,y,d-4)
  if sss then
    color:set(1,0.9)
      love.graphics.circle("line",x,y,d)
  end
end

function getelem_rectangle(self,x,y)
  lx = (x-self.x)/self.w
  ly = (y-self.y)/self.h
  if lx >= 0 and lx <= 1 and ly >= 0 and ly <= 1 then
    return true
  end
  return false
end

--
--  ██████  ██████       ██ ███████  ██████ ████████ ███████
-- ██    ██ ██   ██      ██ ██      ██         ██    ██
-- ██    ██ ██████       ██ █████   ██         ██    ███████
-- ██    ██ ██   ██ ██   ██ ██      ██         ██         ██
--  ██████  ██████   █████  ███████  ██████    ██    ███████
--

Object = require "classic"

--
-- Map
--

Tile = Object:extend()
Tile.w = 60
Tile.h = 52

function Tile:draw(x,y)
  shapes.triangle(x, y, Tile.w, Tile.h, self.v)
end

function rolltile(r)
  local si = -1
  local dd = a.draw_data[r]
  local o = 10000
  local n = love.math.random(1,o)
  for i=1,12 do
    if n>dd[i] then
      n=n-dd[i]
    else
      si = i+1
      break
    end
  end
  return si
end

function Tile:new()
  self.v = 0
  self.i = -1
end

function Tile:generate(ac, r, gp)
  local r_ac = r + ac
  self.i = 0
  while r_ac > 0 do
    self.i = self.i + rolltile(math.min(5,r_ac))
    r_ac = r_ac - 5
  end

  self.deck_kinds = {0,0,0,0}
  for i=1,self.i do
    local myi = love.math.random(1,4)
    self.deck_kinds[myi] = self.deck_kinds[myi] + 1
  end

  local ar_c = r + ac*5 - 1
  local used_kinds = {0,0,0,0}
  for i=1,ar_c do
    local k = love.math.random(1,4)
    if used_kinds[k] < ac + 1 + gp then
      used_kinds[k] = used_kinds[k] + 1
    end
  end
  self.armor_kinds = used_kinds
end

Map = Object:extend()
Map.x = 60
Map.y = 0

function Map:new(ac, gp)
  self.geno = 0
  self.ac = ac
  self.map = {}
  for r=1,5 do
    self.map[r] = {}
    for c=1,(6-r) do
      self.map[r][c] = { v = 0 }
    end
  end
  for c=1,5 do
    self.map[1][c] = Tile()
    self.map[1][c]:generate(self.ac, 1, gp)
    self.map[1][c].v = 2
  end
  self.curr_layer = 1
end

function Map:draw()
  for r=1,5 do
    for c=1,(6-r) do
      if self.map[r][c].v ~= -1 then
        local sss = nil
        if self.sel and (self.sel[1] == c and self.sel[2] == r) then
          sss = true
        end
        shapes.triangle(Map.x+Tile.w*(c-1)+(Tile.w*(r-1)/2), Map.y+Tile.h*(6-r-1), Tile.w, Tile.h, self.map[r][c].v, sss)
        if self.map[r][c].v == 2 then
          love.graphics.print(self.map[r][c].i,Map.x+Tile.w*(c-1)+(Tile.w*(r-1)/2)+Tile.w*.3, Map.y+Tile.h*(6-r-1)+Tile.h*.43)
        end
      end
    end
  end
  if self.peek then
    local c_d = Tile.w/6
    local tt = c_d*2
    local line = 1
    local column = 0
    local opc = 0.75

    local start_x = Map.x+Tile.w*(self.sel[1]-1)+(Tile.w*(self.sel[2]-1)/2) + Tile.w - Tile.w/4
    local start_y = Map.y+Tile.h*(6-self.sel[2]-1) - Tile.h/4
    if start_y < tt/2 then
      start_y = tt/2
    end

    color:set(7,opc)
    love.graphics.rectangle("fill", start_x, start_y+tt*(line-1), tt*8, tt*1)
    for i,v in ipairs(self.peek.armor) do
      column = column + 1
      if column > 8 then
        column = 1
        line = line + 1
        color:set(7,opc)
        love.graphics.rectangle("fill", start_x, start_y+tt*(line-1), tt*8, tt*1)
      end
      shapes.circle(start_x+c_d+tt*(column-1), start_y+c_d+(line-1)*tt, c_d,a.symc[v])
    end
    if column ~= 0 and (#self.peek.armor + #self.peek.deck > 8) then
      column = 0
      line = line + 1
      color:set(7,opc)
      love.graphics.rectangle("fill", start_x, start_y+tt*(line-1), tt*8, tt*1)
    end
    --]]
    for i,v in ipairs(self.peek.deck) do
      column = column + 1
      if column > 8 then
        column = 1
        line = line + 1
        color:set(7,opc)
        love.graphics.rectangle("fill", start_x, start_y+tt*(line-1), tt*8, tt*1)
      end
      shapes.rectangle(start_x+tt*(column-1), start_y+(line-1)*tt, tt, tt, a.symc[v])
    end
  end
end

function Map:getelem(x,y)
  local ly = 6-((y-self.y)/Tile.h)
  local lx = (((x-self.x)/Tile.w))+1-(ly-1)/2
  if ly > 1 and ly < 6 and lx > 1 and lx < 7-ly then
    return math.floor(lx),math.floor(ly)
  end
  return nil
end

function Map:click(x,y)
  self.peek = nil
  local c, r = self:getelem(x,y)
  if c and self.map[r][c].v > 0 then
    if self.sel and (self.sel[1] == c and self.sel[2] == r) and table.getn(world.hand.deck) > 0 then
      if not world.progress.hardcore then
        saves:save(0)
      else
        saves:clear()
      end
      world.switch:press(false)
      if self.map[r][c].v == 2 then
        world.battle = Battle(self.map[r][c], c, r)
      else
        local shadow = Tile()
        shadow:generate(self.ac, r, world.progress.gp)
        world.battle = Battle(shadow, c, r)
      end
    else
      self.sel = {c, r}
      if self.map[r][c].v == 2 then
        local e = self.map[r][c]
        local armor_kind = {}
        local deck_kind = {}
        for k=1,4 do
          for i=1,e.armor_kinds[k] do
            table.insert(armor_kind, k)
          end
          for i=1,e.deck_kinds[k] do
            table.insert(deck_kind, k)
          end
        end
        self.peek = { armor = armor_kind ,deck = deck_kind }
      end
    end
  else
    self.sel = nil
  end
end

function Map:reveal(c,r)
  for ir=-1,1 do
    for ic=-1,1 do
      local nc = ic +c
      local nr = ir +r
      if ir ~= ic and nr > 0 and nr < 6 and self.map[nr][nc] and self.map[nr][nc].v ~= -1 and self.map[nr][nc].v < 2 then
        self.map[nr][nc].v = self.map[nr][nc].v + 1
        if self.map[nr][nc].v == 2 then
          self.map[nr][nc] = Tile()
          self.map[nr][nc]:generate(self.ac, r, world.progress.gp)
          self.map[nr][nc].v = 2
        end
      end
    end
  end
  self.map[r][c].v = -1
end

--
-- Deck
--

Card = Object:extend()
Card.w = 48
Card.h = 60

function Card:new()
  self.num = love.math.random(2,13)
  self.sym = love.math.random(1,4)
  self.sel = false
end

function Card:clean()
  local n = Card()
  n.num = self.num
  n.sym = self.sym
  n.sel = false
  return n
end

function Card:draw(x,y)
  shapes.rectangle(x,y,Card.w,Card.h,a.symc[self.sym],self.sel)
  love.graphics.print(a.num[self.num],x+(Card.w/3),y+(Card.h/5-4))
  love.graphics.print(a.sym[self.sym],x+(Card.w/3),y+(Card.h/2-4))
end


Deck = Object:extend()
Deck.init = 5

function Deck:new()
  self.deck = {}
  for i=1,self.init do
    self.deck[i] = Card()
  end
end

function Deck:draw()
  local ge = 0
  for i,cd in ipairs(self.deck) do
    if i == self.g then
      ge = ge+1
    end
    cd:draw(self.x+(i-1+ge)*cd.w,self.y)
  end
end

function Deck:getelem(x,y,nx)
  local lx = (x-self.x)/Card.w+1
  local ly = (y-self.y)/Card.h
  if ly>=0 and ly<=1 and ((lx>=1 and lx<table.getn(self.deck)+1) or nx) then
    return clamp(math.floor(lx),1,table.getn(self.deck)+1), self.source
  end
  return nil
end

function Deck:sel(e)
  self.deck[e].sel = not (self.deck[e].sel)
end

function Deck:click(x,y,cx,cy)
  e1 = self:getelem(x,y)
  e2 = self:getelem(cx,cy)
  if e1 and e2 and e1 == e2 then
    self:sel(e1)
    return true
  end
  return false
end

function Deck:collect()
  stay = {}
  ret = {}
  for k,cd in ipairs(self.deck) do
    if cd.sel then
      cd.source = self.source
      table.insert(ret,cd)
    else
      table.insert(stay,cd)
    end
  end
  self.deck = stay
  return ret
end


function Deck:take(cx,cy)
  e = self:getelem(cx,cy)
  if e then
    if self.deck[e].sel then
      world.held_cards:collect()
    else
      cd = table.remove(self.deck,e)
      cd.source = self.source
      cd.g = e
      world.held_cards.deck = {cd}
    end
  end
end

function Deck:count(kinds)
  local b_kinds = {0,0,0,0}
  for k,cd in ipairs(self.deck) do
    local val = cd.num
    if b_kinds[cd.sym] > 1 then
      val = val * b_kinds[cd.sym]
    end
    b_kinds[cd.sym] = val
  end
  local ret = 0
  for k,i in ipairs(b_kinds) do
    local val = i
    if kinds and kinds[k] > 1 then
      val = val * kinds[k]
    end
    ret = ret + val
  end
  return ret
end

Hand = Deck:extend()
Hand.x = 50
Hand.y = 300
Hand.source = "hand"

function Hand:draw()
  Deck.draw(self)
  -- color:set(7)
  -- love.graphics.rectangle("fill",self.x,self.y+Card.h,Card.w*world.stats.hs.v,Card.h/4)
  local cc = 7
  if world.battle and world.battle.death_pause then
    cc = 9
  end
  shapes.rectangle(self.x,self.y+Card.h,Card.w*world.stats.hs.v,Card.h/4,cc)

end

Drop = Deck:extend()
Drop.x = 50
Drop.y = 110
Drop.source = "drop"

function Drop:draw()
  Deck.draw(self)
  shapes.rectangle(self.x,self.y+Card.h,Card.w*world.stats.d.v,Card.h/4,7)
  -- shapes.rectangle(self.x+Card.w*table.getn(self.deck),self.y-Card.h/4,Card.w*world.stats.d.v,Card.h/4,16)
end

CustomArmor = Object:extend()
CustomArmor.x = 50
CustomArmor.y = 25
CustomArmor.w = 50
CustomArmor.h = 50
CustomArmor.d = 25

function CustomArmor:new()
  self.sel = nil
  self.slots = {}
end

function CustomArmor:draw()
  -- shapes.rectangle(self.x, self.y, self.w, self.h, 1)
  local armorslots = world.stats.ca.v
  for i=1,armorslots do
    local clr = 6
    if self.slots[i] then
      clr = a.symc[self.slots[i].sym]
    end
    shapes.circle(self.x + self.d + self.d*2*(i-1),self.y + self.d,self.d, clr, self.sel == i)
    color:set(clr)
    if self.slots[i] then
      love.graphics.print(self.slots[i].num, self.x + self.d/2 + self.d*2*(i-1), self.y + self.d/2)
    end
  end
end

function CustomArmor:getelem(x,y)
  local lx = (x-self.x)/self.w+1
  local ly = (y-self.y)/self.h
  if ly>=0 and ly<=1 and ((lx>=1 and lx<world.stats.ca.v+1) or nx) then
    return clamp(math.floor(lx),1,world.stats.ca.v+1)
  end
  return nil
end

function CustomArmor:update(x,y)
  self.sel = nil
  local s = self:getelem(x,y)
  if s and world.held_cards.deck and #world.held_cards.deck == 1 then
    self.sel = s
  end
end

--
-- Stats
--

Stat = Object:extend()
Stat.w = 60
Stat.h = 48

function Stat:draw(x,y)
  shapes.rectangle(x,y,Stat.w,Stat.h,16,self.focus)
  love.graphics.print(self.v,x+(Stat.w/3),y+(Stat.h/5))
  if self:cost() > world.xp.v then
    color:set(9)
  else
    color:set(12)
  end
  if world.held_xp.t then
    love.graphics.print(self:cost(),x+Stat.w+(Stat.w/3),y+(Stat.h/5))
  end
end

function Stat:new(init, cost_mult, v_cost)
  self.v = init
  self.cost_mult = cost_mult
  if v_cost then
    self.v_cost = v_cost
  else
    self.v_cost = 0
  end
  self.focus = false
end

function Stat:cost()
  return self.cost_mult*(self.v+self.v_cost)
end

Stats = Object:extend()
Stats.x = 612
Stats.y = 50

function Stats:new()
  self.d = Stat(5,1)
  self.hs = Stat(5,1)
  self.ma = Stat(5,5)
  self.ca = Stat(0,5,5)
  self.table = {self.ca, self.ma, self.d, self.hs}
end

function Stats:draw()
  for i,st in ipairs(self.table) do
    st:draw(self.x,(i-1)*st.h+self.y)
  end
end

function Stats:getelem(x,y)
  lx = (x-self.x)/Stat.w
  ly = (y-self.y)/Stat.h+1
  if lx > 0 and lx < 1 and ly > 1 and ly < #self.table+1 then
    return math.floor(ly)
  end
  return nil
end

function Stats:update(x,y)
  self.focus = nil
  for k,s in ipairs(self.table) do
    s.focus = false
  end
  s = self:getelem(x,y)
  if s and world.held_xp.t then
      self.table[s].focus = true
      self.focus = s
  end
end

function Stats:buy(d)
  e = self.table[d]
  if e:cost() <= world.xp.v then
    world.xp.v = world.xp.v - e:cost()
    e.v = e.v + 1
  end
end

XP = Object:extend()
XP.x = Stats.x
XP.y = Stats.y+Stat.h*4
XP.w = Stat.w
XP.h = Stat.h

function XP:draw()
  shapes.rectangle(self.x,self.y,Stat.w,Stat.h, 15, self.focus)
  local i_v = self.v
  if world.stats.focus then
    i_v = i_v - world.stats.table[world.stats.focus]:cost()
    if i_v < 0 then
      color:set(9)
    else
      color:set(12)
    end
  end
  love.graphics.print(i_v,self.x+(Stat.w/3),self.y+(Stat.h/5))
end

function XP:new()
  self.v = 0
  self.focus = false
end

XP.getelem = getelem_rectangle

function XP:take(x,y)
  if self:getelem(x,y) then
    world.held_xp.t = true
  end
end

function XP:update(x,y)
  self.focus = false
  if self:getelem(x,y) and world.held_cards.deck then
    self.focus = true
  end
end

HeldCards = Object:extend()

function HeldCards:draw()
  local x, y = love.mouse.getPosition()
  if self.deck then
    for i,cd in ipairs(self.deck) do
      cd:draw(x-Card.w/2+(i*4), y-Card.h/2+(i*4))
    end
  end
end

function HeldCards:take(cx,cy)
  world.hand:take(cx,cy)
  if world.switch.drop.state and not world.battle then
    world.drop:take(cx,cy)
  end
end

function HeldCards:collect()
  self.deck = {}
  for i,cd in ipairs(world.hand:collect()) do
    table.insert(self.deck,cd)
  end
  for i,cd in ipairs(world.drop:collect()) do
    table.insert(self.deck,cd)
  end
end

function HeldCards:update(x,y)
  world.hand.g = nil
  world.drop.g = nil
  if world.battle then
    world.battle.my.g = nil
  end
  if self.deck then
    local e = world.hand:getelem(x,y,true)
    if e then
      world.hand.g = e
    end
    local e = world.drop:getelem(x,y,true)
    if e then
      world.drop.g = e
    end
    if world.battle then
      e = world.battle.my:getelem(x,y,true)
      if e then
        world.battle.my.g = e
      end
    end
  end
end

function HeldCards:drop()
  -- put limit here
  if self.deck then
    if world.xp.focus then
      world.xp.v = world.xp.v + table.getn(self.deck)
      world.progress.i = world.progress.i + table.getn(self.deck)
    elseif world.hand.g and world.stats.hs.v >= (table.getn(world.hand.deck) + table.getn(self.deck)) then
      for k,cd in ipairs(self.deck) do
        table.insert(world.hand.deck, world.hand.g, cd:clean())
        world.hand.g = world.hand.g + 1
      end
    elseif world.drop.g and world.stats.d.v >= (table.getn(world.drop.deck) + table.getn(self.deck)) then
      for k,cd in ipairs(self.deck) do
        table.insert(world.drop.deck, world.drop.g, cd:clean())
        world.drop.g = world.drop.g + 1
      end
    elseif world.customarmor.sel and #self.deck == 1 then
      world.customarmor.slots[world.customarmor.sel] = self.deck[1]
    elseif world.battle and world.battle.my.g and world.stats.ma.v >= (table.getn(self.deck)) then
      for k,cd in ipairs(self.deck) do
        table.insert(world.battle.my.deck, world.battle.my.g, cd:clean())
        world.battle.my.g = world.battle.my.g + 1
      end
      world.battle.my.g = 0
      world.battle:attack()
    else
      for k,cd in ipairs(self.deck) do
        if cd.source == "hand" then
          if cd.g then
            table.insert(world.hand.deck, cd.g, cd:clean())
          else
            table.insert(world.hand.deck, cd:clean())
          end
        else
          if cd.g then
            table.insert(world.drop.deck, cd.g, cd:clean())
          else
            table.insert(world.drop.deck, cd:clean())
          end
        end
      end
    end
  end
  self.deck = nil
end

HeldXP = Object:extend()

function HeldXP:new()
  self.t = false
end

function HeldXP:draw()
  if self.t then
    local x, y = love.mouse.getPosition()
    shapes.circle(x,y,20,15)
  end
end

function HeldXP:drop(x,y)
  if self.t then
    s = world.stats:getelem(x,y)
    if s then
      world.stats:buy(s)
    end
  end
  self.t = false
end

Switch = Object:extend()
Switch.w = Stat.w
Switch.h = Stat.h

function Switch:draw()
  shapes.rectangle(self.x,self.y,Stat.w,Stat.h, self.color, self.state)
  if self.text then
    love.graphics.print(self.text(),self.x+(Stat.w/3),self.y+(Stat.h/5))
  end
end

function Switch:new()
  self.state = false
end

function Switch:click(x,y)
  if self:getelem(x,y) then
    self.state = not self.state
  end
end

Switch.getelem = getelem_rectangle

LeaderboardSwitch = Switch:extend()
LeaderboardSwitch.x = Stats.x-Stat.w
LeaderboardSwitch.y = Stats.y
LeaderboardSwitch.color = 7

function LeaderboardSwitch:text()
  return string.format("%s%%",world.progress.geno)
end

function LeaderboardSwitch:draw()
  shapes.rectangle(self.x,self.y,Stat.w,Stat.h, self.color, self.state)
  love.graphics.print(string.format("%s%%",world.progress.geno),self.x+(Stat.w/4),self.y+(Stat.h/5))
  if world.progress.gp > 0 then
    love.graphics.print(string.format("+%s", world.progress.gp),self.x+(Stat.w/3)-Stat.w,self.y+(Stat.h/5))
  end
end

DropSwitch = Switch:extend()
DropSwitch.x = Stats.x-Stat.w
DropSwitch.y = Stats.y+Stat.h*3
DropSwitch.color = 15

function DropSwitch:text()
  return table.getn(world.drop.deck)
end

MapSwitch = Switch:extend()
MapSwitch.x = Stats.x-Stat.w
MapSwitch.y = Stats.y+Stat.h*2
MapSwitch.color = 14

function MapSwitch:draw()
  shapes.rectangle(self.x,self.y,Stat.w,Stat.h, self.color, self.state)
  love.graphics.print(world.progress.ac .. "/5",self.x+(Stat.w/4),self.y+(Stat.h/5))
end

SaveSwitch = Switch:extend()
SaveSwitch.x = Stats.x-Stat.w
SaveSwitch.y = Stats.y+Stat.h
SaveSwitch.color = 5

SwitchBoard = Object:extend()

function SwitchBoard:new()
  self.drop = DropSwitch()
  self.map = MapSwitch()
  self.save = SaveSwitch()
  self.leaderboard = LeaderboardSwitch()
  self.list = {"drop", "map", "save", "leaderboard"}
end

function SwitchBoard:draw()
  for i,n in ipairs(self.list) do
    self[n]:draw()
  end
end

function SwitchBoard:press(name)
  local ps = false
  if name then
    ps = self[name].state
  end
  if name ~= false and self[name].state == true then
    return
  end
  for i,n in ipairs(self.list) do
    self[n].state = false
  end
  if name then
    self[name].state = not ps
  end
end

function SwitchBoard:click(x,y)
  for i,n in ipairs(self.list) do
    e = self[n]:getelem(x,y)
    if e then
      self:press(self.list[i])
    end
  end
end

Leaderboards = Object:extend()
Leaderboards.version = 3
Leaderboards.filename = "leaderboards"

if debugmode then
  Leaderboards.filename = "leaderboards_debug"
end

function Leaderboards:new()
  self.data = {
    normal = {
      quick = {},
      low = {},
      geno = {}
    },
    hardcore = {
      quick = {},
      low = {},
      geno = {}
    }
  }
  local info = love.filesystem.getInfo(self.filename)
  if info then
    local contents = love.filesystem.read(self.filename)
    local d = binser.deserializeN(contents)
    if d and d.version == self.version then
      self.data = d
    else
      local v = d.version
      if not v then
        v = "unknown"
      end
      love.filesystem.write(self.filename..".old-"..v,contents)
      love.filesystem.remove(self.filename)
    end
  end
end

function Leaderboards:add()
  local entry = {
    date = os.date("%F %T"),
    id = world.id,
    i = world.progress.i,
    time = timer:get_time()/60,
    geno = world.progress.geno
  }
  if not world.progress.hardcore then
    entry.deaths = saves.deaths
  end
  local slot
  local sortc
  if world.progress.hardcore then
    slot = self.data.hardcore
    sortc = 3
  else
    slot = self.data.normal
    sortc = 5
  end
  table.insert(slot.quick,entry)
  table.sort(slot.quick, sortbyprops({"time", "i", "geno"}, {false, false, false}))
  slot.quick = table_take(slot.quick, sortc)
  table.insert(slot.low,entry)
  table.sort(slot.low, sortbyprops({"i", "geno", "time"}, {false, false, false}))
  slot.low = table_take(slot.low, sortc)
  table.insert(slot.geno,entry)
  table.sort(slot.geno, sortbyprops({"geno", "time", "i"}, {true, false, true}))
  slot.geno = table_take(slot.geno, sortc)

  self:file()
end

function Leaderboards:file()
  self.data.version = self.version
  love.filesystem.write(self.filename,binser.serialize(self.data))
end

LeaderboardShow = Object:extend()
LeaderboardShow.x = 40
LeaderboardShow.y = 40
LeaderboardShow.w = 230
LeaderboardShow.h = 90
LeaderboardShow.h2 = 60
LeaderboardShow.t = 12
LeaderboardShow.t2 = 15

function LeaderboardShow:draw()
  color:set(1)
  love.graphics.setFont(font_small)

  local catg = {"quick", "low", "geno"}
  local desc = {"素早い", "最小限", "大量虐殺"}
  love.graphics.print("レギュラー", self.x, self.y-2*self.t2)
  for i1,v1 in ipairs(catg) do
    vv1 = desc[i1]
    love.graphics.print(vv1, self.x, self.y-self.t2+self.h*(i1-1))
    for i2,v in ipairs(leaderboards.data.normal[v1]) do
      local r, g, b = v.id
      love.graphics.setColor(r, g, b)
      love.graphics.print(string.format("け %d.\t殺 %d%%\t亡 %d*\t時 %s", v.i, v.geno, v.deaths, pretty_time(v.time)), self.x, self.y+self.t*(i2-1)+self.h*(i1-1))
    end
    color:set(1)
  end
  love.graphics.print("ハードコア", self.x+self.w, self.y-2*self.t2)
  for i1,v1 in ipairs(catg) do
    vv1 = desc[i1]
    love.graphics.print(vv1, self.x+self.w, self.y-self.t2+self.h2*(i1-1))
    for i2,v in ipairs(leaderboards.data.hardcore[v1]) do
      local r, g, b = v.id
      love.graphics.setColor(r, g, b)
      love.graphics.print(string.format("け %d.\t殺 %d%%\t時 %s", v.i, v.geno, pretty_time(v.time)), self.x+self.w, self.y+self.t*(i2-1)+self.h2*(i1-1))
    end
    color:set(1)
  end
  love.graphics.print("落第", self.x+self.w, self.y-self.t2+self.h*2)
  love.graphics.print("カミングスーン", self.x+self.w, self.y-self.t2+self.h*2+self.t*2)

  -- love.graphics.print(inspect(leaderboards.data), self.x, self.y)

  love.graphics.setFont(font)
end

Saves = Object:extend()
Saves.version = 11
Saves.filename = "save"

if debugmode then
  Saves.filename = "save_debug"
end

function Saves:new()
  self.data = {}
  self.deaths = 0
  local info = love.filesystem.getInfo(self.filename)
  if info then
    local contents = love.filesystem.read(self.filename)
    local d = binser.deserializeN(contents)
    if d and d.version == self.version then
      self.data = d
      self.deaths = d.deaths
      timer.add_time = d.add_time
    else
      local v = d.version
      if not v then
        v = "unknown"
      end
      love.filesystem.write(self.filename..".old-"..v,contents)
      love.filesystem.remove(self.filename)
    end
  end
end

function Saves:delete(ic)
  self.data[ic] = nil
  self:file()
end

function Saves:save(ic)
  if not world.map then
    return
  end
  if world.battle then
    return
  end
  self.data[ic] = {}
  local sv = self.data[ic]
  -- hand
  sv.hand = {}
  for k,cd in ipairs(world.hand.deck) do
    table.insert(sv.hand,{num = cd.num, sym = cd.sym})
  end
  -- drop
  sv.drop = {}
  for k,cd in ipairs(world.drop.deck) do
    table.insert(sv.drop,{num = cd.num, sym = cd.sym})
  end
  -- customarmor
  sv.customarmor = {}
  for k,cd in ipairs(world.customarmor.slots) do
    table.insert(sv.customarmor,{num = cd.num, sym = cd.sym})
  end
  -- map
  sv.map = {}
  for r=1,5 do
    sv.map[r] = {}
    for c=1,(6-r) do
      sv.map[r][c] = {i = world.map.map[r][c].i, v = world.map.map[r][c].v, deck_kinds = world.map.map[r][c].deck_kinds, armor_kinds = world.map.map[r][c].armor_kinds }
    end
  end
  sv.mapgeno = world.map.geno

  -- stats
  sv.stats = { d = world.stats.d.v, hs = world.stats.hs.v, ma = world.stats.ma.v, ca = world.stats.ca.v, }
  -- xp
  sv.xp = world.xp.v
  sv.ac = world.progress.ac
  sv.i = world.progress.i
  sv.geno = world.progress.geno
  sv.gp = world.progress.gp

  sv.id = world.id

  self:file()
end

function Saves:load(ic)
  local sv = self.data[ic]
  if not sv then
    return
  end

  world.id = sv.id

  -- stats
  world.stats.d.v = sv.stats.d
  world.stats.hs.v = sv.stats.hs
  world.stats.ma.v = sv.stats.ma
  world.stats.ca.v = sv.stats.ca

  -- sv.stats = { d = world.stats.d.v, hs = world.stats.hs.v, ma = world.stats.ma.v, }

  -- xp
  world.xp.v = sv.xp
  world.progress.ac = sv.ac
  world.progress.i = sv.i
  world.progress.geno = sv.geno
  world.progress.gp = sv.gp

  -- hand
  world.hand.deck = {}
  for k,cd in ipairs(sv.hand) do
    local c = Card()
    c.num = cd.num
    c.sym = cd.sym
    table.insert(world.hand.deck,c)
  end
  -- drop
  world.drop.deck = {}
  for k,cd in ipairs(sv.drop) do
    local c = Card()
    c.num = cd.num
    c.sym = cd.sym
    table.insert(world.drop.deck,c)
  end
  -- customarmor
  world.customarmor.slots = {}
  for k,cd in ipairs(sv.customarmor) do
    local c = Card()
    c.num = cd.num
    c.sym = cd.sym
    table.insert(world.customarmor.slots,c)
  end
  -- map
  world.map.ac = sv.ac
  world.map.map = {}
  for r=1,5 do
    world.map.map[r] = {}
    for c=1,(6-r) do
      if sv.map[r][c].i then
        local t = Tile()
        t.i = sv.map[r][c].i
        t.v = sv.map[r][c].v
        t.deck_kinds = sv.map[r][c].deck_kinds
        t.armor_kinds = sv.map[r][c].armor_kinds
        world.map.map[r][c] = t
      else
        world.map.map[r][c] = { v = sv.map[r][c].v }
      end
    end
  world.map.geno = sv.mapgeno
  end
end

function Saves:clear()
  self.data = {}
  self.deaths = 0
--  self.start_time = love.timer.getTime()
--  self.add_time = 0
  self:file()
end

function Saves:fullclear()
  self:clear()
  timer = Timer()
end


function Saves:file()
  self.data.version = self.version
  self.data.deaths = self.deaths
  self.data.add_time = timer:get_time()
  love.filesystem.write(self.filename,binser.serialize(self.data))
end

SaveOptions = Object:extend()

function SaveOptions:new()
  self.slots = SaveSlots()
  self.current = CurrentGame()
  self.hardcore = HardcoreGame()
  self.new = NewGame()
end

function SaveOptions:draw()
  if not world.progress.hardcore then
    self.slots:draw()
  end
  self.current:draw()
  self.hardcore:draw()
  self.new:draw()
end

function SaveOptions:update(x,y)
  if not world.progress.hardcore then
    self.slots:update(x,y)
  end
  self.current:update(x,y)
  self.hardcore:update(x,y)
end

function SaveOptions:take(x,y)
  if not world.progress.hardcore then
    self.slots:take(x,y)
  end
  self.current:take(x,y)
  self.new:take(x,y)
end

SaveSlots = Object:extend()
SaveSlots.x = 40
SaveSlots.y = 60
SaveSlots.w = 50
SaveSlots.h = 50
SaveSlots.c = 6

function SaveSlots:draw()
  for i=0,self.c do
    local c = 9
    if i == 0 then
      c = 10
    end
    shapes.rectangle(self.x+self.w*i,self.y,self.w,self.h,c,self.g == i)
    if saves.data[i] then
      love.graphics.print(saves.data[i].i,self.x+self.w*i+(Stat.w/8),self.y+(Stat.h/6))
      love.graphics.setFont(font_small)
      love.graphics.print(string.format("+%s", #saves.data[i].drop),self.x+self.w*i+(Stat.w/4),self.y+(Stat.h/2))
      love.graphics.setFont(font)
      for j=1,saves.data[i].ac do
        shapes.rectangle(self.x+self.w*i,self.y-(Stat.h/8)*j,SaveSlots.w,Card.h/8,5)
      end
      local r, g, b = saves.data[i].id
      love.graphics.setColor(r, g, b)
      love.graphics.rectangle("line", self.x+self.w*i+6,self.y+6,self.w-12,self.h-12)
    end
  end

end

function SaveSlots:update(x,y)
  self.g = nil
  e = self:getelem(x,y)
  if e and world.held_save.t and world.held_save.source ~= e and (saves.data[e] or world.held_save.source ~= -2) then
    self.g = e
  end
end

function SaveSlots:getelem(x,y)
  local lx = (x-self.x)/self.w
  local ly = (y-self.y)/self.h
  if ly>=0 and ly<=1 and (lx>=0 and lx<self.c+1) then
    return clamp(math.floor(lx),0,self.c)
  end
  return nil
end

function SaveSlots:take(x,y)
  local e = self:getelem(x,y)
  if e and saves.data[e] then
    world.held_save.t = true
    world.held_save.source = e
  end
end

CurrentGame = Object:extend()
CurrentGame.x = SaveSlots.x + SaveSlots.w*2
CurrentGame.y = 180
CurrentGame.w = SaveSlots.w*(SaveSlots.c-2)
CurrentGame.h = SaveSlots.h

function CurrentGame:draw()
  local c = 5
  if not world.map then
    c = 1
  end
  shapes.rectangle(self.x,self.y,self.w,self.h,c,self.focus)
  love.graphics.print("~~~~~~~~~~~~",self.x+(SaveSlots.w/2),self.y+(self.h/4))
  local r, g, b = world.id
  love.graphics.setColor(r, g, b)
  love.graphics.rectangle("line", self.x+6,self.y+6,self.w-12,self.h-12)
end

CurrentGame.getelem = getelem_rectangle

function CurrentGame:update(x,y)
  self.focus = false
  if world.held_save.t and world.held_save.source ~= -1 and self:getelem(x,y) then
    self.focus = true
  end
end

function CurrentGame:take(x,y)
  if not world.map or world.progress.hardcore then
    return
  end
  if self:getelem(x,y) then
    world.held_save.t = true
    world.held_save.source = -1
  end
end

HardcoreGame = Object:extend()
HardcoreGame.x = CurrentGame.x + SaveSlots.w*(SaveSlots.c-2)
HardcoreGame.y = 180
HardcoreGame.w = SaveSlots.w
HardcoreGame.h = SaveSlots.h

function HardcoreGame:draw()
  shapes.rectangle(self.x,self.y,self.w,self.h,8,self.focus)
  love.graphics.rectangle("line", self.x+6,self.y+6,self.w-12,self.h-12)
  if world.progress.hardcore then
    local r, g, b = world.id
    love.graphics.setColor(r, g, b)
    if saves.data[7] then
      love.graphics.print(saves.data[7].i,self.x+(Stat.w/8),self.y+(Stat.h/6))
    end
    love.graphics.rectangle("line", self.x+6,self.y+6,self.w-12,self.h-12)
  end
end

HardcoreGame.getelem = getelem_rectangle

function HardcoreGame:update(x,y)
  self.focus = false
  if world.held_save.t and world.held_save.source == -2 and self:getelem(x,y) then
    self.focus = true
  end
end

function HardcoreGame:take(x,y)
  if self:getelem(x,y) then
    world.held_save.t = true
    world.held_save.source = -1
  end
end


NewGame = Object:extend()
NewGame.x = SaveSlots.x
NewGame.y = 180
NewGame.w = SaveSlots.w
NewGame.h = SaveSlots.h

function NewGame:draw()
  shapes.rectangle(self.x,self.y,self.w,self.h,4,self.focus)

  love.graphics.print("++",self.x+(SaveSlots.w/4),self.y+(SaveSlots.h/4))
end

NewGame.getelem = getelem_rectangle

function NewGame:take(x,y)
  if self:getelem(x,y) then
    world.held_save.t = true
    world.held_save.source = -2
  end
end

HeldSave = Object:extend()

function HeldSave:new(source)
  self.t = false
  self.source = source
end

function HeldSave:draw()
  if self.t then
    local x, y = love.mouse.getPosition()
    local c = 9
    if self.source == -2 then
      c = 4
    elseif self.source == -1 then
      c = 5
    elseif self.source == 0 then
      c = 10
    end
    shapes.circle(x,y,20,c)
    if self.source > -1 and saves.data[self.source] then
      local c = saves.data[self.source].id
      local r, g, b = c
      love.graphics.setColor(r, g, b)
      love.graphics.circle("line",x,y,20-6)
    elseif self.source == -1 then
      local r, g, b = world.id
      love.graphics.setColor(r, g, b)
      love.graphics.circle("line",x,y,20-6)
    end
  end
end

function HeldSave:drop(x,y)
  if self.t then
    -- do things like save
    if self.source == -2 and world.save_options.current.focus then
      saves:fullclear()
      world = World()
      world.switch:press("save")
    elseif self.source == -2 and world.save_options.slots.g then
      saves:delete(world.save_options.slots.g)
      saves:file()
    elseif self.source == -2 and world.save_options.hardcore.focus then
      saves:fullclear()
      world = World()
      world.progress.hardcore = true
      world.stats.d.v = 10
      world.switch:press("save")
      saves:save(7)
    elseif self.source == -1 and world.save_options.slots.g then
      saves:save(world.save_options.slots.g)
    elseif self.source > -1 and world.save_options.current.focus then
      saves:load(self.source)
    elseif self.source > -1 and world.save_options.slots.g then
      saves.data[world.save_options.slots.g] = saves.data[self.source]
      saves:file()
    end
  end
  self.t = false
end

--
-- World
--

World = Object:extend()

function World:new()
  self.leaderboard_show = LeaderboardShow()
  self.touch = Touch()
  self.progress = { ac = 0, i = 0, hardcore = false, geno = 0, gp = 0 }
  if debugmode then
    self.progress.ac = 4
  end
  local r, g, b = HSL(love.math.random(), 0.5 + love.math.random()/2, 0.5)
  self.id = {r, g , b}
  self.hand = Hand()
  self.drop = Drop()
  self.customarmor = CustomArmor()
  self.map = Map(self.progress.ac, self.progress.gp)
  self.save_options = SaveOptions()

  self.switch = SwitchBoard()
  self.stats = Stats()
  self.xp = XP()

  self.held_cards = HeldCards()
  self.held_xp = HeldXP()
  self.held_save = HeldSave()
end

function World:draw()
  love.graphics.setLineWidth(2)
  color:set(8,true)

  if self.switch.leaderboard.state then
    self.leaderboard_show:draw()
  end


  if not world.battle then
    self.stats:draw()
    self.xp:draw()
    self.switch:draw()
  else
    self.battle:draw()
  end

  self.hand:draw()

  if self.switch.drop.state then
    self.customarmor:draw()
    self.drop:draw()
  end

  self.held_cards:draw()
  self.held_xp:draw()
  self.held_save:draw()


  if self.switch.map.state and world.map then
    self.map:draw()
  end

  if self.switch.save.state then
    self.save_options:draw()
  end
end

function World:update()
  local x, y = love.mouse.getPosition()

  world.touch:update(x,y)
  world.held_cards:update(x,y)
  world.xp:update(x,y)
  world.customarmor:update(x,y)
  world.stats:update(x,y)
  world.save_options:update(x,y)

end

Touch = Object:extend()
Touch.selarea = 20

function Touch:new()
  self.state = nil
end

function Touch:pressed(x,y)
  self.x, self.y = x, y
  if world.battle and world.battle.attack_pause then
    world.battle:damage()
    self.state = nil
  elseif world.battle and world.battle.death_pause then
    world = World()
    if not world.progress.hardcore then
      saves:load(0)
      saves.deaths = saves.deaths + 1
      saves:file()
      world.switch:press("map")
    else
      saves:fullclear()
    end
    self.state = nil
  else
    self.state = "touch"
  end
end

function Touch:released(x,y)
  if self.state == "touch" then
    local touched = false
    if world.hand:click(x,y,self.x,self.y) then
      touched = true
    end
    if world.switch.drop.state then
      if world.drop:click(x,y,self.x,self.y) then
        touched = true
      end
    end
    if not world.battle and not touched then
      world.switch:click(x,y)
    end
    if world.switch.map.state and world.map then
      world.map:click(x,y)
    end

  elseif self.state == "drag" then
    world.held_cards:drop()
    world.held_xp:drop(x,y)
    world.held_save:drop(x,y)
  end
  if world.battle then
    world.battle.body:click(x,y)
  end
  self.state = nil
end

function Touch:update(x,y)
  if self.state == "touch" and not (x-self.selarea<self.x and x+self.selarea>self.x and
  y-self.selarea<self.y and y+self.selarea>self.y) then
    self.state = "drag"
    world.held_cards:take(self.x,self.y)
    if not world.battle then
      world.xp:take(self.x,self.y)
    end
    if world.switch.save.state then
      world.save_options:take(self.x,self.y)
    end
  end
end


--
-- Battle
--

Battle = Object:extend()

function Battle:new(tile,c,r)
  self.body = Body(tile.deck_kinds)
  self.armor = Armor(tile.armor_kinds, r, world.progress.ac)
  self.myarmor = MyArmor(world.customarmor, r, world.progress.ac)
  self.my = MyAttack()
  self.enem = false
  self.attack_pause = false
  self.death_pause = false
  self.scale = 0
  self.c = c
  self.r = r
end

function Battle:draw()
  self.body:draw()
  self.myarmor:draw()
  self.armor:draw()
  self.my:draw()
  if self.enem then
    self.enem:draw()
  end
  shapes.rectangle(EnemAttack.x,EnemAttack.y+Card.h,Card.w*world.stats.ma.v,Card.h/4,a.scale_color[self.scale])
end

function Battle:attack()
  self.enem = EnemAttack()
  table_shuf(self.body.deck)
  for i=1,math.min(table.getn(self.my.deck), table.getn(self.body.deck)) do
    self.enem.deck[i] = table.remove(self.body.deck)
  end

  self.my.a = self.my:count(self.myarmor.kinds)
  self.enem.a = self.enem:count(self.armor.kinds)

  if self.my.a > self.enem.a then
    self.scale = 1
  elseif self.enem.a > self.my.a then
    self.scale = -1
  end

  self.attack_pause = true
end

function Battle:damage()
  if self.my.a > self.enem.a then
    for k,cd in ipairs(self.enem.deck) do
      table.insert(world.hand.deck, cd:clean())
    end
  end

  if self.my.a >= self.enem.a then
    self.body.stolen = self.body.stolen - table.getn(self.enem.deck)
    if self.body.stolen < 0 then
      self.body.stolen = 0
    end
  else
    for k,cd in ipairs(self.my.deck) do
      table.insert(self.body.deck, cd:clean())
      self.body.stolen = self.body.   stolen + 1
    end

    for i=1,math.min(table.getn(self.my.deck), table.getn(world.drop.deck)) do
      table.insert(world.hand.deck, table.remove(world.drop.deck, 1))
    end
  end

  self.body.hp = table.getn(self.body.deck)

  self.my = MyAttack()
  self.enem = nil

  local addt = 0

  if self.body.hp <= 0 or debugmode then

    world.map:reveal(self.c,self.r)
    world.map.geno = world.map.geno+1

    world.switch:press("drop")
    world.battle = nil
    world.progress.geno = world.progress.geno+1

    if world.progress.hardcore then
      saves:save(7)
    end

    if world.progress.geno >= 20*(world.progress.gp+1) then
      world.progress.gp = world.progress.gp + 1
    end

    if self.r == 5 then
      if world.map.geno >= 15 then
        world.progress.geno = world.progress.geno+5
      else
        addt = self.body.o_hp + self.armor.nk
      end

      world.progress.ac = world.progress.ac + 1

      if world.progress.ac < 5 then
        world.map = Map(world.progress.ac, world.progress.gp)
      else
        world.map = nil
        leaderboards:add()
        world.switch:press("leaderboard")
        saves:fullclear()
      end
    end

    for i=1,math.min((world.stats.d.v) - table.getn(world.drop.deck), self.body.o_hp + self.armor.nk)+addt do
      table.insert(world.drop.deck, Card())
    end
  end

  self.attack_pause = false
  self.scale = 0

  if table.getn(world.hand.deck) < 1 then
    self.death_pause = true
  end
end

Body = Object:extend()
Body.x = 100
Body.y = 70
Body.w = Stat.w
Body.h = Stat.h

function Body:new(deck_kinds)
  self.reset_button = false
  self.stolen = 0

  self.hp = 0
  self.deck = {}

  for k=1,4 do
    for i=1,deck_kinds[k] do
      local ocard = Card()
      ocard.sym = k
      table.insert(self.deck, ocard)
      self.hp = self.hp + 1
    end
  end

  self.o_hp = self.hp
end

function Body:draw()
  shapes.rectangle(self.x,self.y,self.w,self.h,9, self.reset_button)
  love.graphics.print(self.hp,self.x+(self.w/3),self.y+(self.h/5))
  for i=1,self.stolen do
    shapes.rectangle(self.x,self.y-(self.h/8)*i,self.w,Card.h/8,5)
  end
end

function Body:click(x,y)
  if self:getelem(x,y) then
    if not self.reset_button then
      self.reset_button = true
    else
      world = World()
      if not world.progress.hardcore then
        saves:load(0)
        saves.deaths = saves.deaths + 1
        saves:file()
        world.switch:press("map")
      else
        saves:fullclear()
      end
    end
  elseif self.reset_button then
    self.reset_button = false
  end
end

Body.getelem = getelem_rectangle

Armor = Object:extend()
Armor.x = 50
Armor.y = 40
Armor.cd = 25

function Armor:new(armor_kinds, r, ac)
  self.guessed_arc = r + ac*5 - 1
  self.kinds = {1,1,1,1}
  self.used_kinds = {0,0,0,0}
  self.nk = 0
  self.tk = 0
  self.used_kinds = armor_kinds
  for k=1,4 do
    if self.used_kinds[k] ~= 0 then
      self.tk = self.tk + 1
    end
    for i=1,self.used_kinds[k] do
      local v = love.math.random(2,13)
      if r == 5 then
        v = math.max(v,love.math.random(2,13))
      end
      self.kinds[k] = self.kinds[k]*v
      self.nk = self.nk + 1
    end
  end
end

function Armor:draw()
  local c = self.tk - 1
  for k_i=1, #self.kinds do
    local k = #self.kinds + 1 - k_i
    local av = self.kinds[k]
    if av > 1 then
      for i=1,self.used_kinds[k] do
        local diff = 4*(self.used_kinds[k]-i-1)
        shapes.circle(self.x + self.cd*2*c - diff,self.y - diff,self.cd,a.symc[k])
      end
      color:set(a.symc[k])
      love.graphics.print(av,self.x+self.cd*2*c-self.cd*.5,self.y-self.cd*.5)
      c = c - 1
    end
  end
end

-- NOTE: do not override CustomArmor.
MyArmor = Armor:extend()
MyArmor.x = 350
MyArmor.y = 40

function MyArmor:new(custom_armor, r, ac)
  self.kinds = {1,1,1,1}
  self.used_kinds = {0,0,0,0}
  self.nk = 0
  self.tk = 0
  if custom_armor.slots then
    for i,v in ipairs(custom_armor.slots) do
      if self.used_kinds[v.sym] == 0 then
        self.tk = self.tk + 1
      end
      self.used_kinds[v.sym] = self.used_kinds[v.sym] + 1
      self.kinds[v.sym] = self.kinds[v.sym]*v.num
      self.nk = self.nk + 1
    end
  end
end

AttackDeck = Deck:extend()
AttackDeck.init = 0

function AttackDeck:draw()
  Deck.draw(self)
  if self.a then
    color:set(14)
    love.graphics.print(self.a,self.x-Card.w,self.y+Card.h/5)
  end
end

EnemAttack = AttackDeck:extend()
EnemAttack.x = 70
EnemAttack.y = 140
EnemAttack.source = "enemattack"

MyAttack = AttackDeck:extend()
MyAttack.x = 70
MyAttack.y = EnemAttack.y + Card.h/4 + Card.h
MyAttack.source = "myattack"

function MyAttack:getelem(x,y,nx)
  local lx = (x-self.x)/Card.w+1
  local ly = (y-self.y)/Card.h
  if ly>=-1 and ly<=2 and ((lx>=1 and lx<=table.getn(self.deck)+1) or nx) then
    return clamp(math.floor(lx),1,table.getn(self.deck)+1), self.source
  end
  return nil
end

Timer = Object:extend()

function Timer:new()
  self.start_time = love.timer.getTime()
  self.add_time = 0
  self.idle_time = love.timer.getTime()
  self.idle = false
end

function Timer:get_time()
  if self.idle then
    return self.add_time
  else
    return self.add_time + (love.timer.getTime() - self.start_time)
  end
end

function Timer:get_idle()
  return love.timer.getTime() - self.idle_time
end

function Timer:reset_idle()
  self.add_time = self:get_time()
  self.idle_time = love.timer.getTime()
  self.idle = false
  self.start_time = love.timer.getTime()
end

function Timer:update()
  if self:get_idle() >= 60 then
    self.add_time = self:get_time()
    self.idle = true
  end
end

--
-- callbacks
--

function love.load()
  timer = Timer()
  saves = Saves()
  leaderboards = Leaderboards()
  world = World()
  world.switch:press("drop")
  if saves.data[7] then
    saves:load(7)
    world.progress.hardcore = true
    world.switch:press("map")
  elseif saves.data[0] then
    saves:load(0)
    world.switch:press("save")
  end
end

function love.draw()
  world:draw()
  if debugmode then
    color:set(15)
    love.graphics.print("debugmode",1,1)
  end
  if debug.show then
    color:set(1)
    love.graphics.print(debug.string,1,21)
  end
end

function love.mousepressed(x,y,button)
  if button == 1 then
    world.touch:pressed(x,y)
  end
end

function love.mousereleased(x,y,button)
  if button == 1 then
    world.touch:released(x,y)
  end
end

function love.update(dt)
  timer:update()
  world:update()
  if debugmode then
    if love.keyboard.isDown("e") then
      world.xp.v = world.xp.v + 1
      world.progress.i = world.progress.i + 1
    end
    require("lovebird").update()
  end
end

function love.keypressed(k)
  if debugmode then
    if k == "d" then
      table.insert(world.drop.deck,Card())
    end
    if k == "h" then
      table.insert(world.hand.deck,Card())
    end
  end
  if k == "y" then
    debug.show = not debug.show
  end
end

function love.mousemoved(x, y, dx, dy, istouch)
  timer:reset_idle()
end

function love.quit()
  if  world.progress.hardcore then
    saves:save(7)
  else
    saves:save(0)
  end
  saves:file()
end
