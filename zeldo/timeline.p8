pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
-- zeldo - alan morgan

backup_actors = {} -- for when you switch rooms.
actors = {} -- all actors in world.
marker = 0  -- a number representing where you are in the story.
offh = 16*4
offw = 16*6

viewx = 0
viewy = 0

global_time=0 -- the global timer of the game, used by text box functions
tbox_messages={} -- the array for keeping track of text box overflows

-------------------------
-- pico main
-------------------------
function _init()
	color(0)
	palt(0,false)
	srand(time())
	scene_init()
end

function _update()
	local prev_marker = marker
	scene_update()
	if prev_marker != marker then
		scene_init(prev_marker)
	end

	global_time=global_time+1 -- increment the clock
end

function _draw()
	scene_draw()
end

function scene_draw()
	if marker == 0 then -- title screen
		draw_title()
	elseif marker == 1 then -- first master sword scene
		draw_map()
		draw_things()
		draw_hearts()
		draw_fairy()
		tbox_draw()
	elseif marker == 2 then -- second master sword scene
	elseif marker == 3 then -- boss battle
		draw_map()
		draw_things()
	elseif marker == 4 then -- normal game scene
		draw_map()
		draw_things()
		draw_hearts()
		draw_fairy()
		tbox_draw()
	elseif marker == 5 then -- game over
		draw_map()
		draw_things()
		draw_hearts()
		draw_game_over()
		draw_link_death()
		draw_fairy()
	elseif marker == 6 then -- hut
		draw_map()
		draw_things()
		draw_hearts()
		draw_fairy()
		tbox_draw()
	end
end

function scene_update()
	if marker == 0 then -- title screen
		title_update()
	elseif marker == 1 then -- first master sword scene
		tbox_interact()
		view_update()
		if not tbox_active() then
			marker = 6
		end
	elseif marker == 2 then -- second master sword scene
		tbox_interact()
		view_update()
	elseif marker == 3 then -- boss battle
	elseif marker == 4 then -- normal game scene
		tbox_interact()
		map_update()
		room_update()
		view_update()
	elseif marker == 5 then -- game over
	elseif marker == 6 then -- hut
		tbox_interact()
		if not tbox_active() then
			map_update()
			hut_update()
			view_update()
		end
	end
end

function room_update()
	if pl.x < 12 and pl.y < 5.5 then
		marker = 6
	end
end

function scene_init(prev_marker)
	if marker == 0 then
		init_map()
		pl.visible = false
	elseif marker == 1 then -- first master sword scene
	elseif marker == 2 then -- second master sword scene
	elseif marker == 3 then
		init_boss()
		draw_map = draw_boss
	elseif marker == 4 then
		draw_map = draw_overworld
		if prev_marker == 6 then
			load_actors()
			pl.x = 8
			pl.y = 5.5
			view_update()
		end
		music(0,30)
	elseif marker == 5 then
		music(14)
	elseif marker == 6 then -- hut
		save_actors()

		draw_map = draw_hut
		if prev_marker == 0 then
			pl.x = offw + 2.5
			pl.y = 32 + 2.0
			pl.visible = true

			tbox("ivan",  "hey, listen zeldo! princess lank is in trouble you gotta rescue her!")
			tbox("zeldo", "okie dokie. sounds fun!")
		elseif prev_marker == 4 then
			draw_map = draw_hut
			pl.x = offw + 2.5
			pl.y = 32 + 4.5
		end

		view_update()
	end
end

function save_actors()
	backup_actors = actors
	actors = {}
	add(actors, pl)
end

function load_actors()
	actors = backup_actors
	backup_actors = {}
end

function hut_update()
	if pl.y > 32 + 5 then
		marker = 4
	end
end

function view_update()
	viewx = pl.x
	viewy = pl.y
end

function title_update()
	if btnp(4) then
		marker = 6
		sfx(30)
	end
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
	a.hurt = false

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
	a.move = function(other) end

	-- called if two actors are in bounds (not outside) and are touching each
	-- other.
	a.hit = function(other) end

	-- gets called if the actor is out of bounds.
	a.outside = function(other) end

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
	if a2.hurt then
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
	if (btn(0)) pl.dx -= accel 
	if (btn(1)) pl.dx += accel 
	if (btn(2)) pl.dy -= accel 
	if (btn(3)) pl.dy += accel 

	-- play a sound if moving
	-- (every 4 ticks)
	
	if (abs(pl.dx)+abs(pl.dy) > 0.1
					and (pl.t%4) == 0) then
		-- sfx(1)
	end
	
