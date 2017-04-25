pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
-- zeldo - alan morgan

scene_actors = {}
draw_map_funcs = {}
triggers = {}
marker = "title"  -- where you are in the story, start on title screen.
prev_marker = marker
global_time=0 -- the global timer of the game, used by text box functions

sleep = false -- used to sleep the update function

actors = {} -- all actors in world.
offh = 64
offw = 96

viewx = 0
viewy = 0


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
	shake(true) -- reset the shake.

	-- only update if we are not in the middle of a marker change.
	if prev_marker == marker and not sleep then
		prev_marker = marker

		if marker == "title" then
			title_update()
		else
			scene_update()
		end

		if prev_marker != marker then
			scene_init()
			prev_marker = marker
		end
	end

	global_time=global_time+1 -- increment the clock
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
	local a={}

	-- if true, then this object cannot be moved by other objects.
	a.static=false

	-- if false, then you can walk through walls.
	a.solid=true

	-- if false, then you can go through other actors.
	-- but the hit function will still be called.
	a.touchable=true

	-- which side are you on?
	a.good = false
	a.bad  = false

	-- if this number is higher than zero, then the move function won't be
	-- called for your sprite until the timer goes down.
	a.stun  = 0

	-- if false, then the draw function for the sprite is not called.
	a.visible=true

	-- position and speed.
	a.x = x
	a.y = y
	a.dx = 0.0
	a.dy = 0.0

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
	a.bounce  = .3

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

	-- gets called if the actor is leaving the scene
	a.unload = function() end

	-- gets called if the actor is entering the scene
	a.load = function() end

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

-- returns a list of all actors hit. will return nil if none were hit.
-- or if this is out of bounds.
-- bounds. won't check for actors that are out of bounds.
-- also does not work with overlapping actors.
function actor_collision(a, dx, dy)
	local retlist = {}

	if not a.is_outside then
		for a2 in all(actors) do
			if not a2.is_outside and a != a2 then
				local x=(a.x+dx) - a2.x
				local y=(a.y+dy) - a2.y
				if ((abs(x) < (a.w+a2.w)) and
					(abs(y) < (a.h+a2.h)))
				then 
					-- check if moving together
					if (dx != 0 and abs(x) <
							abs(a.x-a2.x)) then
						if a.touchable and a2.touchable then
							v=a.dx + a2.dx
							if not a.static then a.dx = v/2 end
							if not a2.static then a2.dx = v/2 end
						end
						add(retlist, a2)
					elseif (dy != 0 and abs(y) <
									abs(a.y-a2.y)) then
						if a.touchable and a2.touchable then
							v=a.dy + a2.dy
							if not a.static then a.dy = v/2 end
							if not a2.static then a2.dy = v/2 end
						end
						add(retlist, a2)
					end
				end
			end
		end
	end

	return retlist
end

-- checks just walls
function touching_wall(a, dx, dy)
	return a.solid and solid_area(a.x+dx,a.y+dy, a.w,a.h)
end

-- calls the hit function for each actor touching a.
function hit_actors(a,alist)
	-- hits with the main actor.
	for other in all(alist) do
		a.hit(other)
		other.hit(a)
	end
end

-- existential function for touchable items.
function has_touchable(actor_list)
	for a in all(actor_list) do
		if a.touchable then
			return true
		end
	end
	return false
end

-- figures out speed for collisions or doesn't change the speed.
-- and hurts the actors.
function move_actor_check(a, dx, dy)
	if not touching_wall(a, dx, dy) then
		local other_list = actor_collision(a, dx, dy) 

		if #other_list != 0 then
			hit_actors(a,other_list)

			if a.touchable and has_touchable(other_list) then
				dx *= -a.bounce
				dy *= -a.bounce
				--sfx(60)
			end
		end

	else   
		-- otherwise bounce
		dx *= -a.bounce
		dy *= -a.bounce
		--sfx(60)
	end

	return dx + dy
end


function move_actors()
	-- first set all actor's speed.
	foreach(actors, set_actor_speed)

	-- then set all of their coordinates.
	foreach(actors, set_actor_pos)
end

function set_actor_speed(a)
	if a.is_outside then
		return
	end

	if a.move != nil then
		if a.stun <= 0 then
			a.move(a)
		else
			a.stun -= 1
		end

	a.dx = move_actor_check(a, a.dx, 0)
	a.dy = move_actor_check(a, 0, a.dy)
	end
end

function set_actor_pos(a)
	if a.is_outside then
		return
	end

	-- update the position then apply inertia.
	a.x += a.dx
	a.y += a.dy

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

function offset_x()
	return -viewx * 8 + 64
end

function offset_y()
	return -viewy * 8 + 64
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
-- pos is where the player gets teleported to if the trigger is touched.
function make_trigger(name, x1, y1, x2, y2, pos, mark, mus, snd)
	local func=nil
	if mark != nil then
		func = function() transition(mark, mus, snd) end
	end

	triggers[name] = {box={x1=x1, y1=y1, x2=x2, y2=y2}, active=true, pos=pos, func=func}
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
		if v.active and is_pl_in_box(v.box) then
			v.func()
			if v.pos != nil then
				pl.x = v.pos.x
				pl.y = v.pos.y
			end
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
		transition("hut", 63, 63)
	end
end

-- a super useful function. pass in the sprite id and this will return the
-- transparency color.
function get_alt(id)
	if id == 43 or
	   id == 44 or
	   id == 56 or
	   id == 57 then
		return 15
	elseif id == 16 or
	       id == 27 or
	       id == 28 or
	       id == 32 or
	       id == 48 or
	       id == 112 or
	       id == 119 or
	       id == 113 then
		return 0
	end

	-- def is 7 for this game.
	return 7
end

function del_if_enemy(enemy)
	-- all enemies are bad.
	if enemy.bad then
		del(actors, enemy)
	end
end

function clean_enemies()
	foreach(actors, del_if_enemy)
end

-- use right before changing the scene.
function save_scene()
	-- should call this on multiple actors eventually.
	for a in all(actors) do
		a.unload()
	end
	actors = {}
end

-- use when switching to a new scene.
-- x and y are the player's new coordinates.
function load_scene(scene_name)
	save_scene()
	actors = scene_actors[scene_name]

	add(actors, pl)

	for a in all(actors) do
		a.load()
	end

	view_update()

