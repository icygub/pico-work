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

function draw_things()
	for a in all(actors) do
		if a.visible then
			a.draw(a)
		end
	end
end

function draw_to_screen(id, x, y, w, h)
	local alt = get_alt(id)
	palt(alt,true)
	spr(id, x, y, w, h)
	palt(alt,false)
end

function _draw()
	if not trans_active or trans_after_peak then
		scene_draw()
	end
	
	local prev_trans_active = trans_active
	trans_after_peak = transition_draw(30, screen_swipe)

	if prev_trans_active != trans_active and trans_song != nil then
		music(trans_song)
	end

	sleep = trans_active
end

trans_active = false
trans_after_peak = false
trans_timer = 0
trans_song = -1

-- call to start a transition.
function transition(mark, music_when_done, sound_effect)
	if not trans_active then
		if mark != nil then
			marker = mark
		end

		trans_active = true
		trans_timer = 0
		trans_after_peak = false
		sleep = true

		trans_song = music_when_done

		if sound_effect != nil then
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