end

-- a utility function for drawing actors to the screen. auto offsets and
-- assumes white is the default background color.
function draw_actor(a, w, h, flip_x, flip_y, alt)
	if a.alive then
		local sx = (a.x * 8) - viewx * 8 + 64 - a.sw/2
		local sy = (a.y * 8) - viewy * 8 + 64 - a.sh/2

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
				del(actors, a)
			end
		end)
end

function map_update()
	if pl.alive then
		foreach(actors, move_actor)
	else
		marker = 5
	end

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

function draw_boss()
	cls(0)
	local offx = -pl.x*8+64
	local offy = -pl.y*8+64
	map(offw, 0, offw*8 + offx, offy, 32, 32)
end

function draw_hut()
	cls(0)
	local offx = -pl.x*8+64
	local offy = -pl.y*8+64
	map(offw, 32, offw*8 + offx, 32*8 + offy, 5, 5)
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
	pl.bounce=.3

	pl.hit=function(other)
		if other.hurt then
			if pl.hearts > 0 then
				pl.hearts = pl.hearts - 1
			end
	
			if pl.hearts == 0 then
				pl.alive = false
			end
		end
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
	orb.spr = 54
	orb.touchable = false
	-- use a closure!
	orb.hit=
		function(other)
			if other == pl then
				orb.alive = false
			end
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
	bad.hearts=0
	bad.radx = 5
	bad.rady = 5
	bad.solid=true
	bad.move = function(self) end
	bad.hit=
		function(other)
			if other == pl then
				orb = gen_power_orb(bad.x, bad.y)
				orb.dx = bad.dx*3
				orb.dy = bad.dy*3
				bad.alive = false
			end
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
	bad.hit=
		function(other)
			if other == pl then
				bad.alive = false
			end
		end

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

	-- deku always faces player.
	bad.draw =
		function(a)
			draw_actor(a, nil, nil, a.x < pl.x, nil)
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

-----------------
-- draw hearts
-----------------
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

-- landscape and what not
function init_map()
	pl = gen_link(8, 8)

	gen_sword_stand(8, 28)
	gen_poe(57.5,10.5)

	gen_grass()
	gen_enemies()
end

