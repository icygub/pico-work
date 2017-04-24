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
