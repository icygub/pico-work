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