function init_boss()
	color(0)
	actors = {}
	pl = gen_link(offw + 16,30.5)
	ganon = gen_ganondorf(offw + 16,3.5)
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
		printh("hi man")
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
000670000d6d566d66d566d077777777331cccccccccccc1cccccccc544544540655555555554550000000007777777777777777039990000009993008888880
000670000d6d566d66d566d072277227331cccccccccccc1cccccccc544544540655555555555550044444407777777777777777039990000009993008888880
000670000d6d566d66d566d028800882311cccccccccccc1cccccccc544544540055555555555560044999907777777777777777039900000000993008888880
000670000dd5556d6d5556d02888888211cccccccccccc11cccccccc544544547004555555555640044994407777777777777777039900000000993008888880
000670000dd5556d6d5556d0728888271ccccccccccccc14cccccccc544544547004445665555650044994407777777777777777039900000000993008888880
000670000d6d566d66d566d0702882071ccccccccccccc14cccccccc544544547700004444555450099994407777777777777777039900000000993040000004
000670000d6d566d66d566d07702207711cccccccccccc11cccccccc544544547777700000444400044444407777777777777777033300000000333044444444
000070000d6d566d66d566d07777777731ccccccccccccc1cccccccc544544547777770070000007000000007777777777777777000000000000000044444444
777770000d6d566d66d566d02888e9aaaaaaaaaaaa9e888277777777777777777777777777777777000000000005000050575005757775077777770777777757
077700000d6d566d66d566d0228e99eaaaaaaaaaae99e822777cc777777777777777777777777777000000000000000550505007757075077770775777757777
007000000d6d566d66d566d02888e9aaaaaaaaaaaa9e8882776cc677777777777777777777777777000000000000500055507500777077507775777077777775
000000000dd5556d6d5556d0228e99eaaaaaaaaaae99e8227cc66cc7777777777777777777777777000000005050000075700500777507507777077577775777
000000000d6d566d66d566d02888e9aaaaaaaaaaaa9e88827cc66cc7777777777777777777777777000000000000000005000550070507750707577757577777
000000000d6d566d66d566d0228e99eaaaaaaaaaae99e822776cc677777777777777777777777777000000000500050007050750070757755757777777777777
000000000d6d566d66d566d02888e9aaaaaaaaaaaa9e8882777cc777777777777777777777777777000000000000000000050055505750777077707775777577
000000000000000000000000228e99eaaaaaaaaaae99e82277777777777777777777777777777777000000000000005000055075505770777577757777777777
005777755777750000000000000000007755557777944977773b3b37777777770000000000000000000000000000777777770000000000777777700000007777
05475574470674500606060606060600750660577744447773b3b3b3777707770eeeeeeeeeeeee0eeeeeeee00ee0777777770eeeeeeee00777770eeeeeee0777
0547777447777450065656565656565075666657722222277b35353b7700407700888888888888088888888e0880777777770888888888007770888888888077
05475074475574500656565656565650775665777288882704559553704455077000000088208008800008880880777007770880000088800708880000088807
00566664466665000656565656565650775555777222222704445547705544077777770882080708807770000880770990770880777708880008800777008807
555555555555555506d656d656d656d0055605557755554777744447770400777777708820807708800077770880770aa0770880777770888088807777708880
544444444444444506d6d6d6d6d6d6d0770560757755554777544457777077777777088208077708888007770880700550070880777770888088807777708880
454545454545454406d6d6d6d6d6d6d07446044077077047e82e82e877777777777088208077770888880077088009a55a900880777770888088807777708880
457575757575757406d6d6dadad6d6d0777777747777775777722227777777777708820807777708822880770880099009900880777770888088807777708880
46767676767676740656d95ada56d65077777774777777577728e882777777777088208077777708800000770880000000000880777770882028807777708820
467676767676767406565acf5c5656507777775577777757772988e2777777770882080777777708807777770880777777770880777708820002800777008207
444444444444444406565a5f5f56565077777776777777572e888882777777770820800000000708800000070880000000000880000088200702880000088207
45454545454545440656595e5e56565077777776777776d62888e882777777770288888888882008888888800888888888820888888882007770288888882077
45656565656565640656565e5e5656507777777677777767777882e2777777770222222222222202222222220222222222200222222220077777022222220777
4767676767676764060606090906060077777776777777677e822887777777770000000000000000000000000000000000000000000000777777700000007777
47676767676767640000000000000000777777767777777782272e78777777777777777777777777777777777777777777777777777777777777777777777777
700060077777777706d6d6d6d6d6d6d000000000000000007773b77773bb337773bb337773bb337773bb33777777777777288277772882770000000000000000
07667670777777770656d656d656d650060606060606060077733bb7333333773333335733333357333333577777777778822887788228870000000000000000
066070607777777706565656565656500656565656565650773333333533335735cffc7735cffc7735cffc77777dd77772d55d27722222270000000000000000
600670067777777706565656565656500656565656565650773fc33357cffc7757ffff7757ffff7757ffff7777dccd7770555507408228040000000000000000
67777666777777770656565656565650065656565656565074b4ff3777ffff774b3345b44b334547743345b4771cc17742000024420000240000000000000000
0600706077777777065656565656565006d656d656d656d07433ffc74b4453b47744537777445377774453777771177770222207702222070000000000000000
0760767077777777060606060606060006d6d6d6d6d6d6d0743334f7774334777753337777533377775333777777777777000077770000770000000000000000
7066600777777777000000000000000006d6d6d6d6d6d6d077777777777777777747747777777477774777777777777777077077770770770000000000000000
0000000000000000777777777777777777666677777777777777777777777777779aaa7777777777000000000000000075665577000000000000000000000000
000000000000000077777777777777777500005777777777777777777777777779aa9aa777777777000000000000000055555507000000000000000000000000
0000555dd5550000777777777777777770c00c077777777777777777777777777acffca777777777000000000000000050266277000000000000000000000000
0005dd6776dd50007777777777777777700000077777777777777777777777777affffa777777777000000000000000007666677000000000000000000000000
055555555555555077777777777777777705507777777777777777777777777779eeee97777777770000000000000000d655d06d000000000000000000000000
566766d99d66766577777777777777770000000077777777777777777777777777eeee7777777777000000000000000077dd0577000000000000000000000000
5d666d9119d666d57777777777777777aa000d777777777777777777777777777699996777777777000000000000000077055577000000000000000000000000
5dd6d9a99a9d6dd57777777777777777aad0ddd77777777777777777777777777747747777777777000000000000000077d77d77000000000000000000000000
10103030303030303030303030301010101010101010101010303030303010101010101030303030303030303030101010303030303030303030303030304262
6252909090909090909090909090d0d0d0d0909090909090909090909090e0e0a2a2a2a2a2000000000000000000000000000000000000000000000000000000
10103030303030303030303030301010101010101010101010303030303010101010101030303030303030303030303030303030303030303030303030304262
6252909090909090909090909090d0d0d0d0909090909090909090909090e0e0a290f190a2000000000000000000000000000000000000000000000000000000
10103030303030303030303030301010101010101010101010303030303010101010101030303030303030303030303030303030303030303030303030304262
6252909090909090909090909090d0d0d0d0909090909090909090909090e0e0a290f290a2000000000000000000000000000000000000000000000000000000
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