end

function draw_wrap(x,y,w,h, off)
	if off == nil then
		off = 2
	end

	-- first calculate how many times the loop must go.
	-- the screen midpoint is 8. so i need to wrap to 8 at least.
	local count= flr((8-off)/off)

	local offx = -pl.x*8+64
	local offy = -pl.y*8+64

	-- rest is for wrapping.
	for i=1, count, 1 do
		-- left part screen
		map(x, y, x*8 + -i*8*off + offx, y*8 + offy, off, h)

		-- top part screen
		map(x, y, x*8 + offx, y*8 + -i*8*off + offy, w, off)
	end

	for i=0, count-1, 1 do
		-- right part screen
		map(x+w - off, y, (x+w)*8 + i*8*off + offx, y*8 + offy, off, h)

		-- bottom part screen
		map(x, y+h - off, x*8 + offx, (y+h)*8 + i*8*off + offy, w, off)
	end

	for i=0, count-1, 1 do
		for j=0, count-1, 1 do
			-- bl corner
			map(x, (y+h)-off, x*8 + i*8*off - count*8*off + offx, j*8*off + (y+h)*8 + offy, off, off)

			-- br corner
			map((x+w)-off, (y+h)-off, i*8*off + (x+w)*8 + offx, j*8*off + (y+h)*8 + offy, off, off)

			-- tr corner
			map((x+w)-off, y, i*8*off + (x+w)*8 + offx, y*8 + j*8*off - count*8*off + offy, off, off)

			-- tl corner
			map(x, y, x*8 + i*8*off - count*8*off + offx, y*8 + j*8*off - count*8*off + offy, off, off)
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
		move_actors()
	end

	-- call outside and destroy functions
	update_outside()
	garbage_collection()
end

function dice_roll(sides)
	return flr(rnd(sides)) == 1
end

-- difference between bosses and enemies are stages. bosses use stages to
-- manage complexity.

-- make sure to add stages, states, and defeated function
function gen_boss(x, y)
	local bad = gen_enemy(x, y)
	bad.killed = false
	bad.cur_stage = 1
	bad.defeated = function() end
	bad.stages = {}

	-- hit based on
	bad.hit =
	function(other)
		local stage = bad.stages[bad.cur_stage]
		if stage.vulnerable then
			stage.hurt_func(bad, other)
		else
			stage.hit_func(bad, other)
		end
	end

	bad.move =
	function(self)
		local stage = bad.stages[bad.cur_stage]
		local state = stage.states[stage.cur_state]

		if stage != nil then
			state.func(bad, stage, state.timer)
			state.timer += 1
			stage.timer += 1

			-- move to next stage when this stage is defeated.
			if stage.lives <= 0 then
				bad.stage += 1

				-- die when out of stages.
				if bad.stages[bad.cur_stage] == nil then
					bad.killed = true
					bad.defeated()
				end
			end
		end
	end

	return bad
end

function make_state(func)
	local state = {}
	state.timer = 0
	if func != nil then
		state.func = func
	else
		state.func = function(actor, stage, timer) end
	end

	return state
end

-- be sure to set the lives, hit func, and hurt func.
function make_stage()
	local stage = {}
	stage.states = {}
	stage.cur_state = "begin"
	stage.lives = 1
	stage.vulnerable = false
	stage.timer = 0
	stage.hit_func  = function(self, other, stage, state) end
	stage.hurt_func = function(self, other, stage, state) end

	-- use this function to move to different states, instead of manually
	-- setting cur_state.
	stage.move_to_state =
	function(state)
		stage.states[state].timer = 0
	end

	return stage
end
--- NEW CANONDWARF!!!!!!!!
function gen_canondwarf(x, y)
	local bad = gen_boss(x, y)
	add_canon_stages(bad)

	bad.defeated =
	function()
		canon_kill(bad)
	end

	bad.reset =
		function()
			bad.spr = 109
			bad.dx = 0
			bad.dy = 0
			bad.x = x
			bad.y = y
			bad.solid = false
			bad.touchable = true
		end

	bad.unload =
		function()
			if not bad.killed then
				clean_enemies()
				add(actors, bad)
				canon.reset()
			end

			if triggers["canon_intro"].active == false then
				triggers["canon_resume"].active = true
			end

			if bad.killed then
				triggers["canon_resume"].active = false
			end
		end

	bad.load =
		function()
			if bad.killed then
				music(-1)
			end
		end

	bad.tres_text = "trespasser."
	bad.reset()

	return bad
end

-- give this canondwarf and stages will be added.
function add_canon_stages(bad)
	add(bad.stages, make_canon_stage1())
	add(bad.stages, make_canon_stage2())
	add(bad.stages, make_canon_stage3())
end

function make_canon_stage1()
	local stage = make_stage()
	stage.lives = 3
	stage.hit_func =
	function(self, other, stage, state)
		if other.id == "ball" and other.good then
			other.alive = false
			stage.move_to_state("stunned")
		end
	end

	stage.hurt_func =
	function(self, other, stage, state)
		if other == pl.sword and pl.has_master then
			stage.lives -= 1
			stage.vulnerable = false
		end
	end

	stage.states["topl"] = make_state(
	function(actor, stage, timer)
		move_to_player(actor, .05)
		if timer > 120 then
			stage.move_to_state("shootpl")
		end
	end)

	stage.states["shootpl"] = make_state(
	function(actor, stage, timer)
		if timer >= 120 then
			stage.move_to_state("topl")
		elseif timer % 30 == 0 then
			shoot_ball_to_pl(actor)
		end
	end)

	stage.states["begin"] = make_state(
	function(actor, stage, timer)
		if timer == 0 then
			music(55) -- play actual canon music!
		elseif timer >= 30 then
			stage.move_to_state("shootpl")
		else
			actor.dy = -.05
		end
	end)

	stage.states["stunned"] = make_state(
	function(actor, stage, timer)
		if timer == 0 then
			gen_poe(self.x, self.y)
			gen_skellies_in_corners()
			stage.vulnerable = true
		elseif timer >= 60 then
			self.move_to_state("topl")
		else
			-- canon was hit
			if not stage.vulnerable then
				shake()
			end
		end
	end)

	return stage
end

