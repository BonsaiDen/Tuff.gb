# Build
rom: convert
	@mkdir -p build
	@gbasm -O -o build/game.gb -m stdout -s build/game.sym src/main.gb.s

convert:
	@mkdir -p src/data/bin
	node convert src/data src/data/bin

# Emulation
run: rom
	gngb --fps -a build/game.gb

gambatte: rom
	gambatte_qt build/game.gb

bgb: rom
	WINEPREFIX=~/.local/share/wineprefixes/steam wine ~/.local/bin/bgb.exe build/game.gb


# Others
clean:
	rm -rf build
	find . -name "*.bin" -print0 | xargs -0 rm -rf
	
tiled:
	~/Sources/tiled-qt-0.9.1/build/bin/tiled src/data/main.map.json &


# Video
record:
	../gameboy/mednafen -sound.driver sdl -qtrecord "game_raw.mov" -qtrecord.vcodec png -qtrecord.h_double_threshold 144 -qtrecord.w_double_threshold 160 build/game.gb

webm:
	../gameboy/ffmpeg -i game_raw.mov -vf scale=320:288 -sws_flags neighbor -c:v libvpx -crf 10 -b:v 1M -c:a libvorbis game.webm

render:
	../gameboy/ffmpeg -i game_raw.mov -vf scale=480:432 -sws_flags neighbor -acodec libmp3lame -ac 1 -ab 64000 -ar 22050 -vcodec mpeg4 -flags +mv4+gmc -mbd bits -trellis 2 -b 8000k game.avi

