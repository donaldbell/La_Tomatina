pico-8 cartridge // http://www.pico-8.com
version 43
__lua__

-- tomatina
-- tab 0: globals

gnd_top = 82
gnd_bot = 105
cam_x   = 0
game_state = "title"
score = 0
wobble = 0
crowd_cd = 0
level = 1
level_cd = 0
npc_spd_g = 0.7
npc_cd_g = 90
over_music_pending = false
over_music_start_pat = -1
title_cam = -128
title_timer = 0
title_flash_t = 0
title_fly = {}
title_pile = {}
pile_ht = {}
title_top_edge = {}
title_spawn_cd = 60

entities = {}

function on_pud(e)
  if e==pl and pl.boots>0 then return false end
  if (e.jsy or 0)<0 then return false end
  for _,t in ipairs(entities) do
    if t.kind=="puddle" and abs(e.x-t.x)<t.sz+2 and abs(e.y-t.y)<3 then
      return true
    end
  end
end

-->8
-- tab 1: player

pl = {
  x=64, y=90, dir=1, spd=2.0,
  state="idle", timer=0,
  hx=-3, hy=-15, hw=7, hh=15,
  ammo=12, hp=5,
  jsy=0, jvy=0, jump_cd=0,
  boots=0, mask_cd=0, poncho=0, racket=0, umbrella=0,
  throw_cd=0, scarf_cd=0, bikini_cd=0,
}

local function pl_input(e)
  local dx,dy=0,0
  if btn(0) then dx-=1 end
  if btn(1) then dx+=1 end
  if btn(2) then dy-=0.5 end
  if btn(3) then dy+=0.5 end
  if dx!=0 and dy!=0 then dx*=0.707 dy*=0.707 end
  e.x+=dx*e.spd  e.y+=dy*e.spd
  if dx>0 then e.dir=1 elseif dx<0 then e.dir=-1 end
  e.y=mid(e.y,gnd_top,gnd_bot)
  e.x=mid(e.x,8,1050)
  return dx!=0 or dy!=0
end

pl.idle = function(e)
  if pl_input(e) then e.state="walk" e.timer=0 end
  if btnp(4) and e.ammo>0 then throw_tomato(e) end
  if btnp(5) and e.jump_cd==0 then e.state="jump" e.timer=0 e.jvy=-3.5 sfx(5) end
end

pl.walk = function(e)
  if not pl_input(e) then e.state="idle" e.timer=0 end
  if btnp(4) and e.ammo>0 then throw_tomato(e) end
  if btnp(5) and e.jump_cd==0 then e.state="jump" e.timer=0 e.jvy=-3.5 sfx(5) end
  if on_pud(e) then
    e.state="slip" e.timer=0 sfx(3)
    local t=flr(rnd(4))
    e.slip_type=t
    if t==1 then e.slip_vx=-e.dir*2.5
    elseif t==2 then e.slip_vx=e.dir*3.8
    elseif t==3 then e.slip_vx=e.dir*4.5
    else e.slip_vx=e.dir*2.5 end
  end
end

pl.slip = function(e)
  local dur=(e.slip_type==3) and 65 or (e.slip_type==2) and 55 or 40
  e.x+=e.slip_vx
  e.slip_vx*=0.85
  e.x=mid(e.x,8,1050)
  if btnp(5) then e.timer+=8 end
  if e.timer>dur then e.state="idle" e.timer=0 end
end

pl.jump = function(e)
  pl_input(e)
  if btnp(4) and e.ammo>0 then throw_tomato(e) end
  e.jsy+=e.jvy
  e.jvy+=0.5
  if e.jsy>=0 then
    e.jsy=0 e.jvy=0
    e.state="idle" e.timer=0
    e.jump_cd=12
  end
end

pl.draw = function(e)
  local jo=e.jsy or 0
  local x=e.x-4  local y=e.y-15+jo
  local fl=e.dir<0
  local sc=e.hp>=4 and 7 or e.hp==3 and 6 or e.hp==2 and 8 or 2
  if e.state=="slip" then
    pal(7,sc)
    spr(6,e.x-8,e.y-7,2,1,fl)
    pal()
    return
  end
  local ts=0
  if e.state=="walk" or e.state=="jump" then
    ts=flr(time()*8)%2==0 and 1 or 3
  end
  pal(7,sc)
  if e.throw_cd and e.throw_cd>0 then
    e.throw_cd-=1
    spr(2,x,y,1,1,fl)
    spr(16,x,y+8,1,1,fl)
  else
    spr(ts,x,y,1,2,fl)
  end
  pal()
  if e.mask_cd>0  then spr(8,x,y,1,1,fl) end
  if e.poncho>0   then spr(9,x,y,1,1,fl) end
  if e.scarf_cd>0  then spr(10,x,y,1,1,fl) end
  if e.bikini_cd>0 then spr(11,x,y,1,1,fl) end
  if e.umbrella>0  then spr(12,x,y,1,1,fl) end
  if e.racket>0    then spr(13,x,y,1,1,fl) end
end

-->8
-- tab 2: npcs

function npc_slip(e)
  e.x+=(e.slip_vx or 0)
  if e.slip_vx then e.slip_vx*=0.85 end
  e.x=mid(e.x,8,1050)
  if e.timer>38 then e.state="wander" e.timer=0 end
end

function npc_wander(e)
  if on_pud(e) then
    e.state="slip" e.timer=0
    e.slip_vx=(flr(rnd(2))==0 and e.dir or -e.dir)*2.5
    return
  end
  local dx=pl.x-e.x  local dy=pl.y-e.y
  e.dir=dx>0 and 1 or -1
  if abs(dx)>10 then
    e.x+=e.dir*e.spd
    e.y+=mid((e.ty or e.y)-e.y,-0.4,0.4)
    e.y=mid(e.y,gnd_top,gnd_bot)
  end
  e.cooldown=max(0,e.cooldown-1)
  if abs(dx)<80 and abs(dy)<18 and e.cooldown==0 and pl.mask_cd<=0 then
    e.state="throw" e.timer=0
  end
end

function npc_throw_st(e)
  if pl.mask_cd>0 then e.state="wander" e.timer=0 return end
  if e.timer==20 then
    npc_throw(e)
    e.cooldown=90+flr(rnd(60))
  end
  if e.timer>35 then e.state="wander" e.timer=0 end
end

function npc_hit(e)
  if e.timer>20 then e.state="wander" e.timer=0 end
end

function npc_down(e)
  if e.timer==0 then
    sfx(1)
    for i=1,1+flr(rnd(2)) do
      spawn_pickup(e.x+flr(rnd(14))-7,e.y)
    end
  end
  if e.timer>120 then e.state="getup" e.timer=0 end