function make_canon_stage2()
	local stage = make_stage()
	stage.lives = 3
	stage.hit_func =
	function(self, other, stage, state)
		if other.id == "ball" and other.good then
			other.alive = false
			stage.move_to_state("stunned")
		end
	end

	stage.hurt_func =
	function(self, other, stage, state)
		if other == pl.sword and pl.has_master then
			stage.lives -= 1
			stage.vulnerable = false
		end
	end

	stage.states["begin"] = make_state(
	function(actor, stage, timer)
		if timer == 0 then
			-- go through cannon for second stage.
			actor.touchable = false
		elseif timer >= 30 then
			stage.move_to_state("shootpl")
		else
			actor.dy = -.05
		end
	end)

	-- slightly different from other stage's stun.
	stage.states["stunned"] = make_state(
	function(actor, stage, timer)
		if timer == 0 then
			gen_skelly(self.x, self.y)
			stage.vulnerable = true
		elseif timer >= 60 then
			self.move_to_state("tocenter")
		else
			-- canon was hit.
			if not stage.vulnerable then
				shake()
			end
		end
	end)

	stage.states["tocenter"] = make_state(
	function(actor, stage, timer)
		shake()
		local mid_x = 104
		local mid_y = 8
		move_to_point(actor, .05, 104, 10)

		-- if reached the center
		if actor.x < mid_x + 2 and actor.x > mid_x - 2 and actor.y < mid_y + 2 and actor.y > mid_y - 2 then
			stage.move_to_state("circle")
		end
	end)

	stage.states["circle"] = make_state(
	function(actor, stage, timer)
		if timer == 0 then
			-- either move clockwise or counter.
			stage.clock = dice_roll(2)
		else
			if stage.clock then
				move_clockwise(actor, 3, 2, 2, timer)
			else
				move_counter(actor, 3, 2, 2, timer)
			end

			if timer % 60 == 0 then
				shoot_ball_to_pl(actor)
			end

			if timer % 360 == 0 then
				gen_skellies_in_corners()
			end
		end
	end)

	return stage
end

-- this is the stage that he is defeated.
function make_canon_stage3()
	local stage = make_stage()
	stage.lives = 1
	-- no hit nor hurt functions.

	stage.states["begin"] = make_state(
	function(actor, stage, timer)
		shake()
		if timer == 0 then
			music(-1)
			sfx(22)
		elseif timer > 90 then
			stage.lives = 0
		end
	end)

	return stage
end

-- a utility function that generates four skeletons in the boss room.
function gen_skellies_in_corners()
	gen_skelly(98.5, 17.5)
	gen_skelly(109.5, 17.5)
	gen_skelly(109.5, 2.5)
	gen_skelly(98.5, 2.5)
end

-- utility function. parameter is the actor to shoot from.
function shoot_ball_to_pl(actor)
	local ball = gen_energy_ball(actor.x,actor.y, 0, 0)
	move_to_player(ball, .3)
end


--- TEMPORARY THINGS THAT determine canon being killed.
function canon_kill(bad)
	music(-1)

	bad.bad = false
	bad.static = true

	-- canon isn't bad now, no need to re-add him after enemies are cleaned.
	clean_enemies()

	bad.move=actor_interact
	bad.interact =
		function()
			tbox("canondwarf", "yer such a meanie!!!")
		end

	-- get rid of the cage.
	mset(101, 2, 98)
	mset(102, 2, 99)

	-- set locations
	bad.x = 104
	bad.y = 3.5
	pl.x = 103
	pl.y = 4.5

	-- make zelda
	gen_zeldo(102, 3.5)

	-- make it look like they didn't just teleport. heh.
	transition(marker)

	ivan_reveal_cutscene()
end

function ivan_reveal_cutscene()
	ivan_revealed = true
	tbox("canondwarf", "you beat me. that hurt.")
	tbox("zeldo", "lank, why did you beat up canondwarf?")
	tbox("zeldo", "we were just about to have a tea party.")
	tbox("ivan", "haha. ha. ha.")
	tbox("ivan", "mwahahahahaha.")
end
-- draws how many power orbs have been collected.
function draw_power_orbs(x, y)
	-- hearts on right of screen
	draw_to_screen(55, x-1, y-1)
	print(power_orb_count, x+8, y+1, 7)
end

-- draws the various items that have been collected so far.
function draw_items(x, y)
	local stats = {}

	if pl.has_sword then
		if pl.has_master then
			add(stats, 43)
		else
			add(stats, 56)
		end
	end

	if pl.has_boomerang then
		add(stats, 54)
	end

	if pl.has_fairy then
		add(stats, 117)
	end

	-- draw items to the screen
	local i = 0
	for id in all(stats) do
		draw_to_screen(id, i*10 + x, y)
		i += 1
	end
end



function draw_text(text, x, y, col)
	local sx = (x * 8) + offset_x()
	local sy = (y * 8) + offset_y()

	print(text, sx, sy, col)
end

-- a utility function for drawing actors to the screen. auto offsets and
-- assumes white is the default background color.
function draw_actor(a, w, h, flip_x, flip_y)
	if a.alive then
		local sx = (a.x * 8) + offset_x() - a.sw/2
		local sy = (a.y * 8) + offset_y() - a.sh/2

		if w == nil then w = 1 end
		if h == nil then h = 1 end
		if flip_x == nil then flip_x = false end
		if flip_y == nil then flip_y = false end

		local alt = get_alt(a.spr)
		palt(alt,true)
		spr(a.spr + a.frame, sx, sy, w, h, flip_x, flip_y)
		palt(alt,false)
	end
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
	local alt = get_alt(id)
	palt(alt,true)
	spr(id, x, y)
	palt(alt,false)
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


-- draws the hearts, but from the right.
function draw_hearts(x, y)
	-- hearts on right of screen
	for i=0, pl.hearts-1, 1 do
		draw_to_screen(35, x-8*(i+1), y-1)
	end
end

