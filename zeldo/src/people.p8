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