end

function npc_getup(e)
  if e.timer>20 then e.state="wander" e.timer=0 e.hp=2 end
end

function npc_draw(e)
  local x=e.x-4  local y=e.y-15
  if e.state=="down" or e.state=="getup" then
    local prog=(e.state=="getup") and min(e.timer/20,1) or 0
    rectfill(e.x-7,e.y-flr(3+prog*12),e.x+7,e.y,8)
    return
  end
  if e.state=="slip" then
    spr(6,e.x-8,e.y-7,2,1,e.dir<0)
    return
  end
  local flash=(e.state=="hit" and e.timer%4<2)
  local fr=(e.state=="wander") and flr(time()*7)%2 or 0
  local fl=e.dir<0
  if flash then for i=0,15 do pal(i,7) end end
  spr(4+fr,x,y,1,2,fl)
  pal()
end

function spawn_npc(px,py)
  spawn({
    x=px,y=py,ty=py,dir=1,spd=npc_spd_g,
    state="wander",timer=0,
    hp=2,cooldown=npc_cd_g+flr(rnd(npc_cd_g)),kind="npc",
    hx=-3,hy=-14,hw=6,hh=14,
    wander=npc_wander,
    slip=npc_slip,
    throw=npc_throw_st,
    hit=npc_hit,
    down=npc_down,
    getup=npc_getup,
    draw=npc_draw,
  })
end

-->8
-- tab 3: projectiles

function throw_tomato(src)
  src.ammo-=1
  if src==pl then pl.throw_cd=10 sfx(2) end
  local bonus=btn(src.dir==1 and 1 or 0) and src.spd*src.dir*0.5 or 0
  spawn({
    x=src.x, y=src.y,
    vx=src.dir*3.5+bonus,
    sy=-4, vy=-1.5,
    state="fly", timer=0,
    hx=-2, hy=-2, hw=4, hh=4,
    fly=function(e)
      e.x+=e.vx
      e.sy+=e.vy
      e.vy+=e.vy<0 and 0.15 or 0.5
      if e.x<cam_x-20 or e.x>cam_x+148 then e.dead=true return end
      for _,t in ipairs(entities) do
        if t.kind=="npc" and t.state!="down" and t.state!="hit" then
          if abs(e.x-t.x)<7 and abs(e.y+e.sy-t.y)<16 then
            t.hp-=1
            if t.hp<=0 then t.state="down" t.hp=0
            else t.state="hit" end
            t.timer=0  e.dead=true return
          end
        end
      end
      if e.sy>=0 then e.sy=0 e.state="splat" e.timer=0 spawn_puddle(e.x,e.y) end
    end,
    splat=function(e)
      if e.timer>10 then e.dead=true end
    end,
    draw=function(e)
      if e.state=="fly" then
        pset(e.x,e.y,5)
        circfill(e.x,e.y+e.sy,1,8)
      else
        local r=2+flr(e.timer*0.5)
        circfill(e.x,e.y,r,8)
        if e.timer>3 then circfill(e.x,e.y,r-1,2) end
      end
    end,
  })
end

function npc_throw(src)
  local dx=pl.x-src.x
  local dist=abs(dx)
  local spd=mid(dist/30,1.2,2.2)*sgn(dx)
  local arc=mid(dist/45,0.3,1.5)
  spawn({
    x=src.x,y=src.y,
    vx=spd,sy=-arc*2.5,vy=-arc,
    state="fly",timer=0,
    fly=function(e)
      e.x+=e.vx
      e.sy+=e.vy
      e.vy+=e.vy<0 and 0.15 or 0.5
      if abs(e.x-pl.x)<7 and abs(e.y+e.sy-pl.y)<12 then
        if pl.racket>0 then
          pl.racket-=1
          local best,bd=nil,999
          for _,t in ipairs(entities) do
            if t.kind=="npc" and t.state!="down" then
              local d=abs(pl.x-t.x)
              if d<bd then best=t bd=d end
            end
          end
          if best then
            local od=pl.dir pl.dir=best.x>pl.x and 1 or -1
            pl.ammo+=1 throw_tomato(pl) pl.dir=od
          end
          spawn_floater(pl.x,pl.y-18,"deflected!",10)
        elseif pl.poncho>0 then
          pl.poncho-=1
          spawn_floater(pl.x,pl.y-18,"blocked!",11)
        elseif pl.umbrella>0 then
          if pl.umbrella%2==0 then
            spawn_floater(pl.x,pl.y-18,"blocked!",11)
          else
            pl.hp=max(0,pl.hp-1)
          end
          pl.umbrella-=1
        else
          pl.hp=max(0,pl.hp-1)
        end
        e.dead=true return
      end
      if e.x<cam_x-20 or e.x>cam_x+148 then e.dead=true return end
      if e.sy>=0 then e.sy=0 e.state="splat" e.timer=0 spawn_puddle(e.x,e.y) end
    end,
    splat=function(e)
      if e.timer>10 then e.dead=true end
    end,
    draw=function(e)
      if e.state=="fly" then
        circfill(e.x,e.y+e.sy,1,8)
      else
        local r=2+flr(e.timer*0.5)
        circfill(e.x,e.y,r,8)
        if e.timer>3 then circfill(e.x,e.y,r-1,2) end
      end
    end,
  })
end