function scene_draw()
	-- the marker variable is for the transitions.
	local mark = ""
	if trans_after_peak then
		mark = marker
	else
		mark = prev_marker
	end

	if mark == "title" then
		draw_title()
		return
	end

	if mark == "hut" then
		draw_map(96, 32, 5, 5)
	elseif mark == "boss" then
		draw_map(offw, 0, 32, 32)
	elseif mark == "overworld" then
		draw_map(0, 0, offw, offh)
		draw_wrap(0, 0, offw, offh)
	elseif mark == "old" then
		draw_map(96, 38, 5, 5)
	elseif mark == "sacred" then
		draw_map (113, 33, 10, 22)
		draw_wrap(113, 33, 10, 22)
	elseif mark == "shop" then
		draw_map(101, 33, 11, 10)
	else -- assume lost woods
		draw_map (97, 45, 10, 10)
		draw_wrap(97, 45, 10, 10, 1)
	end

	draw_things()
	draw_hearts(126, 2)
	draw_items(2, 118)
	draw_power_orbs(2, 2)

	if pl.alive == false then
		draw_game_over()
		draw_link_death()
	end

	if not ivan_revealed then
		draw_fairy()
	end

	tbox_draw()
end

function _draw()
	if not trans_active or trans_after_peak then
		scene_draw()
		draw_triggers() -- debugging
		print(marker, 50, 2, 7)
	end

	
	local prev_trans_active = trans_active
	trans_after_peak = transition_draw(30, screen_swipe)

	if prev_trans_active != trans_active and trans_song != nil then
		music(trans_song)
	end

	sleep = trans_active
end

function draw_map(x, y, w, h)
	cls(0)
	local offx = -pl.x*8+64
	local offy = -pl.y*8+64
	map(x, y, x * 8 + offx, y * 8 + offy, w, h)
end

trans_active = false
trans_after_peak = false
trans_timer = 0
trans_song = -1

-- call to start a transition.
function transition(mark, music_when_done, sound_effect)
	if not trans_active then
		marker = mark
		trans_active = true
		trans_timer = 0
		trans_after_peak = false
		sleep = true

		trans_song = music_when_done

		if sound_effect == nil then
			sfx(-1)
		else
			music(-1)
			sfx(sound_effect)
		end
	end
end

-- returns true if it is at least halfway done.
function transition_draw(time, func)
	local after_peak = false
	if trans_active then
		after_peak = func(time, trans_timer)
		trans_timer += 1
		if trans_timer >= time then
			trans_active = false
		end
	end
	return after_peak
end

-- a transition effect. returns true if it is at least halfway done.
function screen_swipe(length, timer)
	-- only want to go in a half circle.
	local pos = 128 * sin(timer / length / 2 + .5)

	if timer > length / 2 then
		rectfill(128-pos,-1,129,129,0)
	else
		rectfill(-1,-1,pos,129,0)
	end

	return timer >= flr(length / 2)
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
	bad.move = function(self) move_to_player(self, .1) end
	bad.inertia = 0
	return bad
end

function gen_deku_bullet(x,y,dx,dy)
	local bad = gen_bullet(x,y,dx,dy)
	bad.spr = 71
	return bad
end

function gen_poe(x, y)
	local bad = gen_enemy(x, y)
	bad.spr = 116
	bad.solid = false
	bad.touchable = false
	bad.move = function(self) move_counter(self, 4, 5, 5, self.t) end
	bad.draw =
		function(a)
			draw_actor(a, nil, nil, a.dx > 0, nil)
		end
	return bad
end

function gen_dark_link(x, y)
	local bad = gen_enemy(x, y)
	bad.spr = 124
	return bad
end

function gen_octorok(x, y)
	local bad = gen_enemy(x, y)
	bad.spr = 86
	return bad
end

function gen_enemy(x, y)
	local bad = make_actor(x, y)
	bad.spr = 1
	bad.dx=0
	bad.dy=0
	bad.inertia=.5
	bad.bad=true
	bad.hearts=0
	bad.solid=true
	bad.move = function(self) end
	bad.hit=
		function(other)
			if other == pl.boomerang then
				bad.stun = 30
			end

			if other.good then
				bad.alive = false
			end
		end

	bad.destroy =
		function(self)
			local col = nil
			-- smaller chance you get a heart.
			if dice_roll(5) then
				col = gen_heart(bad.x, bad.y)
			else
				col = gen_power_orb(bad.x, bad.y)
			end
			
			col.dx = bad.dx*3
			col.dy = bad.dy*3
		end

	-- enemy faces player, assumes sprite is facing left
	bad.draw =
		function(a)
			draw_actor(a, nil, nil, a.x < pl.x, nil)
		end

	return bad
end


function gen_bullet(x,y,dx,dy)
	local bad = gen_enemy(x,y)
	if dx == nil then dx = 0 end
	if dy == nil then dy = 0 end
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

function gen_boomerang(x, y, dir)
	local time = 15
	local spd = .4
	local hs = 0
	local vs = 0

	local boom = make_actor(x, y)

	boom.spr = 54
	boom.solid = false
	boom.touchable = false
	boom.inertia = 0
	boom.collection = {}

	-- updates the position of the things the boomerang collected.
	update_collection = function()
		foreach(boom.collection,
			function(item)
				item.dx = boom.dx
				item.dy = boom.dy
			end)
		end

	-- when the boomerang collects a power orb.
	boom.collect=
		function(other)
			other.x = boom.x
			other.y = boom.y
			other.dx = boom.dx
			other.dy = boom.dy
			add(boom.collection, other)
		end

	if dir == 0 or dir == 4 or dir == 7 then
		hs = -spd
	elseif dir == 1 or dir == 5 or dir == 6 then
		hs = spd
	end

	if dir == 2 or dir == 4 or dir == 5 then
		vs = -spd
	elseif dir == 3 or dir == 6 or dir == 7 then
		vs = spd
	end

	boom.dx = hs
	boom.dy = vs
	
	boom.move=
		function(self)
			if self.t >= time then
				move_to_player(boom, spd)
			else
				boom.dx = hs
				boom.dy = vs
			end

			update_collection()
		end

	boom.draw=
		function(self)
			local num = flr(self.t / 4) % 4
			local fx = false
			local fy = false
			if num == 0 then
				fx = true
				fy = true
			elseif num == 1 then
				fx = true
				fy = false
			elseif num == 2 then
				fx = false
				fy = false
			elseif num == 3 then
				fx = false
				fy = true
			end
			draw_actor(self, nil, nil, fx, fy)
		end

	boom.hit=
		function(other)
			if other == pl then
				if boom.t >= time then
					boom.alive = false
					for a in all(boom.collection) do
						a.alive = false
					end
				end
			elseif other.bad and other.solid and other.touchable then
				boom.t = time
			end

		end

	boom.destroy =
		function(self)
			pl.boomerang = nil
		end

	return boom
