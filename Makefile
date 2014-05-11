rom: convert
	@mkdir -p build
	@cd src && rgbasm -o ../build/main.o main.rsm
	@rgblink -o build/game.gb build/main.o -m build/game.map
	@rgbfix -v -p 0 build/game.gb
	@node stat build/game.map
	@cp  build/game.gb tools/emu/roms/tuff.gb
	@cp  build/game.gb tools/emu/web/roms/tuff.gb

convert:
	@mkdir -p data/bin
	node convert data data/bin

run: rom
	gngb --fps -a build/game.gb

gambatte: rom
	gambatte_qt build/game.gb

bgb: rom
	WINEPREFIX=~/.local/share/wineprefixes/steam wine ~/.local/bin/bgb.exe build/game.gb

clean:
	rm -rf build
	find . -name "*.bin" -print0 | xargs -0 rm -rf
	
tiled:
	~/Sources/tiled-qt-0.9.1/build/bin/tiled &