function crowd_throw()
  local sx=cam_x+64
  local bias=(rnd(10)<6) and flr(rnd(220)) or -flr(rnd(150))
  local tx=mid(sx+bias,30,1550)
  local r=flr(rnd(10))
  local it=r<2 and 0 or r<3 and 1 or r<4 and 2 or r<5 and 3 or r<6 and 4 or r<7 and 5 or r<8 and 6 or 7
  local nm={"bikini top!","fan scarf!","boots!","scuba mask!","poncho!","padel!","umbrella!","gooool!"}
  local ic={14,8,4,1,11,5,12,7}
  spawn({
    x=sx,y=110,sy=0,
    vx=(tx-sx)/40,vy=-3.5,
    itype=it,iname=nm[it+1],icol=ic[it+1],
    state="fly",timer=0,
    fly=function(e)
      e.x+=e.vx e.y+=e.vy e.vy+=0.15
      if e.vy>0 and e.y>=gnd_top and e.y<=gnd_bot then
        e.y=mid(e.y,gnd_top,gnd_bot)
        e.vx=0 e.state="idle" e.timer=0
      end
      if e.timer>150 or e.y>120 then e.dead=true end
    end,
    idle=function(e)
      if abs(pl.x-e.x)<6 and abs(pl.y-e.y)<5 then
        if e.itype==7 then
          local best,bd=nil,999
          for _,t in ipairs(entities) do
            if t.kind=="npc" and t.state!="down" then
              local d=abs(e.x-t.x)
              if d<bd then best=t bd=d end
            end
          end
          if best then
            e.vx=sgn(best.x-e.x)*1.5 e.bounces=0
            e.state="kick" e.timer=0
            spawn_floater(e.x,e.y-10,"gooool!",10)
          else e.dead=true end
        else
          if e.itype==0 then pl.bikini_cd=300
          elseif e.itype==1 then pl.scarf_cd=300
          elseif e.itype==2 then pl.boots=1200
          elseif e.itype==3 then pl.mask_cd=300
          elseif e.itype==4 then pl.poncho=3
          elseif e.itype==5 then pl.racket=3
          elseif e.itype==6 then pl.umbrella=6
          end
          sfx(4)
          spawn_floater(e.x,e.y-8,e.iname,e.icol)
          e.dead=true
        end
      end
    end,
    kick=function(e)
      e.x+=e.vx
      e.sy=-flr(abs(sin(e.timer*0.1))*4)
      for _,t in ipairs(entities) do
        if t.kind=="npc" and t.state!="down" and t.state!="hit" then
          if abs(e.x-t.x)<8 then
            t.state="down" t.hp=0 t.timer=0
            e.bounces+=1
            if e.bounces>=6 then e.dead=true return end
            local best,bd=nil,999
            for _,n in ipairs(entities) do
              if n.kind=="npc" and n!=t and n.state!="down" then
                local d=abs(e.x-n.x)
                if d>5 and d<bd then best=n bd=d end
              end
            end
            if best then
              e.vx=sgn(best.x-e.x)*1.5 e.timer=0
            else e.dead=true end
            return
          end
        end
      end
      if e.timer>120 then e.dead=true end
    end,
    draw=function(e)
      local c=e.icol
      if e.state=="fly" then
        if e.timer%8<4 then rectfill(e.x-2,e.y-3,e.x+2,e.y,c)
        else rectfill(e.x-3,e.y-1,e.x+3,e.y+1,c) end
      elseif e.state=="kick" then
        ovalfill(e.x-3,e.y,e.x+3,e.y+1,5)
        local by=e.y+e.sy
        circfill(e.x,by,3,7)
        pset(e.x,by,0)
        pset(e.x-2,by-2,0) pset(e.x+2,by-2,0)
        pset(e.x-1,by+2,0) pset(e.x+1,by+2,0)
      else
        local fc=e.timer%6<3 and c or 7
        if e.itype==0 then
          pset(e.x-3,e.y-3,fc) pset(e.x-2,e.y-4,fc)
          rectfill(e.x-4,e.y-2,e.x-1,e.y,fc)
          pset(e.x,e.y-1,fc)
          pset(e.x+2,e.y-3,fc) pset(e.x+3,e.y-4,fc)
          rectfill(e.x+1,e.y-2,e.x+4,e.y,fc)
        elseif e.itype==1 then
          rectfill(e.x-4,e.y-1,e.x+4,e.y,fc)
          rectfill(e.x-4,e.y-3,e.x-3,e.y-1,fc)
          rectfill(e.x+3,e.y-3,e.x+4,e.y-1,fc)
          pset(e.x-1,e.y-1,10) pset(e.x+1,e.y-1,10)
        elseif e.itype==2 then
          rectfill(e.x-4,e.y-5,e.x-2,e.y,fc)
          rectfill(e.x-5,e.y-1,e.x-1,e.y,fc)
          rectfill(e.x+1,e.y-5,e.x+3,e.y,fc)
          rectfill(e.x+1,e.y-1,e.x+5,e.y,fc)
        elseif e.itype==3 then
          ovalfill(e.x-4,e.y-3,e.x+4,e.y+1,fc)
          ovalfill(e.x-3,e.y-2,e.x+3,e.y,1)
        elseif e.itype==4 then
          rectfill(e.x-4,e.y-3,e.x+4,e.y,fc)
          rectfill(e.x-2,e.y-5,e.x+2,e.y-3,fc)
          pset(e.x,e.y-4,7)
        elseif e.itype==5 then
          ovalfill(e.x-3,e.y-4,e.x+3,e.y,fc)
          line(e.x+2,e.y,e.x+5,e.y+3,4)
        elseif e.itype==6 then
          ovalfill(e.x-5,e.y-4,e.x+5,e.y-1,fc)
          line(e.x,e.y-1,e.x,e.y+2,5)
        else
          circfill(e.x,e.y-2,3,7)
          pset(e.x,e.y-2,0)
          pset(e.x-2,e.y-4,0) pset(e.x+2,e.y-4,0)
          pset(e.x-1,e.y,0) pset(e.x+1,e.y,0)
        end
      end
    end,
  })
end

-->8
-- tab 4: pickups & effects

function spawn_floater(px,py,txt,col)
  spawn({
    x=px,y=py,kind="floater",ftxt=txt,fcol=col,
    state="idle",timer=0,
    idle=function(e)
      e.y-=0.5
      if e.timer>50 then e.dead=true end
    end,
  })
end