end

function gen_sword(x, y, dir, master)
	local time = 10
	local spd = .3
	local off = .5

	local dx = 0.0
	local dy = 0.0

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
			draw_actor(self, nil, nil, fx, fy)
		end

	return sword
end
function make_lost_woods(path_len)
	actors = {}
	gen_sign(100.5,46.5, "don't get lost!")

	scene_actors[get_lost_name(1)] = actors
	actors = {}

	for i=2, path_len do
		gen_lost_actors(i, path_len)
	end

	local path = make_lost_path(path_len)
	lost_woods_triggers(path)
end

function gen_lost_actors(path_num, path_len)
	actors = {}

	gen_skelly(102,50)

	scene_actors[get_lost_name(path_num)] = actors
	actors = {}
end

-- returns the list of path directions.
function make_lost_path(path_len)
	-- can't have a path that allows you to go right then left.
	-- if 0 then 0 or 1. if 2 then 1 or 2.
	local lost_woods_path = {}
	local prev_num = 1

	for i=1, path_len-1 do
		local new_num = 1

		if prev_num == 0 then
			new_num = flr(rnd(2))
		elseif prev_num == 1 then
			new_num = flr(rnd(3))
		else -- must be 2
			new_num = flr(rnd(2)) + 1
		end
			
		add(lost_woods_path, new_num)
		prev_num = new_num
	end

	add(lost_woods_path, 1)
	return lost_woods_path
end

-- a utility function to make a trigger in one of the three lost woods directions
-- used in make_wrong_exit, make_right_exit, and make_final_exit.
-- 0 = left, 1 = up, 2 = right
function make_lost_dir_trigger(str, dir)
	if dir == 0 then
		make_trigger(str, 96, 48, 97, 52, {x=106.5, y=50})
	elseif dir == 1 then
		make_trigger(str, 100, 44, 104, 45, {x=102, y=54.5})
	else -- dir is 2
		make_trigger(str, 107, 48, 108, 52, {x=97.5, y=50})
	end
	triggers[str].active = false
end

function get_lost_name(room_num)
	return "lost_woods_"..room_num
end

function get_lost_right_name(room_num)
	return "lost_woods_"..room_num.."_right"
end

function get_lost_wrong1_name(room_num)
	return "lost_woods_"..room_num.."_wrong_1"
end

function get_lost_wrong2_name(room_num)
	return "lost_woods_"..room_num.."_wrong_2"
end

-- pass in true to make the room active, or false to make it inactive.
function toggle_lost_room_str(room_name, active)
	local str1 = room_name.."_wrong_1"
	local str2 = room_name.."_wrong_2"
	local str3 = room_name.."_right"

	triggers[str1].active = active
	triggers[str2].active = active
	triggers[str3].active = active
end

function toggle_lost_room(room_num, active)
	local str1 = get_lost_wrong1_name(room_num)
	local str2 = get_lost_wrong2_name(room_num)
	local str3 = get_lost_right_name(room_num)

	if room_num > 0 then
		triggers[str1].active = active
		triggers[str2].active = active
		triggers[str3].active = active
	end
end

-- switches the triggers. if either are 0, then nothing happens for that one.
function switch_lost_room(cur_num, nxt_num)
	toggle_lost_room(cur_num, false)
	toggle_lost_room(nxt_num, true)
	marker = get_lost_name(nxt_num)
end

-- there are only two wrongs. 1 and 2.
function make_wrong_exits(path_num, dir1, dir2)
	local str1 = get_lost_wrong1_name(path_num)
	local str2 = get_lost_wrong2_name(path_num)

	make_lost_dir_trigger(str1, dir1)
	make_lost_dir_trigger(str2, dir2)

	local reset_func=
		function()
			-- go to the first lost room.
			switch_lost_room(path_num, 1)
		end

	triggers[str1].func = reset_func
	triggers[str2].func = reset_func
end

function make_right_exit(path_num, dir)
	local str = get_lost_right_name(path_num)
	local nxt = get_lost_name(path_num+1)
	make_lost_dir_trigger(str, dir)

	triggers[str].func =
		function()
			-- go to next room
			switch_lost_room(path_num, path_num+1)
		end
end

function make_final_exit(path_num, dir)
	local str = get_lost_right_name(path_num)
	make_lost_dir_trigger(str, dir)
	triggers[str].pos = {x=118,y=54.5}

	triggers[str].func =
		function()
			-- get rid of last one and enable first one.
			toggle_lost_room(path_num, false)
			toggle_lost_room(1, true)
			transition("sacred", 63, 63)
		end
end

-- assumes the items in lost woods path are a 0, 1, or 2
function lost_woods_triggers(lost_woods_path)
	local str_exit = "lost_woods_exit"
	make_trigger(str_exit, 100,  55, 104,  56, {x=32, y=1.5})
	triggers[str_exit].func =
		function()
			toggle_lost_room_str(marker, false)
			toggle_lost_room(1, true)
			transition("overworld")
		end

	-- the keys are indexes like an array
	for k,v in pairs(lost_woods_path) do
		if k == #lost_woods_path then
			make_final_exit(k, v)
		else
			make_right_exit(k, v)
		end

		make_wrong_exits(k, (v+1)%3, (v+2)%3)
	end

	toggle_lost_room(1, true) -- make the first lost room enabled at the start.
end


function make_map()
	actors = {}

	gen_sign(34.5, 17.5, "the square force has protected the land of hiroll for ages.")
	gen_chest(40.5, 7.5, 
		function()
			heart_container()
		end)

	gen_sign(9.5,5.5, "lank's house")

	gen_sign(14.5,48.5, "old man's house")
	gen_grave(17.5,48.5, "here lies an even older man. i love you dad. :)")

	gen_oldman(31.5, 2.5,
		function(self)
			if self.state == 0 then
				if power_orb_count >= 50 then
					tbox("old man", "oh, you have 50 power orbs. i'll take those. hehe.")
					power_orb_count -= 50
					mset(32,2,3) -- set the block to grass.
					self.state = 1
				else
					tbox("old man", "a powerful sword along with powerful enemies lie beyond here.")
					tbox("old man", "come back when you've collected 50 power orbs.")
				end
			else
				tbox("old man", "thanks for the orbs.")
			end
		end)

	-- things from alpha
	gen_poe(57.5,10.5)
	gen_poe(8, 9.5)
	gen_enemies()

	scene_actors["overworld"] = actors
	actors = {}
