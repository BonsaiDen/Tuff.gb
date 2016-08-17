# Build
rom: convert
	@mkdir -p build
	@gbasm -O -o build/game.gb -m stdout -s build/game.sym src/main.gb.s
	@cp build/game.gb ~/.wine/drive_c/Program\ Files/bgb/game.gb
	@cp build/game.sym ~/.wine/drive_c/Program\ Files/bgb/game.sym

convert:
	@mkdir -p src/data/bin
	node convert src/data src/data/bin

# Emulation
run: rom
	gngb --fps -a --sound build/game.gb

gambatte: rom
	gambatte_sdl -s 3 build/game.gb

bgb: rom
	wine ~/.wine/drive_c/Program\ Files/bgb/bgb.exe ~/.wine/drive_c/Program\ Files/bgb/game.gb

# Others
clean:
	rm -rf build
	find . -name "*.bin" -print0 | xargs -0 rm -rf
	
tiled:
	~/dev/tiled/bin/tiled src/data/main.map.json &


# Video
record:
	../gameboy/mednafen -sound.driver sdl -qtrecord "game_raw.mov" -qtrecord.vcodec png -qtrecord.h_double_threshold 144 -qtrecord.w_double_threshold 160 build/game.gb

webm:
	../gameboy/ffmpeg -i game_raw.mov -vf scale=320:288 -sws_flags neighbor -c:v libvpx -crf 10 -b:v 1M -c:a libvorbis game.webm

render:
	../gameboy/ffmpeg -i game_raw.mov -vf scale=480:432 -sws_flags neighbor -acodec libmp3lame -ac 1 -ab 64000 -ar 22050 -vcodec mpeg4 -flags +mv4+gmc -mbd bits -trellis 2 -b 8000k game.avi

