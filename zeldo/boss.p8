pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
-- zeldo - alan morgan.

-------------------------
-- pico main
-------------------------
function _init()
	color(0)
	palt(0,false)
	srand(time())

	init_game()
	make_scenes()
	make_triggers()

	scene_init()
end

function _update()
	local prev_marker = marker

	if marker == "title" then
		title_update()
	else
		scene_update()
	end

	if prev_marker != marker then
		scene_init(prev_marker)
	end

	global_time=global_time+1 -- increment the clock
end

function _draw()
	scene_draw()
	draw_triggers() -- debugging
end













marker = "boss"  -- where you are in the story, start on title screen.
scene_actors = {}
draw_map_funcs = {}
triggers = {}


-----------------------------------
-- these are just in charge of creating the sprites that go in each scene.
-----------------------------------
function make_map()
	actors = {}

	gen_chest(8,8)
	gen_sword_stand(8, 28)
	gen_poe(57.5,10.5)
	gen_enemies()

	scene_actors["overworld"] = actors
	actors = {}
end

function make_hut(prev_marker)
	actors = {}

	gen_chest(offw + 1.5, 32 + 1.5)

	scene_actors["hut"] = actors
	actors = {}
end

function make_boss(prev_marker, x, y)
	actors = {}

	ganon = gen_ganondorf(offw + 16,3.5)

	scene_actors["boss"] = actors
	actors = {}
end

function make_scenes()
	make_map()
	make_hut()
	make_boss()
end

-- use right before changing the scene.
function save_scene()
	del(actors, pl)
	actors = {}
end

-- use when switching to a new scene.
-- x and y are the player's new coordinates.
function load_scene(scene_name, x, y)
	save_scene()
	actors = scene_actors[scene_name]

	if x != nil then pl.x = x end
	if y != nil then pl.y = y end
	view_update()

	add(actors, pl)
end

-- sets up the game and player, but not the various objects that are scene
-- specific.
function init_game()
	actors = {}
	pl = gen_link(8, 8)
	gen_grass()
end

-- gets called whenever the scene switches.
function scene_init(prev_marker)
	local x = 0
	local y = 0

	if marker == "boss" then
		x = offw + 16
		y = 30.5
	elseif marker == "overworld" then
		music(0)
		if prev_marker == "hut" then
			x = 8
			y = 5.5
		elseif prev_marker == "title" then -- temp else
			x = 8
			y = 5.5
		end
	elseif marker == "hut" then
		if prev_marker == "title" then
			pl.visible = true
			x = offw + 2.5
			y = 32 + 2

			tbox("ivan",  "hey, listen zeldo! princess lank is in trouble you gotta rescue her!")
			tbox("zeldo", "okie dokie. sounds fun!")
		elseif prev_marker == "overworld" then
			x = offw + 2.5
			y = 32 + 4.5
		end
	elseif marker == "title" then
		pl.visible = false
	end

	load_scene(marker, x, y)
end

function scene_draw()
	if marker == "title" then
		draw_title()
		return
	end

	if marker == "hut" then
		draw_map(offw, 32, 5, 5)
	elseif marker == "boss" then
		draw_map(offw, 0, 32, 32)
	elseif marker == "overworld" then
		draw_map(0, 0, offw, offh)
	end

	draw_things()
	draw_hearts()
	draw_power_orbs()

	if pl.alive == false then
		draw_game_over()
		draw_link_death()
	end

	draw_fairy()
	tbox_draw()
end

function scene_update()
	if not tbox_active() then
		map_update()
		trigger_update()
		view_update()
	else
		tbox_interact()
	end
end

-- triggers are boxes you collide with that can make events happen.
function make_trigger(name, x1, y1, x2, y2)
	triggers[name] = {box={x1=x1, y1=y1, x2=x2, y2=y2}, finished=false, func=function() end}
end

function make_triggers()
	-- trigger positions
	make_trigger("hut_enter", 7,    4.5,  9,    5.5)
	make_trigger("hut_exit",  97,   37,   100,  39)
	make_trigger("no_sword",  7,    10,   9,    12)
	make_trigger("gan_intro", 108,  1,    116,  9)

	-- trigger functions
	triggers["hut_enter"].func =
		function() marker="hut" end

	triggers["hut_exit"].func =
		function() marker="overworld" end

	triggers["no_sword"].func =
		function()
			tbox("ivan", "hey, listen! you don't have a sword yet! how can you save lank like this?")
			triggers["no_sword"].finished=true
		end

	triggers["gan_intro"].func =
		function()
			tbox("cannondwarf", "mwahahahahahahahahahaha. did you think you could defeat me?")
			triggers["gan_intro"].finished=true
		end
end

-- used for debugging purposes.
function draw_triggers()
	for k,v in pairs(triggers) do
		rect(v.box.x1*8 + offset_x(),
			  v.box.y1*8 + offset_y(),
			  v.box.x2*8 + offset_x(),
			  v.box.y2*8 + offset_y(), 10)
	end
end

function trigger_update()
	for k, v in pairs(triggers) do
		if not v.finished and is_pl_in_box(v.box) then
			v.func()
		end
	end
end

-- updates the view with the player's coordinates. call whenever the player
-- changes position.
function view_update()
	viewx = pl.x
	viewy = pl.y
end

function title_update()
	if btnp(4) then
		marker = "hut"
		sfx(30)
	end
end

actors = {} -- all actors in world.
offh = 16*4
offw = 16*6

viewx = 0
viewy = 0

power_orb_count = 0

global_time=0 -- the global timer of the game, used by text box functions
tbox_messages={} -- the array for keeping track of text box overflows

-- draws how many power orbs have been collected.
function draw_power_orbs()
	-- hearts on right of screen
	draw_to_screen(55, 0, 0)
	print(power_orb_count, 9, 1, 7)
end

function draw_map(x, y, w, h)
	cls(0)
	local offx = -pl.x*8+64
	local offy = -pl.y*8+64
	map(x, y, x * 8 + offx, y * 8 + offy, w, h)
end

function is_pl_in_box(box)
	return pl.x > box.x1 and pl.x < box.x2 and pl.y > box.y1 and pl.y < box.y2
end

-- relative to the actor a passed.
function is_pl_in_box_rel(a, x1, y1, x2, y2)
	local box = {x1=a.x+x1, y1=a.y+y1, x2=a.x+x2, y2=a.y+y2}
	return is_pl_in_box(box)
end

-- make an actors and add to global collection.
-- x,y means center of the actors, in map tiles (not pixels).
function make_actor(x, y)
	a={}

	-- if true, then this object cannot be moved by other objects.
	a.static=false

	-- if false, then you can walk through walls.
	a.solid=true

	-- if false, then you can go through other actors.
	-- but the hit function will still be called.
	a.touchable=true

	-- if true, then you can hurt other actors.
	-- but you can only hurt actors not on your team.
	a.hurt = false
	a.good = false
	a.bad  = false

	-- if false, then the draw function for the sprite is not called.
	a.visible=true

	-- position and speed.
	a.x = x
	a.y = y
	a.dx = 0
	a.dy = 0

	-- images
	a.spr = 16

	-- sprite width and sprite height used to get a correct offset.
	a.sw = 8
	a.sh = 8

	-- frame  = current frame
	-- frames = number of frames
	a.frame = 0
	a.frames=1

	-- every actor has a relative time.
	-- time is stopped when off the screen.
	a.t = 0

	-- if 0, then no friction. if 1, then lots of friction.
	a.inertia = 0.6

	-- if 1, then no loss of speed when you bounce.
	a.bounce  = .8

	-- if false, then object is removed from the actors.
	a.alive = true

	-- if true, then you are out of the main screen and the buffer.
	-- see is_in_bounds for buffer information.
	a.is_outside = false
	
	-- radius width and height
	-- .5 would be one block
	-- make it a bit smaller to fit through smaller holes
	a.w = 0.4
	a.h = 0.4
	
	-- draw with draw actor. it makes white transparent.
	-- called every frame as long as actor is alive
	a.draw = draw_actor

	-- called every frame as long as actor is alive
	a.move = function(self) end

	-- called if two actors are in bounds (not outside) and are touching each
	-- other.
	a.hit = function(other) end

	-- gets called if the actor is out of bounds.
	a.outside = function(self) end

	-- gets called right before the actor is deleted.
	a.destroy = function(self) end

	add(actors,a)
	
	return a
end