end

function make_hut()
	actors = {}

	scene_actors["hut"] = actors
	actors = {}
end

function make_sacred()
	actors = {}

	gen_chest(119.5, 36.5,
		function()
			heart_container()
		end)

	gen_sign(116.5, 36.5, "only the hero of hiroll can wield this sword.")
	gen_sword_stand(118, 36.5)

	scene_actors["sacred"] = actors
	actors = {}
end

function make_old()
	actors = {}

	gen_sign(97.5, 39.5, "that chest holds all that is left of my father. please don't open the it.")
	gen_chest(99.5, 39.5,
		function()
			pl.has_boomerang = true
			tbox("", "you found a boomerang!")
			tbox("", "hold x then press an arrow key to use it.")
		end)

	scene_actors["old"] = actors
	actors = {}
end

function make_boss()
	actors = {}

	canon = gen_canondwarf(104,3.5)
	gen_chest(100.5, 2.5,
		function()
			power_orb_count += 49
			canon.tres_text = "theif."

			tbox("", "you found 49 power orbs. canondwarf doesn't deserve these anyway.")
			tbox("canondwarf", "oh now you steal from me. i'll never forgive you for this.")
		end)
	gen_sign(107.5, 2.5, "cages are reserved for special guests.")

	make_trigger("canon_intro",  100,  1,     108,  9)
	make_trigger("canon_resume", 100,  1,     108,  9)

	make_trigger("boss_enter",   87,   3,     89,   4.5,  {x=104,  y=19.5}, "boss", 53, -1)
	make_trigger("boss_exit",    101,  20,    107,  21,   {x=88, y=4.5},  "overworld", 14, -1)

	triggers["canon_resume"].active = false

	triggers["canon_resume"].func =
		function()
			music(-1)
			tbox("canondwarf", "mwahahahahahahahahahaha.")
			tbox("canondwarf", "i see you're back. you'll pay you little "..canon.tres_text)
			sfx(59)
			canon.spr = 108
			canon.state = 1
			triggers["canon_resume"].active=false
		end

	triggers["canon_intro"].func =
		function()
			music(-1)
			tbox("canondwarf", "mwahahahahahahahahahaha.")
			tbox("canondwarf", "who are you?")
			tbox("lank", "i'm lank.")
			tbox("zeldo", "lank you're here! i have to tell you something. don't listen to-")
			tbox("canondwarf", "be quiet princess! i'm going to take care of this trespasser.")
			sfx(59)
			canon.spr = 108
			canon.state = 1
			triggers["canon_intro"].active=false
		end

	scene_actors["boss"] = actors
	actors = {}
end

function make_shop()
	actors = {}

	gen_oldman(106.5, 35.5,
		function(self)
			if self.state == 0 then
				tbox("shopkeeper", "i love selling things.")
				tbox("shopkeeper", "press z below one of the items to buy it.")
			end
		end)

	gen_item(103.5, 38.5, 50, 117,
		function(item)
			if not pl.has_fairy then
				tbox("", "you got a fairy in a bottle.")
				tbox("", "it will heal you if you've lost all your hearts.")
				pl.has_fairy = true
				item.alive = false
				return true
			else
				return false
			end
		end)

	gen_item(106.5, 38.5, 49, 56,
		function(item)
			if not pl.has_sword then
				tbox("", "you got a sword.")
				tbox("", "hold z then press an arrow key to use it.")
				pl.has_sword = true
				item.alive = false
				return true
			else
				return false
			end
		end)

	gen_item(109.5, 38.5, 50, 118,
		function(item)
			heart_container()
			item.alive = false
			return true
		end)

	scene_actors["shop"] = actors
	actors = {}
end

function make_scenes()
	make_map()
	make_hut()
	make_shop()
	make_boss()
	make_old()
	make_lost_woods(5) -- how long the woods are
	make_sacred()
end

-----------------
-- enemy creation
-----------------
function gen_enemies()
	for i=0, 25, 1 do
		local x = rnd(93-18)+18.5
		local y = rnd(43) + 2.5
		local id = flr(rnd(3))
		if id == 0 then
			gen_octorok(x, y)
		elseif id == 1 then
			gen_deku(x, y)
		elseif id == 2 then
			gen_skelly(x, y)
		end
	end
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
-----------------
-- movement functions
-----------------
function move_clockwise(a, spd, radx, rady, timer)
	local ang = -timer / 30 / spd
	a.dx = radx * spd * cos(ang) / 30
	a.dy = rady * spd * sin(ang) / 30
end

-- assumes that when timer is zero, you are at the top of the circle.
function move_counter(a, spd, radx, rady, timer)
	local ang = timer / 30 / spd + .5
	a.dx = radx * cos(ang) / 30
	a.dy = rady * sin(ang) / 30
end

function move_vertical(a)
	local slow = 4*30
	a.dy = a.rady * sin(a.t / slow) / 30
end

function move_horizontal(a)
	local slow = 4*30
	a.dx = a.radx * cos(a.t / slow) / 30
end

function move_to_point(a, spd, x, y)
	local ang = atan2(x - a.x, y - a.y)
	a.dx = spd * cos(ang)
	a.dy = spd * sin(ang)
end

function move_to_player(a, spd)
	move_to_point(a, spd, pl.x, pl.y)
end

function move_from_player(a)
	local slow = 2
	local ang = atan2(a.x - pl.x, a.y - pl.y)
	a.dx = a.radx * cos(ang) / 30 / slow
	a.dy = a.rady * sin(ang) / 30 / slow
end
-- the parameter is what should happen when the player opens the chest.
function gen_chest(x,y, func)
	local chest = gen_interactable(x, y)
	chest.spr=114
	chest.interact=
		function()
			if chest.spr != 115 then
				chest.spr = 115
				sfx(62)
				func()
			end
		end
	return chest
end

function gen_grave(x,y, str)
	local grave = gen_sign(x, y, str)
	grave.spr=4
	return grave
end

