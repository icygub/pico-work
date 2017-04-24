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