-- returns true if the coordinate is solid on the map.
function solid_on_map(x, y)
	local val=mget(x, y)
	return fget(val, 1)
end

-- returns true if the dimensions given touch a wall.
-- only works for dimensions smaller than .5 (1 tile big)
function solid_area(x,y,w,h)
	return 
		solid_on_map(x-w,y-h) or
		solid_on_map(x+w,y-h) or
		solid_on_map(x-w,y+h) or
		solid_on_map(x+w,y+h)
end

-- returns true if character is within the buffer.
-- the buffer is the bounds of the screen (16x16 tiles) plus 8 tiles.
-- so in all it is a 24x24 region.
function is_in_bounds(a)
	local left = pl.x - 16
	local right = pl.x + 16
	local top = pl.y - 16
	local bottom = pl.y + 16
	return a.x > left and a.x < right and a.y > top and a.y < bottom
end

-- updates the status of whether actors are out of bounds or not.
-- also calls the the outside function if
function update_outside()
	for a in all(actors) do
		a.is_outside = not is_in_bounds(a)
		if a.is_outside then
			a.outside(a)
		end
	end
end

-- returns the actor that was hit. will return nil if this actor is out of
-- bounds. won't check for actors that are out of bounds.
-- also does not work with overlapping actors.
function actor_collision(a, dx, dy)
	if a.is_outside then
		return nil
	end

	for a2 in all(actors) do
		if not a2.is_outside then
			local x=(a.x+dx) - a2.x
			local y=(a.y+dy) - a2.y
			if ((abs(x) < (a.w+a2.w)) and
				(abs(y) < (a.h+a2.h)))
			then 
				-- check if moving together
				if (dx != 0 and abs(x) <
						abs(a.x-a2.x)) then
					if a.touchable and a2.touchable then
						v=a.dx + a2.dy
						if not a.static then a.dx = v/2 end
						if not a2.static then a2.dx = v/2 end
					end
					return a2
				end
				
				if (dy != 0 and abs(y) <
								abs(a.y-a2.y)) then
					if a.touchable and a2.touchable then
						v=a.dy + a2.dy
						if not a.static then a.dy = v/2 end
						if not a2.static then a2.dy = v/2 end
					end
					return a2
				end
			end
		end
	end
	return nil
end

-- checks just walls
function touching_wall(a, dx, dy)
	return a.solid and solid_area(a.x+dx,a.y+dy, a.w,a.h)
end

-- calls the hit function for both actors, if the opposing actor can hurt
-- things.
function hurt_actors(a1,a2)
	if a2.hurt  then
		a1.hit(a2)
	end

	if a1.hurt then
		a2.hit(a1)
	end
end

-- a helper function for move_actor
-- returns the new speeds.
function move_actor_check(a, dx, dy)
	if not touching_wall(a, dx, dy) then
		local other = actor_collision(a, dx, dy) 
		if other != nil then
			hurt_actors(a,other)
			if other.touchable and a.touchable then
				dx *= -a.bounce
				dy *= -a.bounce
				-- sfx(2)
			else
				a.x += dx
				a.y += dy
			end
		else
			a.x += dx
			a.y += dy
		end
	else   
		-- otherwise bounce
		dx *= -a.bounce
		dy *= -a.bounce
		-- sfx(2)
	end

	return dx + dy
end

function move_actor(a)
	if a.is_outside then
		return
	end

	if a.move != nil then
		a.move(a)
	end

	a.dx = move_actor_check(a, a.dx, 0)
	a.dy = move_actor_check(a, 0, a.dy)

	-- apply inertia
	-- set dx,dy to zero if you
	-- don't want inertia

	a.dx *= a.inertia
	a.dy *= a.inertia
	
	-- advance one frame every
	-- time actors moves 1/4 of
	-- a tile
	
	a.frame += abs(a.dx) * 4
	a.frame += abs(a.dy) * 4
	a.frame %= a.frames

	a.t += 1
	
end

function control_player(pl)
	-- how fast to accelerate
	accel = .1
	-- move if no bomb/shield or sword.
	if not btn(4) and not btn(5) then
		if btn(0) then pl.dx -= accel end
		if btn(1) then pl.dx += accel end
		if btn(2) then pl.dy -= accel end
		if btn(3) then pl.dy += accel end
	elseif btn(5) then
		if pl.sword == nil then
			if btnp(0) then     pl.sword=gen_sword(pl.x, pl.y, 0, false)
			elseif btnp(1) then pl.sword=gen_sword(pl.x, pl.y, 1, false)
			elseif btnp(2) then pl.sword=gen_sword(pl.x, pl.y, 2, false)
			elseif btnp(3) then pl.sword=gen_sword(pl.x, pl.y, 3, false) end
		end
	end

	-- play a sound if moving
	-- (every 4 ticks)
	
	if (abs(pl.dx)+abs(pl.dy) > 0.1
					and (pl.t%4) == 0) then
		-- sfx(1)
	end
	
end

function gen_chest(x,y)
	local chest = make_actor(x,y)
	chest.spr=114
	chest.static=true
	chest.open=
		function()
			tbox("", "you opened a chest")
		end

	chest.move=
		function(self)
			local x1 = -self.w
			local x2 =  self.w
			local y1 =  self.h
			local y2 =  2.5*self.h

			if is_pl_in_box_rel(self, x1, x2, y1, y2)
			and btnp(4) and chest.spr != 115 then
				chest.spr=115
				chest.open()
			end
		end
	return chest
end

function gen_sword(x, y, dir, master)
	local time = 10
	local spd = .3
	local off = .5

	local dx = 0
	local dy = 0

	if dir == 0 then
		x -= off
		dx = -spd
	elseif dir == 1 then
		x += off
		dx = spd
	elseif dir == 2 then
		y -= off
		dy = -spd
	elseif dir == 3 then
		y += off
		dy = spd
	end

	local sword = make_actor(x, y)
	if dir == 0 or dir == 1 then
		sword.spr = 1
	else
		sword.spr = 0
	end

	if master == true then
		sword.spr+=43
	else
		sword.spr+=56
	end

	sword.dx = dx
	sword.dy = dy
	sword.w  = .5
	sword.h  = .5

	sword.solid = false
	sword.touchable = false
	sword.good = true
	sword.hurt = true
	sword.dir = dir
	sword.destroy =
		function(self)
			pl.sword = nil
		end

	sword.move =
		function(self)
			if self.t >= time then
				self.alive = false
			end
		end

	sword.draw =
		function(self)
			local fx = (self.dir == 0)
			local fy = (self.dir == 3)
			draw_actor(self, nil, nil, fx, fy, 15)
		end

	return sword
end

function offset_x()
	return -viewx * 8 + 64
end

function offset_y()
	return -viewy * 8 + 64
end

-- a utility function for drawing actors to the screen. auto offsets and
-- assumes white is the default background color.
function draw_actor(a, w, h, flip_x, flip_y, alt)
	if a.alive then
		local sx = (a.x * 8) + offset_x() - a.sw/2
		local sy = (a.y * 8) + offset_y() - a.sh/2

		if w == nil then w = 1 end
		if h == nil then h = 1 end
		if flip_x == nil then flip_x = false end
		if flip_y == nil then flip_y = false end
		if alt == nil then alt = 7 end

		palt(alt,true)
		spr(a.spr + a.frame, sx, sy, w, h, flip_x, flip_y)
		palt(alt,false)
	end
end

function dice_roll(sides)
	return flr(rnd(sides)) == 1
end

-- if given a tile number that is blank, this will return the other version of
-- that tile.
function variety_tile(tile)
	if tile > 0 and tile < 10 then
		if tile % 3 == 0 then
			return tile - 1
		elseif tile + 1 % 3 == 0 then
			return tile + 1
		end
	end

	return tile
end

-- generates the grass tile randomly.
function gen_grass()
	-- go through each tile in 
	for i=1, offw - 2, 1 do
		for j=1, offh - 2, 1 do
			local tile = mget(i,j)
			local new_tile = variety_tile(tile)
			if new_tile != tile and dice_roll(10) then
				mset(i,j,new_tile)
			end
		end
	end
end