-- func is what should happen when the player tries reading the sign.
function gen_sign(x,y, str)
	local sign = gen_interactable(x, y)
	sign.spr = 19
	sign.interact = function() tbox("", str) end
	return sign
end

-- people have states so they may say different things at different times.
function gen_oldman(x,y, func)
	local oldie = gen_interactable(x, y)
	oldie.interact = function() func(oldie) end
	oldie.spr=97
	oldie.state=0
	return oldie
end

function gen_item(x,y, price, spr_ind, func)
	local item = gen_interactable(x, y)
	item.spr = spr_ind
	item.static = true
	item.price = price
	item.draw=
		function(self)
			draw_text(self.price, item.x-.5, item.y-1.3, 1)
			draw_actor(self)
		end

	-- only buy the item if you have enough power orbs.
	item.interact =
		function()
			if power_orb_count >= item.price then
				if func(item) then
					power_orb_count -= item.price
				end
			else
				tbox("shopkeeper", "hey, you don't have enough power orbs to buy that!")
			end
		end

	return item
end


-- things that are operated by pressing z below the object.
function gen_interactable(x, y, func)
	local thing = make_actor(x,y)
	thing.static=true
	if func != nil then
		thing.interact=func
	else
		thing.interact=function() end
	end

	thing.move=actor_interact

	return thing
end

function actor_interact(self)
	local x1 = -self.w
	local x2 =  self.w
	local y1 =  self.h
	local y2 =  2.5*self.h

	if is_pl_in_box_rel(self, x1, x2, y1, y2)
	and btnp(4) then
		self.interact()
	end
end

-- what happens when you find a heart container.
function heart_container()
	tbox("", "you got a heart container.")
	tbox("", "your max health is now increased by one.")
	pl.max_hearts += 1
	pl.hearts = pl.max_hearts

end

function gen_collectable(x, y)
	local collectable = make_actor(x, y)
	collectable.hit_boom = false
	collectable.inertia = 0
	collectable.touchable = false
	collectable.solid = false

	-- use a closure!
	collectable.hit=
		function(other)
			-- only collision with player if not hit boomerang.
			if other == pl and not collectable.hit_boom then
				collectable.alive = false
			elseif other == pl.boomerang and not collectable.hit_boom then
				collectable.hit_boom = true
				other.collect(collectable)
			end
		end

	return collectable
end

function gen_heart(x,y)
	local heart = gen_collectable(x,y)
	heart.spr = 35

	heart.destroy =
		function(self)
			pl.heal()
		end
	return heart
end

function gen_power_orb(x, y)
	local orb = gen_collectable(x,y)
	orb.spr = 55

	orb.destroy =
		function(self)
			power_orb_count += 1
		end
	return orb
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
			draw_actor(a, 1, 2, nil, nil)
		end

	-- now create the stand
	local stand = gen_interactable(x, y)
	stand.spr = 27
	stand.static = true
	stand.w = .5
	stand.interact = 
		function()
			if sword.alive then
				tbox("voice", "hero of hiroll, we entrust this sword with you.")
				tbox("voice", "beware of your friends.")
				tbox("lank", "that was creepy.")
				tbox("ivan", "hey, listen! you shouldn't listen to spontaneous voices like that.")
				tbox("lank", "okay.")
				sword.alive=false
				pl.has_sword = true
				pl.has_master = true
			end
		end

	stand.sw = 16
	stand.draw=
		function(a)
			draw_actor(a, 2, 1, nil, nil)
		end
end
function gen_zeldo(x, y)
	local girl = gen_interactable(x, y)

	girl.spr = 120
	girl.bounce = .1
	girl.good=true
	girl.static=true

	girl.interact =
		function()
			tbox("zeldo", "you must find and defeat ivan.")
		end

	return girl
end
power_orb_count = 0

function control_player(pl)
	-- how fast to accelerate
	local accel = pl.spd
	-- move if no bomb/shield or sword.
	if not btn(4) and not btn(5) then
		if btn(0) then pl.dx -= accel end
		if btn(1) then pl.dx += accel end
		if btn(2) then pl.dy -= accel end
		if btn(3) then pl.dy += accel end
	elseif btn(4) then
		if pl.sword == nil and pl.has_sword then
			local dir = -1
			if btn(0) then     dir = 0
			elseif btn(1) then dir = 1
			elseif btn(2) then dir = 2
			elseif btn(3) then dir = 3 end

			if dir != -1 then pl.sword=gen_sword(pl.x, pl.y, dir, pl.has_master) end
		end
	elseif btn(5) then
		if pl.boomerang == nil and pl.has_boomerang then
			local dir = -1

			if btn(0) and btn(2)     then dir = 4
			elseif btn(1) and btn(2) then dir = 5
			elseif btn(1) and btn(3) then dir = 6
			elseif btn(0) and btn(3) then dir = 7
			elseif btn(0) then dir = 0
			elseif btn(1) then dir = 1
			elseif btn(2) then dir = 2
			elseif btn(3) then dir = 3 end

			if dir != -1 then pl.boomerang=gen_boomerang(pl.x, pl.y, dir) end
		end
	end

	-- play a sound if moving
	-- (every 4 ticks)
	if pl.regenerate > 0 then pl.regenerate -= 1 end
	
	if (abs(pl.dx)+abs(pl.dy) > 0.1
					and (pl.t%4) == 0) then
		-- sfx(1)
	end
	
	if pl.regenerate > 0 then
		shake()
	end
end

function gen_link(x, y)
	local pl = make_actor(x,y)
	pl.spr = 104
	pl.frames = 3
	pl.solid = false
	pl.bounce = .1
	pl.spd = .1
	pl.move = control_player
	pl.hearts = 20
	pl.has_fairy = false
	pl.draw =
		function(self)
			if pl.regenerate > 0 then
				if pl.t % 10 < 3 then return end
			end
			draw_actor(self)
		end
	
	pl.max_hearts = 3

	pl.heal =
		function()
			if pl.hearts < pl.max_hearts then
				pl.hearts += 1
			end
		end

	-- unload the player, boomerang, and sword.
	pl.unload =
		function()
			del(actors, pl)
			if pl.boomerang != nil then
				del(actors, pl.boomerang)
				pl.boomerang = nil
			end

			if pl.sword != nil then
				del(actors, pl.sword)
				pl.sword = nil
			end
		end

	pl.good=false
	pl.has_sword=true  -- if false, then link can't use his sword.
	pl.has_master = true
	pl.sword=nil       -- used to regulate only one sword.
	pl.regenerate=0

	pl.has_boomerang=false -- if false, then link can't use his boomerang.
	pl.boomerang=nil      -- used to regulate only one boomerang.

	pl.hit=function(other)
		if other.bad and other.stun == 0 then
			if pl.hearts > 0 and pl.regenerate == 0 then
				pl.hearts = pl.hearts - 1
				pl.regenerate = 30
			end
	
			if pl.hearts == 0 then
				if pl.has_fairy then
					pl.has_fairy = false
					pl.hearts = pl.max_hearts
				else
					pl.alive = false
				end
			end
		end
	end

	pl.destroy=function(other)
		music(-1)
		music(41)
	end

	return pl