function draw_floaters()
  for _,e in ipairs(entities) do
    if e.kind=="floater" then
      local c=e.timer>35 and 5 or (e.fcol or 7)
      print(e.ftxt,e.x-#e.ftxt*2,e.y,c)
    end
  end
end

function spawn_food(px,py,kind)
  local heal=(kind==1) and 2 or 1
  spawn({
    x=px,y=py,kind="food",fkind=kind,fheal=heal,
    state="idle",timer=0,
    idle=function(e)
      if abs(pl.x-e.x)<7 and abs(pl.y-e.y)<5 then
        pl.hp=min(5,pl.hp+e.fheal)
        if e.fkind==2 then wobble=20 end
        local nm={"bravas!","bocadillo!","cerveza!"}
        local nc={10,15,10}
        spawn_floater(e.x,e.y-8,nm[e.fkind+1],nc[e.fkind+1])
        e.dead=true
      end
    end,
    draw=function(e)
      if e.fkind==0 then
        rectfill(e.x-3,e.y-1,e.x+3,e.y,7)
        pset(e.x-3,e.y-3,7) pset(e.x+3,e.y-3,7)
        rectfill(e.x-2,e.y-3,e.x+2,e.y-1,10)
        pset(e.x-1,e.y-2,4) pset(e.x+1,e.y-3,4)
      elseif e.fkind==1 then
        rectfill(e.x-3,e.y-1,e.x+3,e.y,4)
        rectfill(e.x-2,e.y-2,e.x+2,e.y-1,15)
      else
        rectfill(e.x-2,e.y-4,e.x+2,e.y,10)
        rectfill(e.x-2,e.y-5,e.x+2,e.y-4,7)
      end
    end,
  })
end

function spawn_pickup(px,py)
  spawn({
    x=px, y=py,
    state="idle", timer=0,
    hx=-4, hy=-4, hw=8, hh=8,
    idle=function(e)
      if abs(pl.x-e.x)<5 and abs(pl.y-e.y)<5 and pl.ammo<12 then
        pl.ammo=min(12,pl.ammo+1)
        e.dead=true
      end
    end,
    draw=function(e)
      circfill(e.x,e.y-1,1,8)
      pset(e.x,e.y-2,3)
    end,
  })
end

function spawn_puddle(px,py)
  local n=0
  for _,e in ipairs(entities) do
    if e.kind=="puddle" then n+=1 end
  end
  if n>=40 then
    for _,e in ipairs(entities) do
      if e.kind=="puddle" then e.dead=true break end
    end
  end
  local sz=3+flr(rnd(3))
  spawn({
    x=px,y=py,kind="puddle",sz=sz,
    state="idle",timer=0,
    idle=function(e) end,
  })
end

function draw_puddles()
  for _,e in ipairs(entities) do
    if e.kind=="puddle" then
      ovalfill(e.x-e.sz,e.y-1,e.x+e.sz,e.y+1,8)
      ovalfill(e.x-e.sz+1,e.y-1,e.x+e.sz-1,e.y,2)
    end
  end
end

-->8
-- tab 5: entities

function spawn(t)
  t.timer=t.timer or 0
  entities[#entities+1]=t
  return t
end

function overlaps(a,b)
  return a.x+a.hx     < b.x+b.hx+b.hw
     and a.x+a.hx+a.hw > b.x+b.hx
     and a.y+a.hy     < b.y+b.hy+b.hh
     and a.y+a.hy+a.hh > b.y+b.hy
end

function update_entities()
  if pl[pl.state] then pl[pl.state](pl) end
  pl.timer+=1
  pl.jump_cd=max(0,pl.jump_cd-1)
  local alive={}
  for _,e in ipairs(entities) do
    if e[e.state] then e[e.state](e) end
    e.timer=(e.timer or 0)+1
    if not e.dead then alive[#alive+1]=e end
  end
  entities=alive
end

function draw_entities()
  local dl={pl}
  for _,e in ipairs(entities) do dl[#dl+1]=e end
  for i=2,#dl do
    local t=dl[i]  local j=i-1
    while j>0 and dl[j].y>t.y do dl[j+1]=dl[j] j-=1 end
    dl[j+1]=t
  end
  for _,e in ipairs(dl) do
    if e.draw then e.draw(e) end
  end
end

-->8
-- tab 6: background

function draw_bg()
  rectfill(cam_x, 0, cam_x+127, 79, 12)
  draw_clouds()
  draw_hills()
  draw_castle()
  draw_mid_buildings()
  draw_palms()
  draw_buildings()
  rectfill(cam_x,78,cam_x+127,79,6)
  rectfill(cam_x, gnd_bot+1, cam_x+127, 127, 0)
  draw_crowd()
  draw_ground_perspective()
  draw_puddles()
end

function draw_clouds()
  local prx = flr(cam_x * 0.93)
  srand(3)
  for i=1,40 do
    local cx = flr(rnd(1600)) + prx
    local cy = 5 + flr(rnd(12))
    local cw = 30 + flr(rnd(50))
    rectfill(cx+4, cy, cx+cw-4, cy+3, 7)
    rectfill(cx, cy+3, cx+cw, cy+6, 7)
  end
  srand(time())
end

function draw_hills()
  rectfill(cam_x, 48, cam_x+127, 79, 3)
  local prx = flr(cam_x * 0.80)
  srand(5)
  for i=1,60 do
    local hx = flr(rnd(1600)) + prx
    local hh = 4 + flr(rnd(10))
    local hw = 14 + flr(rnd(24))
    rectfill(hx, 49-hh, hx+hw, 48, 3)
  end
  srand(time())
end

function draw_mid_buildings()
  local prx = flr(cam_x * 0.55)
  local cols = {7,7,15,7,15,9,10}
  srand(9)
  for i=1,50 do
    local bx = flr(rnd(1600)) + prx
    local bh = 4+flr(rnd(8))
    local bw = 8+flr(rnd(16))
    local col = cols[1+flr(rnd(7))]
    rectfill(bx, 56-bh, bx+bw, 79, col)
  end
  srand(time())
end

function draw_palms()
  local prx=flr(cam_x*0.55)
  srand(11)
  for i=1,10 do
    local px=flr(rnd(1600))+prx
    rectfill(px,47,px+1,79,4)
    line(px,47,px-5,39,11) line(px+1,47,px-4,39,11)
    line(px,47,px-2,37,11) line(px+1,47,px-1,37,11)
    line(px,47,px+3,37,11) line(px+1,47,px+4,37,11)
    line(px,47,px+6,39,11) line(px+1,47,px+7,39,11)
    line(px,47,px+5,43,11) line(px+1,47,px+6,43,11)
    line(px,47,px-3,43,11) line(px+1,47,px-2,43,11)
  end
  srand(time())
end

function draw_buildings()
  local wcs={7,7,15,15,9,6}
  srand(31)
  local x=0
  while x<1600 do
    if x>=950 then break end
    local bw =20+flr(rnd(28))
    local bh =16+flr(rnd(20))
    local bc =wcs[1+flr(rnd(6))]
    local gf =flr(rnd(4))
    local wt =flr(rnd(2))
    local top=79-bh
    rectfill(x,top,x+bw,79,bc)
    rectfill(x,top,x+bw,top+1,5)
    line(x,top,x,79,5)
    if gf~=0 then
      local wy=top+5
      while wy<70 do
        local nw=1+flr(bw/18)
        local wsp=flr(bw/(nw+1))
        for j=1,nw do
          local wx=x+j*wsp-2
          if wt==0 then
            rectfill(wx,wy,wx+4,wy+5,5)
            rectfill(wx+1,wy+1,wx+3,wy+4,1)
          else
            rectfill(wx,wy,wx+5,wy+5,5)
            rectfill(wx+1,wy+1,wx+2,wy+4,1)
            rectfill(wx+3,wy+1,wx+4,wy+4,1)
          end
        end
        wy+=10
      end
    end
    if gf==0 then
      if bw>22 and bh>22 then
        local dw=min(16,flr(bw*0.5))
        local dx=x+flr((bw-dw)/2)
        rectfill(dx,68,dx+dw,79,5)
        for sl=0,10,2 do
          line(dx,68+sl,dx+dw,68+sl,0)
        end
        -- striped awning: colour cycles by building position
        local aw=({8,10,14,9})[1+((x\20)%4)]
        rectfill(dx-2,63,dx+dw+2,67,7)
        for sx=dx-2,dx+dw+2,4 do
          rectfill(sx,63,sx+1,67,aw)
        end
      else
        -- too small for door: age crack, corner varies by building size
        local corner=(bw+bh)%4
        local crx=(corner==1 or corner==3) and (x+bw-3) or (x+2)
        local crx2=(corner==1 or corner==3) and (x+bw-4) or (x+3)
        local cry=(corner>=2) and 74 or (top+2)
        pset(crx, cry,  5)
        pset(crx2,cry+1,5)
        pset(crx, cry+2,5)
        pset(crx2,cry+3,5)
        pset(crx, cry+4,5)
      end
    end
    x+=bw
  end
  srand(time())
end

function draw_castle()
  local bx = 120 + flr(cam_x * 0.7)
  -- curtain wall
  rectfill(bx-26,32,bx,55,9)
  -- curtain wall merlons (3 across)
  for i=0,2 do
    rectfill(bx-26+i*8,28,bx-23+i*8,32,9)
  end
  -- left bastion (raised section at wall end)
  rectfill(bx-26,27,bx-18,32,9)
  rectfill(bx-26,23,bx-24,27,9)
  rectfill(bx-22,23,bx-20,27,9)
  -- main tower
  rectfill(bx,24,bx+14,55,9)
  rectfill(bx,   20,bx+2,  24,9)
  rectfill(bx+4, 20,bx+6,  24,9)
  rectfill(bx+8, 20,bx+10, 24,9)
  rectfill(bx+12,20,bx+14, 24,9)
  -- tower window
  rectfill(bx+4, 34,bx+10,42,0)
  rectfill(bx+5, 30,bx+9, 34,0)
  -- rocky base
  rectfill(bx-26,50,bx+14,55,4)
end

function draw_exit()
end

function draw_ground_perspective()
  local dash_col={-1,2,-1,6,-1,1,-1,4}
  for r=0,25 do
    local sy=80+r
    local scale=2+flr(r/7)
    local tw_w=8*scale
    local sx=cam_x-(cam_x%tw_w)
    local lc=dash_col[1+(r%8)]
    for t=0,flr(128/tw_w)+2 do
      local tx=sx+t*tw_w
      rectfill(tx,sy,tx+tw_w-1,sy,5)
      if lc>=0 then
        local lx=tx+lc*scale
        rectfill(lx,sy,lx+scale-1,sy,6)
      end
    end
  end
end

function draw_crowd()
  local sk={15,9,4,14,15,9}
  local hr={0,4,5,2,8,3}
  local sh={8,8,2,8,9,2,8,8}  -- tomato-soaked crowd

  -- shadow base fills entire zone, gaps look like depth between bodies
  rectfill(cam_x,101,cam_x+127,127,5)

  -- far layer (6-8px wide full figures)
  local p1=flr(cam_x*0.15)
  srand(41)
  for i=1,240 do
    local cx=flr(rnd(1600))+p1
    local hw=5+flr(rnd(3))
    local sc=sk[1+flr(rnd(6))]
    rectfill(cx-1,112,cx+hw+1,119,sh[1+flr(rnd(8))])
    rectfill(cx,106,cx+hw,112,sc)
    rectfill(cx+1,106,cx+hw-1,108,hr[1+flr(rnd(6))])
  end
  srand(time())

  -- mid layer (12-17px wide heads)
  local p2=flr(cam_x*0.07)
  srand(53)
  for i=1,180 do
    local cx=flr(rnd(1600))+p2
    local hw=12+flr(rnd(5))
    local hh=11+flr(rnd(5))
    local ty=108+flr(rnd(6))
    local sc=sk[1+flr(rnd(6))]
    local hc=hr[1+flr(rnd(6))]
    local bc=sh[1+flr(rnd(8))]
    local bob=flr(sin(time()*0.3+cx*0.017)*1)
    rectfill(cx-4,ty+hh+bob,cx+hw+4,127,bc)
    rectfill(cx,ty+bob,cx+hw,ty+hh+bob,sc)
    rectfill(cx,ty+bob,cx+hw,ty+bob+3,hc)
  end
  srand(time())

  -- close layer: grid-based (12px slots, 24+px heads) gaps can never line up
  srand(79)
  for seg=0,133 do
    local cx=seg*12+flr(rnd(12))
    local hw=24+flr(rnd(10))
    local hh=16+flr(rnd(8))
    local ty=116+flr(rnd(7))
    local sc=sk[1+flr(rnd(6))]
    local hc=hr[1+flr(rnd(6))]
    local bc=sh[1+flr(rnd(8))]
    rectfill(cx-2,124,cx+hw+2,127,bc)
    rectfill(cx,ty,cx+hw,min(ty+hh,127),sc)
    rectfill(cx,ty,cx+hw,ty+4,hc)
  end
  srand(time())
end

-->8
-- tab 7: game states & hud

function _init()
  game_state="title"
  title_cam=-128
  title_timer=0
  title_flash_t=0
  title_fly={}
  title_pile={}
  pile_ht={}
  title_top_edge={}
  title_spawn_cd=60
  for i=0,127 do
    pile_ht[i]=127
    title_top_edge[i]=-1
    for row=32,79 do
      if sget(i,row)!=0 then
        title_top_edge[i]=row-8
        break
      end
    end
  end
  poke(0x5f2e,1)
  music(16)
end

function game_init()
  entities={}
  cam_x=0
  game_state="play"
  score=0
  level=1
  pl.x=64  pl.y=90  pl.dir=1
  pl.state="idle"  pl.timer=0
  pl.ammo=12  pl.hp=5
  pl.jsy=0  pl.jvy=0  pl.jump_cd=0
  pl.boots=0  pl.mask_cd=0  pl.poncho=0  pl.racket=0  pl.umbrella=0
  pl.scarf_cd=0  pl.bikini_cd=0
  wobble=0
  crowd_cd=150+flr(rnd(150))
  npc_spd_g=0.7
  npc_cd_g=90
  over_music_pending=false
  over_music_start_pat=-1
  srand(99)
  for i=1,40 do
    local px=100+flr(rnd(1400))
    local py=gnd_top+2+flr(rnd(gnd_bot-gnd_top-4))
    spawn_pickup(px,py)
  end
  srand(77)
  for i=1,8 do
    local nx=200+flr(rnd(1200))
    local ny=gnd_top+2+flr(rnd(gnd_bot-gnd_top-4))
    spawn_npc(nx,ny)
  end
  srand(55)
  for i=1,15 do
    local fx=150+flr(rnd(1300))
    local fy=gnd_top+2+flr(rnd(gnd_bot-gnd_top-4))
    local r=flr(rnd(10))
    spawn_food(fx,fy,r<4 and 0 or r<8 and 1 or 2)
  end
  srand(33)
  for i=1,10 do
    local px=100+flr(rnd(1400))
    local py=gnd_top+2+flr(rnd(gnd_bot-gnd_top-4))
    spawn_puddle(px,py)
  end
  srand(time())
  music(0)
end

function level_up_init()
  entities={}  cam_x=0  game_state="play"
  pl.x=64  pl.y=90  pl.dir=1
  pl.state="idle"  pl.timer=0
  pl.jsy=0  pl.jvy=0  pl.jump_cd=0
  wobble=0  crowd_cd=150+flr(rnd(150))
  local nc=min(8+(level-1)*2,18)
  npc_spd_g=min(0.7+(level-1)*0.08,1.3)
  npc_cd_g=max(90-(level-1)*10,30)
  srand(99+level*7)
  for i=1,40 do spawn_pickup(100+flr(rnd(1400)),gnd_top+2+flr(rnd(gnd_bot-gnd_top-4))) end
  srand(77+level*13)
  for i=1,nc do spawn_npc(200+flr(rnd(1200)),gnd_top+2+flr(rnd(gnd_bot-gnd_top-4))) end
  srand(55+level*11)
  for i=1,15 do
    local r=flr(rnd(10))
    spawn_food(150+flr(rnd(1300)),gnd_top+2+flr(rnd(gnd_bot-gnd_top-4)),r<4 and 0 or r<8 and 1 or 2)
  end
  srand(33+level*17)
  local np=min(10+(level-1)*5,40)
  for i=1,np do
    spawn_puddle(100+flr(rnd(1400)),gnd_top+2+flr(rnd(gnd_bot-gnd_top-4)))
  end
  srand(time())
end

function update_title_tomatoes()
  title_spawn_cd-=1
  if title_spawn_cd<=0 and #title_fly<8 then
    title_spawn_cd=20+flr(rnd(20))
    title_fly[#title_fly+1]={
      x=4+rnd(120),
      y=-3,
      vx=-1.5+rnd(3),
      vy=0.5+rnd(1),
    }
  end
  local alive={}
  for _,t in ipairs(title_fly) do
    t.vy+=0.12
    t.x+=t.vx
    t.y+=t.vy
    if t.x<2 then t.x=2 t.vx=abs(t.vx)*0.7 end
    if t.x>125 then t.x=125 t.vx=-abs(t.vx)*0.7 end
    local col=mid(0,flr(t.x),127)
    local te=title_top_edge[col]
    if te>=0 and pile_ht[col]>te and t.vy>0 and t.y+2>=te and t.y<te+8 then
      t.y=te-2
      t.vy=-abs(t.vy)*0.5
      t.vx=(rnd(1)<0.5 and -1 or 1)*(1.5+rnd(2))
    end
    -- circle-circle collision with each settled tomato
    local on_surf=false
    for _,s in ipairs(title_pile) do
      if abs(s.y-t.y)<6 then
        local dx=t.x-s.x  local dy=t.y-s.y
        local d2=dx*dx+dy*dy
        if d2<16 and d2>0 then
          local d=sqrt(d2)
          local nx=dx/d  local ny=dy/d
          t.x+=nx*(4-d)  t.y+=ny*(4-d)
          local dot=t.vx*nx+t.vy*ny
          if dot<0 then
            t.vx-=1.4*dot*nx
            t.vy-=1.4*dot*ny
          end
          if ny<-0.3 then on_surf=true end
        end
      end
    end
    -- floor
    if t.y+2>=126 then
      t.y=124  on_surf=true
      if abs(t.vy)>0.4 then t.vy=-abs(t.vy)*0.42 else t.vy=0 end
      t.vx*=0.85
    end
    local keep=true
    if on_surf and abs(t.vx)<0.3 and abs(t.vy)<0.3 then
      title_pile[#title_pile+1]={x=flr(t.x),y=flr(t.y)}
      for c=max(0,flr(t.x)-2),min(127,flr(t.x)+2) do
        pile_ht[c]=min(pile_ht[c],flr(t.y)-2)
      end
      keep=false
    end
    if keep and t.y>-20 and t.y<132 then alive[#alive+1]=t end
  end
  title_fly=alive
end

function draw_title_tomatoes()
  for _,p in ipairs(title_pile) do
    circfill(p.x,p.y,2,8)
    pset(p.x-1,p.y-1,9)
  end
  for _,t in ipairs(title_fly) do
    circfill(t.x,t.y,2,8)
    pset(t.x,t.y-2,3)
    pset(t.x-1,t.y-1,9)
    pset(t.x,t.y,2)
  end
end

function update_title()
  title_timer+=1
  if title_cam<0 then
    title_cam=min(title_cam+4,0)
    return
  end
  title_flash_t=(title_flash_t+1)%40
  update_title_tomatoes()
  if (btnp(4) or btnp(5)) and title_timer>30 then
    game_state="expo"
  end
end

function draw_title()
  cls(0)
  camera(title_cam,0)
  draw_title_tomatoes()
  sspr(0,32,128,48,0,24)
  if title_cam>=0 then
    local c=title_flash_t<20 and 7 or 0
    print("z/x to start",40,104,c)
  end
  camera(0,0)
end

function update_expo()
  if btnp(4) or btnp(5) then
    game_init()
  end
end

function draw_expo()
  cls(0)
  print("every august, the streets",4,12,7)
  print("of the spanish town of bunol",4,20,7)
  print("run red.",4,28,7)
  print("people gather to hurl",4,40,7)
  print("thousands of tomatoes",4,48,7)
  print("at each other. for fun.",4,56,7)
  print("you just want to get out.",4,68,7)
  print("z/x to enter the chaos",4,112,7)
end

function camera_scroll()
  cam_x=mid(pl.x-64,0,900)
end

function draw_level_up()
  rectfill(24,48,103,80,0)
  rect(25,49,102,79,9)
  local lbl="nivel "..level
  print(lbl,64-#lbl*2,57,9)
  local msg="buena suerte!"
  print(msg,64-#msg*2,68,7)
end

function draw_gameover()
  rectfill(20,40,107,88,0)
  rect(21,41,106,87,8)
  print("game over",37,50,8)
  local ss=flr(score/30)
  print("survived: "..ss.."s",33,63,7)
  print("z/x to restart",29,76,5)
end

function draw_hud()
  local ss=flr(score/30)
  print(ss,64-#tostring(ss)*2,2,7)
  for i=0,pl.ammo-1 do
    circfill(4+(i%6)*6,2+flr(i/6)*5,2,8)
  end
  local gx=125
  if pl.umbrella>0 then circfill(gx,4,3,12) print(pl.umbrella,gx-1,0,0) gx-=8 end
  if pl.racket>0 then circfill(gx,4,3,5) print(pl.racket,gx-1,0,7) gx-=8 end
  if pl.poncho>0 then circfill(gx,4,3,11) print(pl.poncho,gx-1,0,7) gx-=8 end
  if pl.mask_cd>0 then circfill(gx,4,3,1) gx-=8 end
  if pl.boots>0 then circfill(gx,4,3,4) end
end

function _update()
  if game_state=="title" then update_title() return end
  if game_state=="expo"  then update_expo()  return end
  if over_music_pending then
    if stat(24) != over_music_start_pat then
      music(16)
      over_music_pending = false
    end
  end
  if game_state=="over" then
    if btnp(4) or btnp(5) then _init() end
    return
  end
  if game_state=="level_up" then
    level_cd-=1
    if level_cd<=0 then level_up_init() end
    return
  end
  score+=1
  crowd_cd-=1
  if crowd_cd<=0 then crowd_throw() crowd_cd=180+flr(rnd(120)) end
  wobble=max(0,wobble-1)
  if pl.mask_cd>0 then pl.mask_cd-=1 end
  if pl.boots>0 then pl.boots-=1 end
  if pl.scarf_cd>0 then pl.scarf_cd-=1 end
  if pl.bikini_cd>0 then pl.bikini_cd-=1 end
  update_entities()
  camera_scroll()
  if pl.x>1040 then
    sfx(6)
    level+=1
    game_state="level_up"
    level_cd=120
    return
  end
  if pl.hp<=0 then game_state="over" over_music_pending=true over_music_start_pat=stat(24) end
end

function _draw()
  if game_state=="title" then draw_title() pal(14,143,1) return end
  if game_state=="expo"  then draw_expo()  pal(14,143,1) return end
  cls(0)
  local wy=wobble>0 and flr(sin(wobble*0.5)*2) or 0
  camera(cam_x,wy)
  draw_bg()
  draw_entities()
  draw_floaters()
  camera(0,0)
  draw_hud()
  if game_state=="over" then draw_gameover() end
  if game_state=="level_up" then draw_level_up() end
  pal(14,143,1)
end

__gfx__
004440000044400000444000004440000024200000242000000000ff2200ff140070000000bbb0000000000000000000001c1600000000000000000000000000
04fff40004fff40004fff40004fff40002fff20002fff2000000000022220ff400b333000bb00000000000000000000001111110000001910000000000000000
0fff1f000fff1f000fff1f000fff1f000fff5f000fff5f00000000111120ff14003003000b000000000000000000000011111111000009b90000000000000000
0ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000000111121200000000333000bb00000820000000000000000010000000009190000000000000000
00777000007770000077700000777000008880000088800000111111111fff000000000000bbbb00082828000000e0000001000000000d9d0000000000000000
077f7000077f7000077f7000077f7000082f2000082f20001100001022000000000000000bbbbbb00000000000eee00000010400000000900000000000000000
0777ff000777f7000777ff00077f77000289800002898000100141000000000000000000bbbbbbbb000000000000e00000001600000000d00000000000000000
077777000777770007777ff0077777000828200008282000001100000000000000000000bbbbbbbb000000000000000000000000000000000000000000000000
0444d0000444d000000000000444d000024240000242400000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111000011110000000000001111000042420000424200000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111000011111000000000001111000024240000242400000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111000111011000000000001111000044444000444400000000000000000000000000000000000000000000000000000000000000000000000000000000000
0011d000110001000000000001111000444044000044400000000000000000000000000000000000000000000000000000000000000000000000000000000000
001d10001000014000000000410d1000440004000044400000000000000000000000000000000000000000000000000000000000000000000000000000000000
00444000440004000000000004044000100001100141100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000110001000110100000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbb1111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaa2222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99993333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88884444070070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffff5555077770070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeee6666717177700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddd7777077777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccc0000006070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaa000000000000000000000000000000000000
000000000000000000000000000aaaaa00000000000000aaa0000aaaaa000aa0aaaa0000aaaaa00000000000aaaa000000000000000000000000000000000000
000000000000000000000000aaaaaaaa000000000000aaaaaa00aaaaaaa00aaaaaaaa00aaaaaaa0000000000aaaa000000000000000000000000000000000000
000000000000000000aa0000aaaaaaaa000aaaaa000aaaaaaa00aaaaaaa00aaaaaaaa00aaaaaaa0000000aaaaaaa000000000000000000000000000000000000
000000000000000000aaa000aaaaaa00000aaaaa00aaaaaaaa000000aaa00aaa00aaa000000aaa0000000aaaaaaa000aaa000000000000000000000000000000
00000000000000000aaaaa00aaaa000000aaaa0000aaa00000000aaaaaa00aaa00aaa000aaaaaa00000aaaaaaaa000aaaaa00000000000000000000000000000
00000000000000000aaaa000aaaa00aa00aaa00000aaa0000000aaaaaaa00aaa00aaa00aaaaaaa00000aaaa0aaa00aaaaaaa0000000000000000000000000000
000000000000000000af0000aaaaaaaa00aaaaaa00aaa000000aaaa0aaa00aaa00aaa0aaaa0aaa00000aaa00aaa00aaa00aa0000000000000000000000000000
0000000000000000000000000aaaaaaa00aaaaaaa0aaaa00000aaa00aaa00aaaaaaaa0aaa00aaa00000aaa00aaa00aaa00aa0000000000000000000000000000
0000000000000000000aaa000aaaaaa0000aaaaaa0aaaaa0aa00aaaaaaa00aaaaaaaa0aaaaaaaa00000aaa00aaa00aaaaaaa0000000000000000000000000000
000000000000000000aaaa000aaaa000000000aaaa0aaaaaaa00aaaaaaaa0aaaaaaa000aaaaaaa00000aaaaaaaa0aaaaaaaa0000000000000000000000000000
0000000000000000000aaa000aaaa000000aaaaaa000aaaaaa000aaa0aa00aaa0aa00000aa00aa000000aaaaaaa00aaa00000000000000000000000000000000
0000000000000000000aaa000aaaaaaaaa0aaaaaa0000aaa0000000000000aaa000000000000000000000aaaaaa00aaaa0000000000000000000000000000000
0000000000000000000aaaa00aaaaaaaaa0aaaa0000000000000000000000aaa000000000000000000000000aaa000aaaaaa0000000000000000000000000000
0000000000000000000aaaa000aaaaaaa0000000000000000000000000000aaa0000000000000000000000000000000aaaa00000000000000000000000000000
0000000000000000000aaaa000aaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000aaa0000000000000000000888000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000888888888800000000000000000000000000000000000000088880000888800000000000000000000000000000000
00000000000000000000000000000000088888888888800000000000000000000000000000000000000888880008888880000000000000000000000000000000
00000000000000000000000000000000888888888888800000000000000000000000000000000000000888880008888880000000000000000000000000000000
00000000000000000000000000000008888888888888800000000000000088000080000008888000000888880000888880000000000000000000000000000000
00000880000000000000000000000008888888888880000888000000880888808888000088888880008888880000888800000000000000000000000000000000
00888880000000000000000000000008888888880000088888880088888888888888800088888888008888888800000000000000000000000000000000000000
08888880000000000000000000000008800888880000888888888008888888888888800088888888008888888808888000888000000000000000000000880000
88888880000000000008888800000000000888880000888888888008888888888888800088008888008888888808888808888088800000000000000000888800
08888880000000000888888880000000000888888008888888888808888888888888800000000888000888888808888008888888880000888880000008888800
08888888000000008888888888000000000088888008888008888808888088880888800088888888000888800008888008888888888008888888000008888800
08888888000000008888888888000000000088888008888000888808888088880888800088888888000888800008888008888888888008888888800008888000
00888888000000008888088888800000000088888008888000888808888088880888800888888888000888800008888008888888888088888888800088888000
00888888000000000000008888800000000088888008888000888808888088880888800888888888000888800008888008880088888000000888880088888000
00888888000000000000888888800000000088888008888000888808888088880888808888008888000888800008888088880088888000000888800088880000
00888888000000000088888888800000000088888008888000888808888088880888808888008888000888800088888088880088880000888888800888880000
00888888800000000888888888800000000088888008888008888808888088880888808888888888000888800088888088880088880888888888800888880000
00088888800000000888888888800000000008888008888888888808888088880888800888888888000888888088888088880088880888888888800888800000
00088888800000008888800888800000000008888800888888888008888088880888800888888888800888888088888088880888880888888888800888800000
00088888800000008888800888800000000008888800888888888008888008880888800088880888800888888088880088800888808888008888000888800000
00088888800000000888808888880000000008888800088888880000800000000000000000000080000088888088880088800888808888008888000888000000
00088888800008880888888888880000000008888800008888000000000000000000000000000000000000000088880088800888808888888888000000000000
00008888880888880888888888880000000008888000000000000000000000000000000000000000000000000000000088800888808888888888000000000000
00008888888888880088888888880000000000000000000000000000000000000000000000000000000000000000000000000888800888888888008880000000
00008888888888888088888088800000000000000000000000000000000000000000000000000000000000000000000000000000000088888888088888000000
00008888888888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008880088880000000
00000888888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080088880000000
00000888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008880000000
00000888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01010000080200a0300f03013030170501b0501e0502104024040250402604027040280302805027060240601e0401a0201805017050190501705015010140201303012050100500e0500d0500b0500a05008050
510200001d62324623276332b6432e6432e3432c3432934325343223431f3431d3431b3431a333173331533313333113330f3330f3330d3230c3230b323093230832308323073230632305313053130131301313
490100000c615126151462516625186251c63520635266352863528635266352463522635206351e6251a62518625166251462512625106250e6150c6150a6150861506615066150061500615006050060500605
510100000c0110e0110e011100111001112011140211602118021180211a0211a0211c0211c0211e021200312003122031220312203124041240412604126041260412804128041280412a0412a0412c0412c041
08010000105012655126511265212852128531285312854128541295512b5512b5512b5512b5612b5512b5512b5512b5512b5412b5312b5312b5312b5312b5312b5312b5312b5312b5312b5312b5112b5112b511
0101000005517095270c52710537115471354715547175471a5471c5471c5471c5471c5471a5471a547185471854717547175471753715537155371353711527105270e5170c5070950709507175071550713507
01070000133251f3252b3253732500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4904000015320163201732018320193201a3201b3201c3201d3201e3201f320203202132022320233202432025320263202732028320293202a3202c3202d3202f32030320323203332035320363203832039320
05100010000450002000115000450002500115000450002500045000250011500045000220011500045000250c0550c0450c0350c0250c0550c0450c0350c0250c0550c0450c0350c0250c0550c0450c0350c025
011000200c0432e405000052e205246150000516115000050c043000050000516115246150000516115000050c04316115000052e20524615000052e305000050c04300005000053a30524615000051610500005
011000200c0432e405000052e205246150000516115000050c043000050000516115246150000516115000050c04316115000052e20524615000052e305000050c04300005000053a30524615000051610500005
151000200c0450c0200c1150c0450c0250c1150c0450c0250c0450c0250c1150c0450c0220c1150c0450c0250c0450c0250c1150c0450c0200c1150c0450c0250c0450c0250c1150c0450c0220c1150c0450c020
590800201073210722107321072210732107221073210722107321072210732107221073210722107321072210732107221073210722107321072210732107221073210722107321072210732107221073210722
590800200c7220c7220c7320c7220c7220c7220c7220c7320c7220c7220c7320c7220c7220c7320c7220c7220c7320c7220c7220c7320c7220c7220c7320c7220c7220c7320c7220c7220c7320c7220c7220c732
05200020100361002210116100351002710116100321002711036110251111711036110221111311036110270c0360c0220c0170c0260c0320c0160c0250c0120c0370c0160c7270c0160c0320c0160c7250c017
491000003c6253c6213c6153c6253c6153c6213c6253c6153c6253c6253c6113c6253c6253c6113c6253c0053c6113c6253c6253c0053c6253c6113c6253c0053c6253c6253c6113c6253c6253c6113c0053c615
a51000200c5450c5200c1150c5450c5250c1150c5450c5250c5450c5250c1150c5450c5220c1150c5450c5250c5450c5250c1150c5450c5200c1150c5450c5250c5450c5250c1150c5450c5220c1150c5450c520
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01030000343402d340343402d34028340213401c34015340343402d34034340343402d340343402d34028340213401c34015340343402d34034340343402d340343402d34028340213401c340153401034009340
__music__
00 08494e4c
01 08090b4d
00 08090b4d
00 0809104d
02 0809104d
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
03 08494e4c

