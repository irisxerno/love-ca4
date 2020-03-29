-
zsh: command not found: sl
- utils
function RGB(r,g,b)
  if type(r)=="table" then
    r,g,b = unpack(r)
  end
  return r/255,g/255,b/255
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

font = love.graphics.newFont("SourceCodePro-Bold.ttf",20)
love.graphics.setFont(font)

-- "assets"
a = {}
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

function shapes.circle(x,y,d,c)
  color:set(7,0.5)
  love.graphics.circle("fill",x,y,d)
  color:set(c)
  love.graphics.circle("line",x,y,d-4)
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

function Tile:generate(r)
  local r_ac = r + world.progress.ac
  self.i = 0
  while r_ac > 0 do
    self.i = self.i + rolltile(math.min(5,r_ac))
    r_ac = r_ac - 5
  end
end

Map = Object:extend()
Map.x = 40
Map.y = 0

function Map:new()
  self.map = {}
  for r=1,5 do
    self.map[r] = {}
    for c=1,(6-r) do
      self.map[r][c] = Tile()
    end
  end
  for c=1,5 do
    self.map[1][c].v = 2
  end
  self.curr_layer = 1
end

function Map:draw()
  for r=1,5 do
    for c=1,(6-r) do
      if self.map[r][c].v ~= -1 then
        shapes.triangle(Map.x+Tile.w*(c-1)+(Tile.w*(r-1)/2), Map.y+Tile.h*(6-r-1), Tile.w, Tile.h, self.map[r][c].v)
        if self.map[r][c].i == -1 then
          self.map[r][c]:generate(r)
        end
        if self.map[r][c].v == 2 then
          love.graphics.print(self.map[r][c].i,Map.x+Tile.w*(c-1)+(Tile.w*(r-1)/2)+Tile.w*.3, Map.y+Tile.h*(6-r-1)+Tile.h*.43)
        end
      end
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
  local c,r = self:getelem(x,y)
  if c and self.map[r][c].v > 0 then
    world.switch:press(false)
    world.battle = Battle(self.map[r][c].i, c, r)
  end
end

function Map:reveal(c,r)
  for ir=-1,1 do
    for ic=-1,1 do
      local nc = ic +c
      local nr = ir +r
      if ir ~= ic and nr > 0 and nr < 6 and self.map[nr][nc] and self.map[nr][nc].v ~= -1 and self.map[nr][nc].v < 2 then
        self.map[nr][nc].v = self.map[nr][nc].v + 1
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
  end
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
Hand.x = 30
Hand.y = 300
Hand.source = "hand"

function Hand:draw()
  Deck.draw(self)
  -- color:set(7)
  -- love.graphics.rectangle("fill",self.x,self.y+Card.h,Card.w*world.stats.hs.v,Card.h/4)
  shapes.rectangle(self.x,self.y+Card.h,Card.w*world.stats.hs.v,Card.h/4,7)

end

Drop = Deck:extend()
Drop.x = 40
Drop.y = 50
Drop.source = "drop"

function Drop:draw()
  Deck.draw(self)
  shapes.rectangle(self.x+Card.w*table.getn(self.deck),self.y-Card.h/4,Card.w*world.stats.d.v,Card.h/4,16)
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

function Stat:new(init, cost_mult)
  self.v = init
  self.cost_mult = cost_mult
  self.focus = false
end

function Stat:cost()
  return self.cost_mult*self.v
end

Stats = Object:extend()
Stats.x = 500
Stats.y = 20

function Stats:new()
  self.d = Stat(1,1)
  self.hs = Stat(5,1)
  self.ma = Stat(5,5)
  self.table = {self.ma, self.hs, self.d}
end

function Stats:draw()
  for i,st in ipairs(self.table) do
    st:draw(self.x,(i-1)*st.h+self.y)
  end
end

function Stats:getelem(x,y)
  lx = (x-self.x)/Stat.w
  ly = (y-self.y)/Stat.h+1
  if lx > 0 and lx < 1 and ly > 1 and ly < 4 then
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
XP.y = Stats.y+Stat.h*3
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

function XP:getelem(x,y)
  lx = (x-self.x)/Stat.w
  ly = (y-self.y)/Stat.h
  if lx >= 0 and lx <= 1 and ly >= 0 and ly <= 1 then
    return true
  end
  return false
end

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
  if world.battle then
    world.battle.my.g = nil
  end
  if self.deck then
    local e = world.hand:getelem(x,y,true)
    if e then
      world.hand.g = e
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

function Switch:getelem(x,y)
  lx = (x-self.x)/Stat.w
  ly = (y-self.y)/Stat.h
  if lx >= 0 and lx <= 1 and ly >= 0 and ly <= 1 then
    return true
  end
  return false
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

function MapSwitch:text()
  return world.progress.ac
end

SwitchBoard = Object:extend()

function SwitchBoard:new()
  self.drop = DropSwitch()
  self.map = MapSwitch()
  self.drop.state = true
  self.list = {"drop","map"}
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

--
-- World
--

World = Object:extend()

function World:new()
  self.progress = { ac = 0, i = 0 }
  self.hand = Hand()
  self.drop = Drop()
  self.map = Map()
  self.touch = Touch()

  self.switch = SwitchBoard()
  self.stats = Stats()
  self.xp = XP()

  self.held_cards = HeldCards()
  self.held_xp = HeldXP()
