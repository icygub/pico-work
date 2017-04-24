

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