-- draws map, relative to player
function draw_overworld()
	cls(3)
	local offx = -pl.x*8+64
	local offy = -pl.y*8+64

	map(0,0,-pl.x*8+64,-pl.y*8+64,offw,offh)

	-- rest is for wrapping.
	for i=1, 3, 1 do
		-- left part screen
		map(0, 0, -i*8*2 + offx, offy, 2, offh)

		-- top part screen
		map(0, 0, offx, -i*8*2 + offy, offw, 2)
	end

	for i=0, 2, 1 do
		-- right part screen
		map(offw - 2, 0, offw*8 + i*8*2 + offx, offy, 2, offh)

		-- bottom part screen
		map(0, offh - 2, offx, i*8*2 + offh*8 + offy, offw, 2)
	end

	for i=0, 2, 1 do
		for j=0, 2, 1 do
			-- bl corner
			map(0, offh-2, i*16 - 3*16 + offx, j*16 + offh*8 + offy, 2, 2)

			-- br corner
			map(offw-2, offh-2, i*16 + offw*8 + offx, j*16 + offh*8 + offy, 2, 2)

			-- tr corner
			map(offw-2, 0, i*16 + offw*8 + offx, j*16 - 3*16 + offy, 2, 2)

			-- tl corner
			map(0, 0, i*16 - 3*16 + offx, j*16 - 3*16 + offy, 2, 2)
		end
	end
end

------------------
-- game control!!!
------------------
function garbage_collection()
	foreach(actors,
		function(a)
			if a.alive == false then
				a.destroy()
				del(actors, a)
			end
		end)
end

function map_update()
	if pl.alive then
		foreach(actors, move_actor)
	end

	-- call outside and destroy functions
	update_outside()
	garbage_collection()
end

local rnd_x = 0
local rnd_y = 1
function draw_title()
	cls(0)
	local col = 10 --global_time / 60 % 16
	if global_time % 120 == 0 then
		rnd_x = flr(rnd(6))
		rnd_y = flr(rnd(4))
	end

	viewx = 16 * rnd_x + 8
	viewy = 16 * rnd_y + 8

	map(viewx - 8, viewy - 8, 0,0,16,16)

	draw_things()

	-- draw the title
	for i=0,7,1 do
		draw_to_screen(72+i,4*8+i*8,7*8)
		draw_to_screen(88+i,4*8+i*8,8*8)
	end

	print("the story of", 41, 50, col)
	if global_time % 30 < 20 then
		print("press z to start", 32, 72, 7)
	end
end

function draw_things()
	for a in all(actors) do
		if a.visible then
			a.draw(a)
		end
	end
end

function draw_to_screen(id, x, y)
	palt(7,true)
	spr(id, x, y)
	palt(7,false)
end

fairy_counter=0
fairy_clockwise=false
function draw_fairy()
	local x = 64 + 8 * cos(fairy_counter) - 4
	local y = 64 + 8 * sin(fairy_counter) - 4
	draw_to_screen(107, x, y)

	if time() % 20 == 0 then
		fairy_clockwise=not fairy_clockwise
	end

	if fairy_clockwise then
		fairy_counter -= rnd(.01)
	else
		fairy_counter += rnd(.01)
	end
		
	if fairy_counter > 1 then
		fairy_counter -= 1
	elseif fairy_counter < 0 then
		fairy_counter += 1
	end
end

death_link_counter=0
function draw_link_death()
	local yoff = sin(time() / 4 + .2)
	local ind = 104

	death_link_counter += 1
		if death_link_counter > 7*30 then
			ind = 102
		elseif death_link_counter > 5*30 then
			ind = 103
		end

	draw_to_screen(ind, 128/2 - 4, yoff + 128/2 - 4)
end

function gen_sword_stand(x, y)
	-- create the sword first
	local sword = make_actor(x, y-1)
	sword.spr = 16
	sword.static = false
	sword.touchable = false
	sword.h = .4
	sword.draw=
		function(a)
			-- 0 is the black bacground.
			draw_actor(a, 1, 2, nil, nil, 0)
		end

	-- now create the stand
	local stand = make_actor(x,y)
	stand.spr = 27
	stand.static = true
	stand.w = 1.0
	stand.sw = 16
	stand.draw=
		function(a)
			-- 0 is the black bacground.
			draw_actor(a, 2, 1, nil, nil, 0)
		end
end

function gen_link(x, y)
	local pl = make_actor(x,y)
	pl.spr = 104
	pl.frames = 3
	pl.solid = true
	pl.move = control_player
	pl.hearts = 3
	pl.hurt=true
	pl.good=true
	pl.bounce=.3
	pl.sword=nil

	pl.hit=function(other)
		if other.bad then
			if pl.hearts > 0 then
				pl.hearts = pl.hearts - 1
			end
	
			if pl.hearts == 0 then
				pl.alive = false
			end
		end
	end

	pl.destroy=function(other)
		music(14)
	end

	return pl
end

-----------------
-- enemy creation
-----------------
function gen_enemies()
	for i=0, 25, 1 do
		local id = flr(rnd(3))
		local x = rnd(124)+1.5
		local y = rnd(60) +1.5
		if id == 0 then
			gen_octorok(x, y)
		elseif id == 1 then
			gen_deku(x, y)
		elseif id == 2 then
			gen_skelly(x, y)
		end
	end
end

function gen_power_orb(x, y)
	local orb = make_actor(x, y)
	orb.spr = 55
	orb.touchable = false
	-- use a closure!
	orb.hit=
		function(other)
			if other == pl then
				orb.alive = false
			end
		end

	orb.destroy =
		function(self)
			power_orb_count += 1
		end
	return orb
end

function gen_enemy(x, y)
	local bad = make_actor(x, y)
	bad.spr = 1
	bad.dx=0
	bad.dy=0
	bad.inertia=.5
	bad.hurt=true
	bad.bad=true
	bad.hearts=0
	bad.radx = 5
	bad.rady = 5
	bad.solid=true
	bad.move = function(self) end
	bad.hit=
		function(other)
			if other.good then
				bad.alive = false
			end
		end

	bad.destroy =
		function(self)
			orb = gen_power_orb(bad.x, bad.y)
			orb.dx = bad.dx*3
			orb.dy = bad.dy*3
		end

	-- enemy faces player, assumes sprite is facing left
	bad.draw =
		function(a)
			draw_actor(a, nil, nil, a.x < pl.x, nil)
		end

	return bad
end

function gen_dark_link(x, y)
	local bad = gen_enemy(x, y)
	bad.spr = 124
	bad.move = move_clockwise
	return bad
end

function gen_octorok(x, y)
	local bad = gen_enemy(x, y)
	bad.spr = 86
	return bad
end

function gen_poe(x, y)
	local bad = gen_enemy(x, y)
	bad.spr = 116
	bad.solid = false
	bad.touchable = false
	bad.move = move_counter
	bad.draw =
		function(a)
			draw_actor(a, nil, nil, a.dx > 0, nil)
		end
	return bad
end

function gen_deku_bullet(x,y,dx,dy)
	bad = gen_enemy(x,y)
	bad.spr = 71
	bad.dx = dx
	bad.dy = dy
	bad.inertia=1
	bad.solid=false
	bad.touchable=false
	bad.destroy=function(self) end

	-- die if the bullet is out of bounds.
	bad.outside=
		function(a)
			a.alive = false
		end

	-- rotate the bullet
	bad.draw=
		function(a)
			if a.t % 40 < 10 then
				draw_actor(a, nil, nil, false, false)
			elseif a.t % 30 < 10 then
				draw_actor(a, nil, nil, false, true)
			elseif a.t % 20 < 10 then
				draw_actor(a, nil, nil, true, true)
			elseif a.t % 10 < 10 then
				draw_actor(a, nil, nil, true, false)
			end
		end
	
	return bad
end

function gen_deku(x, y)
	local bad = gen_enemy(x, y)
	bad.spr = 70

	-- deku shoots every so often.
	bad.move =
		function(a)
			if a.t % 60 == 0 then
				local dx = -.4
				if a.x < pl.x then
					dx = .4
				end
				gen_deku_bullet(a.x,a.y,dx,0)
			end
		end

	return bad
end

function gen_skelly(x, y)
	local bad = gen_enemy(x, y)
	bad.spr = 68
	bad.move = move_to_player
	return bad
end

function gen_ganondorf(x, y)
	local bad = gen_enemy(x, y)
	bad.spr = 109
	bad.move = function(self) end
	bad.hit = function(self) end
	return bad
end

-- draws the amount of hearts link currently has.
function draw_hearts()
	-- hearts on right of screen
	for i=0, pl.hearts-1, 1 do
		draw_to_screen(35, 128-8*(i+1), 0)
	end