__gff__
0002000002000002000002020002020202020202020200000000000000020200020202000202020000000200000000000002020000000002000000000000000002020202000000000000000000000000020202020000000000000000000000000200020202020000000000000000000000000000000000000000000000000000
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
010200001805018000010000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
01200000220502205022000220571d0501d0501d0001d0501e0501e0501d0001e0501d0501d0501d0001d050220501d0501d05022075220502405025050270502905029050290501d00029075290502a0502c050
012300002e0502e050220002e0752e0502e0502c0502a0502c0502a0502905029050290501b0001d0501d0501b0551d0501e0551e05020050220501d0501b050190551b0501d0551d0501e050200501b05019050
010400002205222052220522205222052220522205222052220522205222052220522005220052200522005222052220522205222052220522205222052220522205222052220522205222002220022200222002
0104000022050220502205022050000000000000000000001d0501d0501d000000001d0501d05000000000001d0501d05000000000001d0001d00000000000001d0501d05000000000001d0501d0500000000000
010400001d0501d0500000000000000000000000000000001d0501d05000000000001d0501d05000000000001d0501d05000000000001d0001d0001d0001d0001d0501d0501d0501d0501b000190001900000000
01100000220502205022000220001d0501d0501d0001d000220502205022000220002205022050240502405025050250502705027050290502905000000000002905029050240002400029050290500000000000
011000002a0502a0502d0002c0002c0502c0502b000290002e0502e0502e0502e0502c0002f0001e000200002e0502a0002e0502d0002e0502c0002e0562e0502c050240002a050240002c0502c0502a0502a050
01100000294502945029450294502900029000294502945024000240002745327452274522745229454290542a4552a4562a4562a456294542945427452274522545125451254512545127452274521d4511d451
011000001d4501d4511d4511d45100000000001b0501b050190501905018050180501805018050180501805015070150701507015070150701507015070150701157011570115701157011570115701150000000
011000001167011530115301153011670115301167011530116701153011530115301167011530116701153011670115301153011530116701153011670115301167011670115301153011670116701153011530
010400000000000000000000000000000000000000000000050560505605050050000505605056050500500005056050560505005000050560505605050050000505605056050500500005056050560505005000
011000002e0102e0102c0102c0102e0102e01029010290102e0102e0103001030010310103101030010300102e0102e0102c0102c0102e0102e01029010290103301033010310103101030010300102e0102e010
011000002202022020220202202021020210202102021020220202202022020220202402024020240202402031020310203102031020300203002030020300203103031030310303103033030330303303033030
0110000035040350403504035040350403504035040350403a0403a0403a0403a0403a0403a0403a0403a04039040390403904039040390403904039040390403904039040390403904039040390403904039040
001000001d3201d3201d3201d3201d3201d3201d3201d3201d3201d3201d3201d3201d3201d3201d3201d32021320213202132021320213202132021320213201d3201d3201d3201d3201d3201d3200930009300
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
000300001f0501f0501f0500210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 01424344
00 02424344
00 03424344
00 02424344
00 03424344
00 02424344
00 040b4344
00 050b4344
01 060c4344
00 070d4344
00 080e4344
00 090f4344
02 0a0f4344
00 41424344
00 1c424344
01 10124344
00 10114344
00 41111314
00 41161514
00 41191714
00 1d1a1814
00 41161514
00 41191714
02 411a1b54
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