end

function World:draw()
  love.graphics.setLineWidth(2)
  color:set(8,true)
  self.hand:draw()
  if self.switch.drop.state then
    self.drop:draw()
  elseif self.switch.map.state then
    self.map:draw()
  end
  color:set(15)
  love.graphics.print(world.progress.i, 650,350)
  if not world.battle then
    self.switch:draw()
    self.switch:draw()
    self.stats:draw()
    self.xp:draw()
  else
    self.battle:draw()
  end
  self.held_cards:draw()
  self.held_xp:draw()
end

function World:update()
  local x, y = love.mouse.getPosition()

  world.touch:update(x,y)
  world.held_cards:update(x,y)
  world.xp:update(x,y)
  world.stats:update(x,y)
end

Touch = Object:extend()
Touch.selarea = 20

function Touch:new()
  self.state = nil
end

function Touch:pressed(x,y)
  self.x, self.y = x, y
  if world.battle and world.battle.pause then
    world.battle:damage()
    self.state = nil
  else
    self.state = "touch"
  end
end

function Touch:released(x,y)
  if self.state == "touch" then
    world.hand:click(x,y,self.x,self.y)

    if world.switch.drop.state then
      world.drop:click(x,y,self.x,self.y)
    end

    if world.switch.map.state then
      world.map:click(x,y)
    end
    if not world.battle then
      world.switch:click(x,y)
    end
  elseif self.state == "drag" then
    world.held_cards:drop()
    world.held_xp:drop(x,y)
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
  end
end


--
-- Battle
--

Battle = Object:extend()

function Battle:new(hp,c,r)
  self.body = Body(hp)
  self.armor = Armor(r)
  self.my = MyAttack()
  self.enem = false
  self.pause = false
  self.scale = 0
  self.c = c
  self.r = r
end
function Battle:draw()
  self.body:draw()
  self.armor:draw()
  self.my:draw()
  if self.enem then
    self.enem:draw()
  end
  shapes.rectangle(EnemAttack.x,EnemAttack.y+Card.h,Card.w*world.stats.ma.v,Card.h/4,a.scale_color[self.scale])
end

function Battle:attack()
  self.enem = EnemAttack()
  for i=1,math.min(table.getn(self.my.deck),self.body.hp) do
    self.enem.deck[i] = Card()
  end
  world.progress.i = world.progress.i + table.getn(self.my.deck)
  self.my.a = self.my:count()
  self.enem.a = self.enem:count(self.armor.kinds)
  if self.my.a > self.enem.a then
    self.scale = 1
  elseif self.enem.a > self.my.a then
    self.scale = -1
  end
  self.pause = true
end

function Battle:damage()
  if self.my.a > self.enem.a then
    for k,cd in ipairs(self.enem.deck) do
      table.insert(world.hand.deck,cd:clean())
    end
  end
  if self.enem.a <= self.my.a then
    self.body.hp = self.body.hp - table.getn(self.my.deck)
  end
  self.my = MyAttack()
  self.enem = nil
  if self.body.hp <= 0 then
    for i=1,math.min(world.stats.d.v, self.body.o_hp + self.armor.nk) do
      table.insert(world.drop.deck, Card())
    end
    world.map:reveal(self.c,self.r)
    if self.r == 5 then
      world.progress.ac = world.progress.ac + 1
      world.map = Map()
    end
    world.switch.map.state = false
    world.switch.drop.state = true
    world.battle = nil
  end
  self.pause = false
  self.scale = 0
end

Body = Object:extend()
Body.x = 100
Body.y = 70

function Body:new(hp)
  self.hp = hp
  self.o_hp = hp
end

function Body:draw()
  shapes.rectangle(self.x,self.y,Stat.w,Stat.h,9)
  love.graphics.print(self.hp,self.x+(Stat.w/3),self.y+(Stat.h/5))
end

Armor = Object:extend()
Armor.x = 50
Armor.y = 40
Armor.cd = 25

function Armor:new(r)
  self.ar_c = r + world.progress.ac*5 - 1
  self.kinds = {1,1,1,1}
  self.used_kinds = {0,0,0,0}
  self.nk = 0
  self.tk = 0
  for i=1,self.ar_c do
    local k = love.math.random(1,4)
    local v = love.math.random(2,13)
    if r == 5 then
      v = math.max(v,love.math.random(2,13))
    end
    if self.used_kinds[k] < world.progress.ac + 1 then
      if self.used_kinds[k] == 0 then
        self.tk = self.tk + 1
      end
      self.kinds[k] = self.kinds[k]*v
      self.used_kinds[k] = self.used_kinds[k] + 1
      self.nk = self.nk+1
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

--
-- callbacks
--

function love.load()
  world = World()
end

function love.draw()
  world:draw()
  if debug.show then
    color:set(1)
    love.graphics.print(debug.string,1,1)
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
  world:update()
  local x, y = love.mouse.getPosition()
end

function love.keypressed(k)
  print(k)
  if k == "e" then
    world = World()
    debug.string = ""
  end
  if k == "d" then
    table.insert(world.drop.deck,Card())
  end
  if k == "y" then
    debug.show = not debug.show
  end
end