end

------------------------------------------------------------------------------
-- screen shake implementation, taken from https://github.com/jessemillar/pico-8
-- slightly modified
------------------------------------------------------------------------------
function shake(reset) -- shake the screen
	camera(0,0) -- reset to 0,0 before each shake so we don't drift

	if not reset then -- if the param is true, don't shake, just reset the screen to default
		camera(flr(rnd(2)-1),flr(rnd(2)-1)) -- define shake power here (-1 to shake equally in all directions)
	end
end

ivan_revealed = false

function make_triggers()
	-- trigger positions
	make_trigger("no_sword",     7,    10,    9,    12)
	make_trigger("no_sword",     7,    10,    9,    12)
	make_trigger("steal"   ,     97,   39,    100,  42)
	make_trigger("hut_start",    97,   33,    100,  36)
	make_trigger("mast_intro",   115,  37,    121,  41)

	make_trigger("hut_enter",    7,    4.5,   9,    5.5,  {x=98.5,    y=36.5}, "hut",  63, -1)
	make_trigger("old_enter",    15,   47.5,  17,   48.5, {x=98.5,    y=42.5}, "old",  63, -1)
	make_trigger("shop_enter",   29,   55.5,  31,   56.5, {x=106.5,   y=42.5}, "shop", 63, -1)
	make_trigger("lost_enter",   31,   0,     33,   1,    {x=102,     y=54.5}, get_lost_name(1))

	make_trigger("hut_exit",    97,   37,    100,  38,   {x=8,    y=5.5},  "overworld", 14, -1)
	make_trigger("old_exit",    97,   43,    100,  44,   {x=16,   y=48.5}, "overworld", 14, -1)
	make_trigger("shop_exit",   104,  43,    109,  44,   {x=29.5, y=56.5}, "overworld", 14, -1)
	make_trigger("sacred_exit", 116,  55,    120,  56,   {x=32.5, y=1.5},  "overworld", 14, -1)

	-- start out false

	triggers["mast_intro"].func =
		function()
			tbox("ivan", "yes. lank, once you wield this, you can finally defeat canondwarf. haha!")
			tbox("lank", "wow, i think i can do this.")
			triggers["mast_intro"].active=false
		end

	triggers["hut_start"].func =
		function()
			tbox("ivan", "hey! listen!")
			tbox("ivan", "wake up lank.")
			tbox("lank", "...")
			tbox("ivan", "lank, princess zeldo is being held captive by canondwarf! you gotta rescue her!")
			tbox("lank", "who are you?")
			tbox("ivan", "i'm your fairy")
			tbox("lank", "oh, okay.")
			triggers["hut_start"].active=false
		end

	triggers["steal"].func =
		function()
			tbox("ivan", "look! it's a chest.  try pressing z near it.")
			tbox("lank", "but it's not mine..")
			tbox("ivan", "nevermind that. you're just borrowing it.")
			tbox("lank", "well, i guess i could give it back later.")
			
			triggers["steal"].active=false
		end

	triggers["no_sword"].func =
		function()
			tbox("ivan", "hey, listen! you don't have a sword yet! how can you save zeldo like this?")
			triggers["no_sword"].active=false
		end
end

-- sets up the game and player, but not the various objects that are scene
-- specific.
function init_game()
	actors = {}
	pl = gen_link(8, 8)
	gen_grass()
end

-- gets called whenever the scene switches.
function scene_init()
	local x = 0
	local y = 0

	if marker == "boss" then
	--elseif marker == "overworld" then
		--music(-1)
		--music(14)
	elseif marker == "hut" then
		--music(-1)
		--music(63)
		if prev_marker == "title" then
			pl.visible = true
			pl.x = 98.5
			pl.y = 34
		end
	--elseif marker == "old" then
		--music(-1)
		--music(63)
	--elseif marker == "sacred" then
		--music(-1)
		--music(45)
		---- just a filler song
	elseif marker == "title" then
		music(-1)
		music(0)
		pl.visible = false

	--elseif marker == "shop" then
		--music(-1)
		--music(63)
	end

	load_scene(marker)
end

------------------------------------------------------------------------------
-- text box implementation, taken from https://github.com/jessemillar/pico-8
-- fixed bugs for this game though.
------------------------------------------------------------------------------

tbox_messages={} -- the array for keeping track of text box overflows

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

function is_tbox_done(id)
	for l in all(tbox_messages) do
		if l.id == id then
			return false
		end
	end
	return true
end

-- add a new text box, id is optional, it is the id of the event. You can check
-- if an event is done with a unique id.
function tbox(speaker, message, id)
	local line_len=26

	-- if there are an odd number of lines.
	if #tbox_messages%2==1 then -- add an empty line as a second line to the previous dialogue.
		tbox_line(speaker, "")
	end

	local words = words_to_list(message, line_len)
	local lines = words_to_lines(words, line_len)

	for l in all(lines) do
		tbox_line(speaker, l, id)
	end
end

-- a utility function for easily adding a line to the messages array
function tbox_line(speaker, l, id)
	local line={speaker=speaker, line=l, animation=0, id=id}
	add(tbox_messages, line)
end

-- check for button presses so we can clear text box messages
function tbox_interact()
	if btnp(4) and #tbox_messages>0 then
		-- sfx(30) -- play a sound effect

		-- does the animation complete
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
			--sfx(0)
			tbox_messages[1].animation+=1
		elseif tbox_messages[2] != nil and tbox_messages[2].animation<#tbox_messages[2].line then
			--sfx(0)
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
