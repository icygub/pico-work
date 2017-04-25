function gen_energy_ball(x,y,dx,dy)
	local ball = gen_bullet(x,y,dx,dy)
	ball.spr = 119
	ball.bad = true
	ball.deflect = false
	ball.id = "ball"

	ball.hit=
		function(other)
			if other == pl.sword and pl.has_master and ball.good == false then
				ball.deflect = true
				ball.good = true
			end
		end

	ball.move=function(self)
		if ball.deflect then 
			ball.deflect = false
			ball.dx *= -1
			ball.dy *= -1
		end
	end

	return ball
end

function gen_canondwarf(x, y)
	local bad = gen_enemy(x, y)
	bad.solid = false
	bad.killed = false

	bad.reset =
		function()
			bad.spr = 109
			bad.dx = 0
			bad.dy = 0
			if not bad.killed then
				bad.x = x
				bad.y = y
				bad.hearts = 1
				bad.state = 0
				bad.timer = 0
			end
			bad.vulnerable = false
			bad.clock = true
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

	bad.reset()
	bad.tres_text = "trespasser."

	bad.move = canon_move

	bad.hit =
		function(other)
			if other.id == "ball" and other.good then
				other.alive = false
				if bad.state < 7 then
					bad.state = 5
				else
					bad.state = 9
					bad.timer = 60
					gen_skelly(bad.x, bad.y)
				end
			elseif other == pl.sword and pl.has_master then
				if bad.vulnerable then
					bad.hearts -= 1
					bad.vulnerable = false
					if bad.hearts == 3 then
						bad.state = 7
					end
				end
			end

			if bad.hearts <= 0 and bad.state < 11 then
				sfx(22)
				music(-1)
				bad.state = 11
				bad.timer = 90 -- how long to shake when dead.
			end
		end

	return bad
end

function canon_move(self)
	if self.state == 1 then -- start music
		music(55)
		self.state = 2
		self.timer = 30
	elseif self.state == 2 then -- move up at start
		self.dy = -.05
		self.timer -= 1
		if self.timer <= 0 then
			self.state = 3
			self.timer = 60
		end
	elseif self.state == 3 then -- shoot player
		self.timer -= 1
		if self.timer <= 0 then
			self.state = 4
			self.timer = 120
		elseif self.timer % 30 == 0 then
			local ball = gen_energy_ball(self.x,self.y, 0, 0)
			move_to_player(ball, .3)
		end
	elseif self.state == 4 then -- move to player
		move_to_player(self, .05)
		self.timer -= 1
		if self.timer <= 0 then
			self.state = 3
			self.timer = 120
		end
	elseif self.state == 5 then -- got hit, gen things
		gen_poe(self.x, self.y)
		gen_skelly(98.5, 17.5)
		gen_skelly(109.5, 17.5)
		gen_skelly(109.5, 2.5)
		gen_skelly(98.5, 2.5)
		self.state = 6
		self.vulnerable = true
		self.timer = 60
	elseif self.state == 6 then -- stunned then move to player.
		self.timer -= 1
		if self.timer <= 0 then
			self.vulnerable = false
			self.state = 4
			self.timer = 120
		elseif self.vulnerable == false then -- canon was hit
			shake()
		end
	elseif self.state == 7 then -- second stage
		shake()
		local mid_x = 104
		local mid_y = 8
		move_to_point(self, .05, 104, 10)
		-- if reached the center then
		if self.x < mid_x + 2 and self.x > mid_x - 2 and self.y < mid_y + 2 and self.y > mid_y - 2 then
			self.timer = 0
			self.state = 8
			self.touchable = false
		end
	elseif self.state == 8 then
		if self.clock then
			move_clockwise(self, 3, 2, 2, self.timer)
		else
			move_counter(self, 3, 2, 2, self.timer)
		end
		if self.timer % 60 == 0 then
			local ball = gen_energy_ball(self.x,self.y, 0, 0)
			move_to_player(ball, .3)
		end
		if self.timer % 360 == 0 then
			gen_skelly(98.5, 17.5)
			gen_skelly(109.5, 17.5)
			gen_skelly(109.5, 2.5)
			gen_skelly(98.5, 2.5)
		end
		self.timer += 1
	elseif self.state == 9 then
		self.vulnerable = true
		self.state = 10
		self.timer = 60
		gen_skelly(self.x, self.y)
	elseif self.state == 10 then
		shake()
		self.clock = not self.clock
		if self.timer <= 0 then
			self.vulnerable = false
			self.state = 7
		elseif self.vulnerable == false then -- canon was hit
			shake()
		end
		self.timer -= 1
	elseif self.state == 11 then -- defeated, shaking like crazy.
		shake()
		self.timer -= 1
		if self.timer <= 0 then
			canon_kill(self)
		end
	end
end

function canon_kill(bad)
	bad.state = 12
	music(-1)

	bad.killed = true
	bad.bad = false
	bad.static = true

	-- canon is killed now, no need to re-add him after enemies are cleaned.
	clean_enemies()

	bad.move=actor_interact
	bad.interact =
		function()
			tbox("canondwarf", "yer such a meanie!!!")
		end

	-- make zelda
	mset(101, 2, 98)
	mset(102, 2, 99)
	bad.x = 104
	bad.y = 3.5
	pl.x = 103
	pl.y = 4.5

	gen_zeldo(102, 3.5)
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
