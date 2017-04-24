
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