end

-----------------
-- movement functions
-----------------
function move_clockwise(a)
	local slow = 4*30
	a.dx = a.radx * cos(a.t/slow) / 30
	a.dy = a.rady * sin(a.t/slow) / 30
end

function move_counter(a)
	local slow = 4*30
	a.dx = a.radx * cos(-a.t/slow) / 30
	a.dy = a.rady * sin(-a.t/slow) / 30
end

function move_vertical(a)
	local slow = 4*30
	a.dy = a.rady * sin(a.t / slow) / 30
end

function move_horizontal(a)
	local slow = 4*30
	a.dx = a.radx * cos(a.t / slow) / 30
end

function move_to_player(a)
	local slow = 2
	local ang = atan2(pl.x - a.x, pl.y - a.y)
	a.dx = a.radx * cos(ang) / 30 / slow
	a.dy = a.rady * sin(ang) / 30 / slow
end

function move_from_player(a)
	local slow = 2
	local ang = atan2(a.x - pl.x, a.y - pl.y)
	a.dx = a.radx * cos(ang) / 30 / slow
	a.dy = a.rady * sin(ang) / 30 / slow
end

-- fades the game to black then prints game over.
game_over_timer = 5
game_over_fadein = 3
function draw_game_over()

	local yoff = sin(time() / 8)
	local fade_ind=58
	if game_over_timer > 0 then
		if time() % 1 == 0 then
			game_over_timer -= 1
		end
	elseif game_over_timer == 0 and game_over_fadein > 0 then
		if time() % 1 == 0 then
			game_over_fadein -= 1
		end
	end

	for i=0,120,8 do
		for j=0,120,8 do
			draw_to_screen(fade_ind+game_over_timer, i, j)
		end
	end

	if game_over_fadein <= 2 then
		print("game over", 46, 47+yoff, 7 - game_over_fadein)
		print("reset cart to play again", 16, 77+yoff, 7 - game_over_fadein)
	end

end

------------------------------------------------------------------------------
-- text box implementation, taken from https://github.com/jessemillar/pico-8
-- fixed bugs for this game though.
------------------------------------------------------------------------------
-- turns a long word into a list of words with each one ending in a dash except
-- the last one. this function assumes the parameter is a word (no spaces).
function break_up_long_word(word_list, word, max_len)
	local ind = 0

	local substr = ""
	while ind < #word do
		if #word <= ind + max_len then
			substr = sub(word, ind, ind+max_len)
		else
			substr = sub(word, ind, ind+max_len - 1).."-"
		end

		add(word_list, substr)
		ind += max_len
	end

	return word_list
end

function words_to_list(str, line_len)
	-- convert the message to an array of words.
	local collect_word = ""
	local words = {}
	for i=0, #str, 1 do
		local cur_char = sub(str, i, i)

		-- if we hit a space and our collection is not empty.
		if cur_char == " " and #collect_word > 0 then
			words = break_up_long_word(words, collect_word, line_len)
			collect_word = ""

		-- if we didn't hit a space and our collection is not empty.
		elseif cur_char != " " then
			collect_word = collect_word..cur_char
		end
	end

	if #collect_word > 0 then
		words = break_up_long_word(words, collect_word, line_len)
	end

	return words
end

function words_to_lines(words, line_len)
	-- now that we have a list of the words, add the lines.
	local cur_line = ""
	local first = 0
	local line_list = {}
	for word in all(words) do
		-- we can't fit the next word on this line, so we will push this line and
		-- start a new line.
		if #cur_line + #word + first > line_len then
			add(line_list, cur_line)
			cur_line = ""
			first = 0
		end

		if first == 1 then cur_line = cur_line.." " end
		cur_line = cur_line..word

		if first == 0 then
			first = 1
		end
	end

	if #cur_line > 0 then
		add(line_list, cur_line)
	end

	return line_list
end

-- add a new text box
function tbox(speaker, message)
	local line_len=26

	-- if there are an odd number of lines.
	if #tbox_messages%2==1 then -- add an empty line as a second line to the previous dialogue.
		tbox_line(speaker, "")
	end

	local words = words_to_list(message, line_len)
	local lines = words_to_lines(words, line_len)

	for l in all(lines) do
		tbox_line(speaker, l)
	end
end

-- a utility function for easily adding a line to the messages array
function tbox_line(speaker, l)
	local line={speaker=speaker, line=l, animation=0}
	add(tbox_messages, line)
end

-- check for button presses so we can clear text box messages
function tbox_interact()
	if btnp(4) and #tbox_messages>0 then
		-- sfx(30) -- play a sound effect

		if #tbox_messages>1 then
			del(tbox_messages, tbox_messages[1])
		end

		del(tbox_messages, tbox_messages[1])
	end
end

-- check if a text box is currently visible (useful if the dialogue clear button is used for other actions as well)
function tbox_active()
	if #tbox_messages>0 then
		return true
	else
		return false
	end
end

-- draw the text boxes (if any)
function tbox_draw()
	if #tbox_messages>0 then -- only draw if there are messages
		rectfill(3, 103, 124, 123, 7) -- draw border rectangle
		rectfill(5, 106, 122, 121, 1) -- draw fill rectangle
		line(5, 105, 122, 105, 6) -- draw top border shadow 
		line(3, 124, 124, 124, 6) -- draw bottom border shadow 

		-- draw the speaker portrait
		if #tbox_messages[1].speaker>0 then
			local speaker_width=#tbox_messages[1].speaker*4

			if speaker_width>115 then
				speaker_width=115
			end

			rectfill(3, 96, speaker_width+9, 102, 7) -- draw border rectangle
			rectfill(5, 99, speaker_width+7, 105, 1) -- draw fill rectangle
			line(5, 98, speaker_width+7, 98, 6) -- draw top border shadow 

			print(sub(tbox_messages[1].speaker, 0, 28), 7, 101, 7)
		end

		-- print the message
		if tbox_messages[1] != nil and tbox_messages[1].animation<#tbox_messages[1].line then
			sfx(0)
			tbox_messages[1].animation+=1
		elseif tbox_messages[2] != nil and tbox_messages[2].animation<#tbox_messages[2].line then
			sfx(0)
			tbox_messages[2].animation+=1
		end
			
		print(sub(tbox_messages[1].line, 0, tbox_messages[1].animation), 7, 108, 7) 
		if #tbox_messages>1 then -- only draw a second line if one exist
			print(sub(tbox_messages[2].line, 0, tbox_messages[2].animation), 7, 115, 7) 
		end
		
		-- draw and animate the arrow
		palt(0,true)
		if global_time%10<5 then
			spr(48, 116, 116)
		else
			spr(48, 116, 117)
		end
		palt(0,false)
	end
end




