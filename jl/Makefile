# the story of zeldo, a retro zeldo game
# by Alan Morgan

COMP='/opt/picotool/p8tool'

out.p8: code.p8 res.p8
	cat code.p8 res.p8 > out.p8
	# $(COMP) build out.p8 --map res.p8 --sfx res.p8 --music res.p8 --gfx res.p8 --gff res.p8 --lua code.p8

code.p8: src/engine.p8 src/boss.p8 src/canon.p8 src/draw.p8 src/enemy.p8 src/engine.p8 src/items.p8 src/lostwoods.p8 src/map.p8 src/move.p8 src/objects.p8 src/people.p8 src/pl.p8 src/shake.p8 src/story.p8 src/tbox.p8
	echo -e "pico-8 cartridge // http://www.pico-8.com\nversion 8\n__lua__\n-- zeldo - alan morgan\n" > code.p8
	cat $^ >> code.p8

clean:
	rm out.p8