__gfx__
00000000330000333333333333333333555555555d55555555555555400004445445455444444444000000000221022102110211444422222222444422442422
000000003053350333b3bb333333333355666655d555555d55555555006660044454445444444444052222500022000202220222444444444444444422442422
00700700053333503b3b3b3333333333566666655555555555555555066555044445444444444444022d22200000000000000000222444444444422222442422
00077000033333303333333333333333565555655555555555555555066654504445544544444444022ddd202102210221021102222222222222222222442422
0007700003333330333333333333333356666665d5d555d55555555506555550544444444444444402ddd2202200220022022202222222222222222222442422
0070070003333330b33bb3b3333333335655656555d55555555555550565454045444454444444440222d2200000000000000000222444444444422222442422
00000000053333503b3b3b3b33333333566666655555555d55555555005554404554455444444444052222500021002102110221444444444444444422442422
00000000300440033333333333333333555555555555d55d55555555400000004454544444444444000000000000000000000000444422222222444422442422
00055000000000000000000077777777551cccccccccccc155555555555555557777777000007777500550050000000000000000300000000000000340000004
000450000d6d566d66d566d000000000551cccccccccccc135353535454545457000770066600777500550050000000000000000001111111111110000666600
000450000d6d566d66d566d006666660511cccccccccccc155555555555555557060000666660777000000000000555dd5550000011111111111111006666660
000110000d6d566d66d566d00605656011cccccccccccc1153535353545454540666666655560007055000550005dd6776dd5000044444111144444006666660
011991100dd5556d6d5556d0066666601ccccccccccccc1535353535454545450665555555556600055000550555555555555550044444444444444008666680
1dd19dd10d6d566d66d566d0065605601ccccccccccccc153333333344444444065555555555556000000000566766d99d667665033994444449933008888880
d006700d0d6d566d66d566d00666666011cccccccccccc1153535353545454540655555655566550550055005d666d9119d666d5039999999999993008888880
000670000d6d566d66d566d00000000051ccccccccccccc133333333444444440655556455566450000000005dd6d9a99a9d6dd5039999999999993008888880
000670000d6d566d66d566d077777777331cccccccccccc1cccccccc54454454065555555555455000000000ffff6fffffffffff039990000009993008888880
000670000d6d566d66d566d072277227331cccccccccccc1cccccccc54454454065555555555555004444440fff676fff11fffff039990000009993008888880
000670000d6d566d66d566d028800882311cccccccccccc1cccccccc54454454005555555555556004499990fff676fffdffffff039900000000993008888880
000670000dd5556d6d5556d02888888211cccccccccccc11cccccccc54454454700455555555564004499440fff676ff4d66666f039900000000993008888880
000670000dd5556d6d5556d0728888271ccccccccccccc14cccccccc54454454700444566555565004499440fff676ff09777776039900000000993008888880
000670000d6d566d66d566d0702882071ccccccccccccc14cccccccc54454454770000444455545009999440f1f676f14d66666f039900000000993040000004
000670000d6d566d66d566d07702207711cccccccccccc11cccccccc54454454777770000044440004444440f1dd9dd1fdffffff033300000000333044444444
000070000d6d566d66d566d07777777731ccccccccccccc1cccccccc54454454777777007000000700000000fff404fff11fffff000000000000000044444444
777770000d6d566d66d566d02888e9aaaaaaaaaaaa9e88827777557777777777ffff5fffffffffff000000000005000050575005757775077777770777777757
077700000d6d566d66d566d0228e99eaaaaaaaaaae99e8227705507777000077fff575fff11fffff000000000000000550505007757075077770775777757777
007000000d6d566d66d566d02888e9aaaaaaaaaaaa9e888270151107705cc507fff575fffdffffff000000000000500055507500777077507775777077777775
000000000dd5556d6d5556d0228e99eaaaaaaaaaae99e8227011110770c66c07fff575ff2d55555f000000005050000075700500777507507777077577775777
000000000d6d566d66d566d02888e9aaaaaaaaaaaa9e88827011110770c66c07fff575ff0d777775000000000000000005000550070507750707577757577777
000000000d6d566d66d566d0228e99eaaaaaaaaaae99e82270111107705cc507f1f575f12d55555f000000000500050007050750070757755757777777777777
000000000d6d566d66d566d02888e9aaaaaaaaaaaa9e88827700007777000077f1ddddd1fdffffff000000000000000000050055505750777077707775777577
000000000000000000000000228e99eaaaaaaaaaae99e8227777777777777777fff202fff11fffff000000000000005000055075505770777577757777777777
005777755777750000000000000000006655557777944977773b3b37777777770000000000000000000000000000777777770000000000777777700000007777
05475574470674500606060606060600650660577744447773b3b3b3777707770eeeeeeeeeeeee0eeeeeeee00ee0777777770eeeeeeee00777770eeeeeee0777
0547777447777450065656565656565065666657722222277b35353b7700407700888888888888088888888e0880777777770888888888007770888888888077
05475074475574500656565656565650675665777288882704559553704455077000000088208008800008880880777007770880000088800708880000088807
00566664466665000656565656565650075555777222222704445547705544077777770882080708807770000880770990770880777708880008800777008807
555555555555555506d656d656d656d0055065507755554777744447770400777777708820807708800077770880770aa0770880777770888088807777708880
544444444444444506d6d6d6d6d6d6d0770650777755554777544457777077777777088208077708888007770880700550070880777770888088807777708880
454545454545454406d6d6d6d6d6d6d07440644777077047e82e82e877777777777088208077770888880077088009a55a900880777770888088807777708880
457575757575757406d6d6dadad6d6d0777777777777775777722227777777777708820807777708822880770880099009900880777770888088807777708880
46767676767676740656d95ada56d65075000077777777577728e882777777777088208077777708800000770880000000000880777770882028807777708820
467676767676767406565acf5c56565070aa880777777757772988e2777777770882080777777708807777770880777777770880777708820002800777008207
444444444444444406565a5f5f56565077005807777777572e888882777777770820800000000708800000070880000000000880000088200702880000088207
45454545454545440656595e5e56565077770a07777776d62888e882777777770288888888882008888888800888888888820888888882007770288888882077
45656565656565640656565e5e56565077770a0777777767777882e2777777770222222222222202222222220222222222200222222220077777022222220777
4767676767676764060606090906060077777057777777677e822887777777770000000000000000000000000000000000000000000000777777700000007777
47676767676767640000000000000000777777777777777782272e78777777777777777777777777777777777777777777777777777777777777777777777777
700060077777777706d6d6d6d6d6d6d000000000000000007773b77773bb337773bb337773bb337773bb33777777777777288277772882770000000000000000
07667670777777770656d656d656d650060606060606060077733bb7333333773333335733333357333333577777777778822887788228870000000000000000
066070607777777706565656565656500656565656565650773333333533335735cffc7735cffc7735cffc77777dd77772d55d27722222270000000000000000
600670067777777706565656565656500656565656565650773fc33357cffc7757ffff7757ffff7757ffff7777dccd7770555507408228040000000000000000
67777666777777770656565656565650065656565656565074b4ff3777ffff774b3345b44b334547743345b4771cc17742000024420000240000000000000000
0600706077777777065656565656565006d656d656d656d07433ffc74b4453b47744537777445377774453777771177770222207702222070000000000000000
0760767077777777060606060606060006d6d6d6d6d6d6d0743334f7774334777753337777533377775333777777777777000077770000770000000000000000
7066600777777777000000000000000006d6d6d6d6d6d6d077777777777777777747747777777477774777777777777777077077770770770000000000000000
0000000000000000700000077777777777666677777777777777777777777777779aaa7777777777000000000000000075665577000000000000000000000000
000000000000000000444400000000007500005777777777777777777777777779aa9aa777777777000000000000000055555507000000000000000000000000
0000555dd5550000044444400555555070c00c077777777777777777777777777acffca777777777000000000000000050266277000000000000000000000000
0005dd6776dd5000000aa00000000000700000077777777777777777777777777affffa777777777000000000000000007666677000000000000000000000000
055555555555555004499440044994407705507777777777777777777777777779eeee97777777770000000000000000d655d06d000000000000000000000000
566766d99d6676650e4444e00e4444e00000000077777777777777777777777777eeee7777777777000000000000000077dd0577000000000000000000000000
5d666d9119d666d502eeee2002eeee20aa000d777777777777777777777777777699996777777777000000000000000077055577000000000000000000000000
5dd6d9a99a9d6dd50000000000000000aad0ddd77777777777777777777777777747747777777777000000000000000077d77d77000000000000000000000000
10103030303030303030303030301010101010101010101010303030303010101010101030303030303030303030101010303030303030303030303030304262
6252909090909090909090909090d0d0d0d0909090909090909090909090e0e0a2a2a2a2a2000000000000000000000000000000000000000000000000000000
10103030303030303030303030301010101010101010101010303030303010101010101030303030303030303030303030303030303030303030303030304262
6252909090909090909090909090d0d0d0d0909090909090909090909090e0e0a29090f1a2000000000000000000000000000000000000000000000000000000
10103030303030303030303030301010101010101010101010303030303010101010101030303030303030303030303030303030303030303030303030304262
6252909090909090909090909090d0d0d0d0909090909090909090909090e0e0a29090f2a2000000000000000000000000000000000000000000000000000000
10103030303030303030303030301010101010101010101030303030303010101010101030303030303030303030303030303030303030303030303030304262
6252909090909090909090909090d0d0d0d0909090909090909090909090e0e0a2909090a2000000000000000000000000000000000000000000000000000000
10103030303030303030303030301010101010101010103030303030303010101010101030303030303030303030303030303030303030303030303030304262
6252909090909090909090909090d0d0d0d0909090909090909090909090e0e0a2a290a2a2000000000000000000000000000000000000000000000000000000
10103030303030303030303030301010101010101030303030303030303010101010101030303030303030303030303030303030303030303030303030304262
6252909070909090909090909090d0d0d0d0909090909090909090909090e0e00000000000000000000000000000000000000000000000000000000000000000
10103030303030303030303030301010101010303030303030303030303010101010101030303030303030303010101010103030303030303030303030304262
6252909090909090909090909090d0d0d0d0909090909090909090909090e0e00000000000000000000000000000000000000000000000000000000000000000
10103030303030303030303030301010101030303030303030303030301010101010101030303030303030301010101010101030303030303030303030304262
6252909090909090909090909090d0d0d0d0909090909090909090909090e0e00000000000000000000000000000000000000000000000000000000000000000
10103030303030303030303030301010101030303030303030303030301010101010101030303030303030301010101010101030303030303030303030304262
6252909090909090909090909090d0d0d0d0909090909090909090709090e0e00000000000000000000000000000000000000000000000000000000000000000
10103030303030303030303030301010101030303030303030303030101010101010101030303030303030301010101010101030303030303030303030304262
6252909090909090909090909090d0d0d0d0909090909090909090909090e0e00000000000000000000000000000000000000000000000000000000000000000
10103030303030303030303030301010101030303030303030303010101010101010101030303030303030301010101010101030303030303030303030304262
6252909090909090909090909090d0d0d0d0909090909090909090909090e0e00000000000000000000000000000000000000000000000000000000000000000
10103030303030303030303030101010101010303030303030101010101010101010101030303030303030301010101010101030303030303030303030304262
6252909090909090909090909090d0d0d0d0909090909090909090909090e0e00000000000000000000000000000000000000000000000000000000000000000
10103030303030303030303030101010101010303030303010101010101010101010101030303030303030303010101010103030303030303030303030304262
6252909090909090909090909090d0d0d0d0909090909090909090909090e0e00000000000000000000000000000000000000000000000000000000000000000
10103030303030303030303030101010101010303030303030101010101010101010101010303030303030303030303030303030303030303030303030304262
6252909090909090909090909090d0d0d0d0909090909090909090909090e0e00000000000000000000000000000000000000000000000000000000000000000
10103030303030303030303030101010101010303030303030303010101010101010101010303030303030303030303030303030303030303030303030304262
6252909090909090909090909090d0d0d0d0909090909090909090909090e0e00000000000000000000000000000000000000000000000000000000000000000
10103030303030303030303030101010101010303030303030303030101010101010101010103030303030303030303030303030303030303030303030304262
6252909090909090909090909090d0d0d0d0909090909090909090909090e0e00000000000000000000000000000000000000000000000000000000000000000
10103030303030303030303030301010101030303030303030303030301010101010101010103030303030303030303030303030303030303030303030304262
625290909090909090909090909090909090909090909090909090909090e0e00000000000000000000000000000000000000000000000070000000000000700
10103030303030303030303030303030303030303030303030303030301010101010101010103030303030303030303030303030303030303030303030304262
625290909090909090909090909090909090909090909090909090909090e0e00000000000000000000000000000000007000000000000000700000000000007
10103030303030303030303030303030303030303030303030303030303010101010101010101010101010303030303030303030101010101030303030304262
625290909090909090909070909090909090909090909090909090909090e0e00000000000000000000000000000000000070000000000000000000000000000
10103030303030303030303030303030303030303030303030303030303010101010101010101010101010103030303030303010101010101010303030304262
625290909090909090909090909090909090909090909090909090909090e0e00000000000000000000000000000000000000000000000000000000000000000
10103030303030303030303030303030303030303030303030303030303010101010101010101010101010103030303030303010101010101010303030304262
625290909090909090909090909090909090909090909090909090909090e0e00000000000000000000000000000000000000000000000000000000000000000
10103030303030303030303030303030303030303030303030303030303010101010101010101010101010103030303030303010101010101010303030304262
625290909090909090909090909090909090909090909090909090909090e0e00000000000000700000000070000000000000000000000000702000000000007
10103030303030303030303030303030303030303030303030303030303010101010101010101010101010103030303030303010101010101010303030304262
625290909090909090909090909090909090909090909090909090909090e0e00000000000000002000000000200000000000200000000070000020000000700
10101030303030303030303030303030303030303030303030303030303010101010101010101010101010103030303030303010101010101010303030304262
625290909090909090909090909090909090909070909090909090909090e0e00000000000000000000000000000000000000000000000000000000000000000
10101030303030303030303030303030303030303030303030303030303010101010101010101010101010303030303030303030101010101030303030304262
625290909090909090909090909090909090909090909090909090909090e0e00000000000000000000000000000000000000000000000000000000000000000
10101010303030303030303030303030303030303030303030303030301010101010101010103030303030303030303030303030303030303030303030304262
625290909090907090909090909090909090909090909090909090909090e0e00000000000000000000000000000000000000000000000000000000000000000
10101010103030303030303030303030303030303030303030303030301010101010101010303030303030303030303030303030303030303030303030104262
625270909090909090909090909090909090909090909090909090909090e0e00000000000000000000000000000000000000000000000000000000000000000
10101010101030303030303030303030303030303030303030303030301010101010101010303030303030303030303030303030303030303030303030104262
625270909090909090909090909090909090909090909090909090909090e0e00000000000000000000000000000000000000000000000000000000000000000
10101010101010101030303030303030303030303030303030303030301010101010101010303030303030303030303030303030303030303030303010104262
625270709090909090909090909090909090909090909090909090909090e0e00000000000000000000000000000000000000000000000000000000000000000
10101010101010101010103030303030303030303030303030303030101010101010101010103030303030303030303030303030303030303030301010104262
625270707090909090909090909090909090909090909090909090909090e0e00000000000000000000000000000000000000000000000000000000000000000
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010104262
625270707070707070707070707070707070707070707070707070707070e0e00000000000000000000000000000000000000000000000000000000000000000
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010104262
625270707070707070707070707070707070707070707070707070707070e0e00000000000000000000000000000000000000000000000000000000000000000
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888228228888228822888222822888888822888888ff8888
88888888888888888888888888888888888888888888888888888888888888888888888888888888882288822888222222888222822888882282888888fff888
88888888888888888888888888888888888888888888888888888888888888888888888888888888882288822888282282888222888888228882888888f88888
888888888888888888888888888888888888888888888888888888888888888888888888888888888822888228882222228888882228882288828888fff88888
88888888888888888888888888888888888888888888888888888888888888888888888888888888882288822888822228888228222888882282888ffff88888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888228228888828828888228222888888822888fff888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888188888888888888888
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555551715555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555551771555555555555555
5555555555555555555555555555555555555555505a5b505555e5050505555f5050505555e5850505555f505850555555555555555551777155555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555551777715555555555555
55555555555555555555555555555555555555556666666665577777777755666666666556666666665566666666655555555555555551771155555555555555
555566656665666566656665666566555555e55565556555655755575757556555655565565556566655655565556555e555555555c555117155555555555555
55556565656556555655655565656565555ee55566656665655777575757556665656665566656566655666566656555ee55555555cc55555155155511115555
5555666566655655565566556655656555eee55565556655655755575557556555655565565556555655655566656555eee5555cccccc5551155155511115555
55556555656556555655655565656565555ee55565666665655757777757556566666565565666565655656666656555ee55555c00cc05511111155511115555
555565556565565556556665656565655555e55565556555655755577757556555655565565556555655655566656555e555555c55c055501100055511115555
55555555555555555555555555555555555555556666666665577777777755666666666556666666665566666666655555555550550555550155555500005555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555055555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555500000000055555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555666665506660606055555555555555566666555555555555555555555555556666655555555555555555555555555666665555555555555555555555555
55555655565506000606055555555555555565556555555555555555555555555556555655555555555555555555555555655565555555555555555555555555
55555657565506660666055555555555555565556555555555555555555555555556555655555555555555555555555555655565555555555555555555555555
55555655565500060006055555555555555565556555555555555555555555555556555655555555555555555555555555655565555555555555555555555555
55555666665506660006055555555555555566666555555555555555555555555556666655555555555555555555555555666665555555555555555555555555
55555555555500000000055555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507770707066600ee000ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555070707770006000e000c000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555077707070666000e000ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555070707770600000e00000c0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507070707066600eee00ccc0002000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507770707066600ee000ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555070707770006000e000c000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555077707070666000e000ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555070707770600000e00000c0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507070707066600eee00ccc0002000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507770707066600ee000ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555070707770006000e000c000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555077707070666000e000ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555070707770600000e00000c0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507070707066600eee00ccc0002000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507770000066600ee000ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555070700000006000e000c000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555077700000666000e000ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555070700000600000e00000c0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507070000066600eee00ccc0002000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507770000066600ee000ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555070700000006000e000c000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555077000000666000e000ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555070700000600000e00000c0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507770000066600eee00ccc0002000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507770000066600ee000ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555070700000006000e000c000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555077000000666000e000ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555070700000600000e00000c0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507770000066600eee00ccc0002000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507770000066600ee000ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555070700000006000e000c000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555077000000666000e000ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555070700000600000e00000c0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507770000066600eee00ccc0002000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507770707066600ee000ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555070707770006000e000c000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555077707070666000e000ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555070707770600000e00000c0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507070707066600eee00ccc0002000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55505050505050505050505050505050550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507700000066600ee000ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555070700000006000e000c000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555070700000066000e000ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555070700000006000e00000c0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507770000066600eee00ccc0002000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507700000066600ee000ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555070700000006000e000c000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555070700000066000e000ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555070700000006000e00000c0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507770000066600eee00ccc0002000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507700000066600ee000ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555070700000006000e000c000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555070700000066000e000ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
555070700000006000e00000c0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507770000066600eee00ccc0002000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__gff__
0002000002000002000002020002020202020202020200000000000000020200020202000202020000000200000000000002020000000000000000000000000002020202000000000000000000000000020202020000000000000000000000000200020202020000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101142626150101010101010101010101010d0d0d0d0f0f0f0f0f0f0f0f0f0f0f0f0e0e0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101142626150101010101010101010101010d0d0d0d0f0f0f0f0f0f0f0f0f0f0f0f0e0e0a600c0c0c0c0c0c0c0c0c0c0c4243404142430c0c0c0c0c0c0c0c0c0c0c600a
0101010101010101010101010101010101010101030303030303030303030303030303030303030303030101010101010101010606060606060606060606142626150606060606060606060606060d0d0d0d0f0f0f0f0f11120f0f0f0f0f0e0e0a0c0c0c0c0c0c0c0c0c0c0c0c5253505162630c0c0c0c0c0c0c0c0c0c0c0c0a
0101010101010101010101010101010101010103030303030303030303030303030303030303030303030303010101010101060606060406060406060606142626150606060604060604060606060d0d0d0d0f0f0f0f0f21220f0f0f0f0f0e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
010101010101011d1e0101010101010101010303030303030101010101010103030303030303030303030303030101010101060606060606060606060606142626150606060606060606060606060d0d0d0d0f0f0f0f0f31320f130f0f0f0e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
010101010101012d2e0101010101010101010303030303010101010101010101010101010101010103030303030101010101060606060606060606060606142626150606060606060606060606060d0d0d0d0709090909090909090909070e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
0101010303030303030303030301010101010303030303030101010101010101010101010101010101030303030301010101060406060406060406060406142626150604060604060604060604060d0d0d0d0909090909090909090909090e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
0101030303030303030303030303010101010303030303030303030303010101010103030303010101010303030301010101060606060606060606060606272727270606060606060606060606060d0d0d0d0909090909090909090909090e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
0101030303030303030303030303010101010303030303030303030303030303030303030303010101010303030301010101060606060606060606060606272727270606060606060606060606060d0d0d0d0909090909090909090909090e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
0101010303030303030303030301010101010303030303030303030303030303030303030303010101010303030303010101060606060606060606060606272727270606060606060606060606060d0d0d0d0909090909090909090909090e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
0101010101010103030101010101010101010303030303030303030303030303030303030303010101010103030303010101060406060406060406060406142626150604060604060604060604060d0d0d0d0909090909090909090909090e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
0101010101010103030101010101010101010303030303030301010303030301010303030303010101010103030303010101060606060606060606060606142626150606060606060606060606060d0d0d0d0909090909090909090909090e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
0101010101010103030101010101010101010303030303030101010101010101010103030301010101010103030303010101060606060606060606060606142626150606060606060606060606060d0d0d0d0909090909090909090909090e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
0101010101010103030101010101010101010303030303030101010101010101010101010101010101010103030303010101060406060406060406060406142626150604060604060604060604060d0d0d0d0909090909090909090909090e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
0101010101010103030101010101010101010303030303030101010101010101010101010101010101010303030303010101060606060606060606060606142626150606060606060606060606060d0d0d0d0909090909090909090909090e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
0101010101010103030101010101010101010303030303010101010101010101010101030301010101010303030303010101060606060606060606060606142626150606060606060606060606060d0d0d0d0909090909090909090909090e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
0101010101010103030101010101010101010303030303010101010101010101010103030303010101010303030303010101060606060606060606060606142626150606060606060606060606060d0d0d0d0909090909090909090909090e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
0101010101010103030101010101010101010303030303010101010101010101010103030303030101030303030303010101060606060606060606060606142626150606060606060606060606060d0d0d0d0909090909090909090909090e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
0101010101010103030101010101010101010303030303010101010101010101010103030303030303030303030301010101060406060406060406060406142626150604060604060604060604060d0d0d0d0909090909090909090909090e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
0101010101010103030101010101010101010303030303010101010101010101010103030303030303030303030301010101060606060606060606060606142626150606060606060606060606060d0d0d0d0909090909090909090909090e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
0101010101010303030301010101010101010303030303030101010101010101010103030303030303030303030301010101060606060606060606060606142626150606060606060606060606060d0d0d0d0909090909090909090909090e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
0101010101030303030303010101010101010303030303030303010101010101010103030303030303030303030301010101060406060406060406060406142626150604060604060604060604060d0d0d0d0909090909090909090909090e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
0101010103030303030303030101010101010303030303030303030101010101010103030303030303030303030301010101060606060606060606060606142626150606060606060606060606060d0d0d0d0909090909090909090909090e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
0101010303030303030303030301010101010303030303030303030301010101010101030303030303030303030101010101060606060606060606060606142626150606060606060606060606060d0d0d0d0909090907090909090909090e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
0101030303030303030303030303010101010103030303030303030303010101010101030303030303030303030101010101060606060606060606060606142626150606060606060606060606060d0d0d0d0909090909090909090909090e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
0101030303030303030303030303010101010103030303030303030303030101010101030303030303030303030101010101060606060606060606060606142626150606060606060606060606060d0d0d0d0909090909090909090909090e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
0101030303030303030303030303010101010101010303030303030303030101010101010303030303030303010101010101060406060406060406060406142626150604060604060604060604060d0d0d0d0909090909090909090909090e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
0101030303030303030303030303010101010101010101030303030303030101010101010303030303030303010101010101060606060606060606060606142626150606060606060606060606060d0d0d0d0909090909090909090909090e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
0101030303030303030303030303010101010101010101010303030303030101010101010303030303030303010101010101060606060606060606060606142626150606060606060606060606060d0d0d0d0909090909090909090909090e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
0101030303030303030303030303010101010101010101010303030303030101010101010303030303030303010101010101060406060406060406060406142626150604060604060604060604060d0d0d0d0909090909090909090909090e0e0a0c0c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c0c0a
0101030303030303030303030303010101010101010101010103030303030101010101010303030303030303030101010101060606060606060606060606142626150606060606060606060606060d0d0d0d0909090909090909090909090e0e0a600c0c0c0c0c0c0c0c0c0c0c3334343434350c0c0c0c0c0c0c0c0c0c0c600a
0101030303030303030303030303010101010101010101010103030303030101010101010303030303030303030101010101161616161616161616161616142626151717171717171717171717170d0d0d0d0909090909090909090909090e0e0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a
__sfx__
012000002e0402e0402e0402e0402e04029055290552e0402c0402a0402c0402c0402c0402c0402c0402c0402e0402e0402e0402e0402e0402a0552a0552e0402d0402b0402d0402d0402d0402d0402d0402d040
0120000016070160701d0701d0702207022070220702207014070140701b0701b07020070200702007020070120701207019070190701e0701e0701e0701e070110701107018070180701d0701d0701d0701d070
011000001d0501d0001d050160501d0501d0001d050160501d0501d0001d050160501d050160501d050160501d0501d0001d050160501d0501d0001d050160501d0501d0001d050160501d050160501d05016050
01100000160551d0051605516055160551d0051605516055160551d000160551605516055160551605516055160551d0001605516055160551d0051605516055160551d005160551605516055160551605516055
01100000220512205022050220501d0501d0501d0501d0501d0501d00022070220002207024070260702707029050290502905029050220502405026050270502905029050290502905029050290502905029050
011000001d0501d0001d050160501d0501d0001d050160501d0501d0001d050160501d050160501d050160501b0501d0001407514075140751d0051407514075140751d0001b050140501b050140501b05014050
01100000190001d0001905012050190501d0001905012050190501d000190501205019050120501905012050180501d0001107511075110751d0051107511075110751d000180501105018050110501805011050
011000001605000000160751607516075000001607516075160750000016075160751607500000160751607514050000001407514075140750000014075140751407500005140751407514075000001407514075
010f00001205012000120751207512075000001207512075120750000012075120751207500000120751207519050000001907519075190750000019075190751907500005190751907519075000001907519075
010200001805018000010000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
01200000220502205022000220571d0501d0501d0001d0501e0501e0501d0001e0501d0501d0501d0001d050220001d0001d00022005220002400025000270002900029000290001d00029005290002a0002c000
012300002e0002e000220002e0052e0002e0002c0002a0002c0002a0002900029000290001b0001d0001d0001b0051d0001e0051e00020000220001d0001b000190051b0001d0051d0001e000200001b00019000
010400002200222002220022200222002220022200222002220022200222002220022000220002200022000222002220022200222002220022200222002220022200222002220022200222002220022200222002
0104000022000220002200022000000000000000000000001d0001d0001d000000001d0001d00000000000001d0001d00000000000001d0001d00000000000001d0001d00000000000001d0001d0000000000000
010400001d0001d0000000000000000000000000000000001d0001d00000000000001d0001d00000000000001d0001d00000000000001d0001d0001d0001d0001d0001d0001d0001d0001b000190001900000000
01100000220002200022000220001d0001d0001d0001d000220002200022000220002200022000240002400025000250002700027000290002900000000000002900029000240002400029000290000000000000
011000002a0002a0002d0002c0002c0002c0002b000290002e0002e0002e0002e0002c0002f0001e000200002e0002a0002e0002d0002e0002c0002e0062e0002c000240002a000240002c0002c0002a0002a000
01100000294002940029400294002900029000294002940024000240002740327402274022740229404290042a4052a4062a4062a406294042940427402274022540125401254012540127402274021d4011d401
011000001d4001d4011d4011d40100000000001b0001b000190001900018000180001800018000180001800015000150001500015000150001500015000150001150011500115001150011500115001150000000
011000001160011500115001150011600115001160011500116001150011500115001160011500116001150011600115001150011500116001150011600115001160011600115001150011600116001150011500
010400000000000000000000000000000000000000000000050060500605000050000500605006050000500005006050060500005000050060500605000050000500605006050000500005006050060500005000
011000002e0002e0002c0002c0002e0002e00029000290002e0002e0003000030000310003100030000300002e0002e0002c0002c0002e0002e00029000290003300033000310003100030000300002e0002e000
011000002200022000220002200021000210002100021000220002200022000220002400024000240002400031000310003100031000300003000030000300003100031000310003100033000330003300033000
0110000035000350003500035000350003500035000350003a0003a0003a0003a0003a0003a0003a0003a00039000390003900039000390003900039000390003900039000390003900039000390003900039000
011000001d3001d3001d3001d3001d3001d3001d3001d3001d3001d3001d3001d3001d3001d3001d3001d30021300213002130021300213002130021300213001d3001d3001d3001d3001d3001d3000930009300
011000001705000000170751707517075000001707517075170750000017075170751707500000170751707516050000001607516075160750000016075160751607500005160751607516075000001607516075
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
012000001b0051b0051f00521005210052300523005210051f0051a0051a0051f0052100522005210051f00527005270052b0052d0052d0052f0052f0052d0052b0053200532005320052f005300053000532005
012000001b0051b0051f0051b0051f0051f0051b0051b0051b0050e00518005190050e00520005230052400527005270052b005270052b0052b00527005270051b00526005240052500526005200052300524005
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
012000001b0551b0051f05521055210052305523005210551f0551a0551a0051f0552105522055210551f05527055270052b0552d0552d0052f0552f0052d0552b0553205532005320552f055300553000532055
012000001b0751b0051f0051b0751f0051f0051b0051b0751b0050e07518005190050e07520005230052400527075270052b005270752b0052b00527005270751b00526075240052500526075200052300524005
01200000221502215022150211502315023150231502215026150261502615025150281502815028150281502515025150251502415026150261502615025150291502915029150281502b1502b1502b1502b150
01200000271502715027150271502615026150261502615029150291502915029150281502815028150281502b1502b1502a1502a1502d1502d1502c1502c1502f1502f1502f1502f1502f1502f1502f1502f150
012000000067000370073600736000670003700736007360006700037007360073600037000370073600736000670003700736007360006700037007360073600067000370073600736000370003700736007360
012000003315033150331503315032150321503215032150351503515035150351503415034150341503415037150371503615036150391503915038150381503b1503b1503b1503b1503b1503b1503b1503b150
0120000016050190501d0502205025050220501d0501905016050190501d0502205025050220501d05019050190501d05022050250502905025050220501d05025050290502e0503105035050310502e05029050
012000002b1751f1452414528145271451f1452f145231452d17524145281452d1452b1452414526145281452d17524145291452d1452c145241452614529145281751f145241452814526145211452314526145
01200000183551f335133351f335173351f335133351f335183551f335133351f33518335183351a3351c3351d3552433518335243351d3352433518335243351c35524335133351f33517335133351533517335
012000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000133551535517355
012000002b1512b1502b1502815027150271532f1502f1502d1502d1502d1502d1502b1502b1502b1502b1502d1502d1502d1502f150321503215030150301502b1502b1522b1502815026150261502615026150
012000000c6550c6050c6550c605186750c6050c6550c6050c6550c6050c6550c605186750c6050c6550c6050c6550c6050c65518605186750c6050c6550c6050c6550c6050c6550c605186750c6050c6550c605
012000003735037350373003425633350333502f2503b2503935039350393002d3503725037250372502b2503935039350393003b2503e3503e3503c250302503735037350373003425032350323503235037200
01200000182551f250132551f250172551f250132551f250183551f350133551f35018355183501a3551c3501d2552425018255242501d2552425018255242501c45524450134551f45017455134501545517450
012000002b3502b35037300282562735027350232502f2502d3502d35039300213502b2502b2502b2501f2502d3502d350393002f250323503235030250323503425034250342503425034300343002817528175
012000002615026150241502415024150241502f1502d1502b1502b1502b150281502d1502d15028150281502615028150291502a1502b1502b1503415034150301503015030150301003c35037350393503b350
01200000183551f350133551f350173551f350133551f350183551f350133551f35018355183501a3551c3501d3552435018355243501c3552435018355243501c3552835023355283501c355283502335528350
012000001c3552433518335243351c335243351c3351a335183551f335133351f335193351333515335133351a3551c3351d3351e3351f335133351533517335183301833018330180003c30037300393003b300
012000002615026150241502415024150241502f1502d1502b1502b1502b150281502d1502d15028150281502615028150291502a1502b1502b150281502815024150241502415018000241451f1452114523145
010c000027150261502515024150261502515024150231502515024150231502215024150231502215021150231502215021150201501f1501e1501d1501d1501d1501d1501d1501d1501d1501d1501d10011000
012000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010350103500c65500000
000400000000004450064500845008450034500145004400044000140001400014000445006450084500845003450000000000000000044500745006450024500000000000054500745005450024500000000000
010100002517125171221711d17119151161511517114171141711517116151171511717116171151710f17109151061510417102171011710117101151011510115101151001010010100101001000010000100
000300001f0501f0501f0500210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800002415224162241722410524175241002417524100221552410024150241502415024150241502415124150241402413024125181001810000100001000010000000000000000000000000000000000000
011000002b1502a150271502115020154281502c15030150007040070100002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 00014344
00 02034344
00 04064344
00 42424344
00 43424344
00 42424344
00 444b4344
00 454b4344
01 464c4344
00 474d4344
00 484e4344
00 494f4344
02 4a4f4344
00 41424344
00 1e1f4344
00 20216244
00 60232244
00 41242244
00 41656244
00 41666244
00 41676244
00 41686244
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
00 39424344
01 2d2f4344
00 2d2e4344
00 302e3144
00 33323144
00 36343144
00 3735313a
00 3332317a
00 3634317a
02 3837717a
01 28785444
02 29787954
01 282a4344
00 29792a44
00 28312a44
00 2b312a44
00 28312a2c
00 28292a2b
00 28312c6b
00 28296c6b
03 26274344

