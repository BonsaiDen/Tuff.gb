export PATH :=./tools:$(PATH)

rom: convert
	mkdir -p build
	rgbasm -o build/main.o src/main.rsm
	rgblink -o build/main.gb build/main.o
	rgbfix -v -p 0 build/main.gb
	cp build/main.gb tools/emu/roms/tuff.gb

convert:
	node convert src/data

clean:
	rm -rf build
	find . -name "*.bin" -print0 | xargs -0 rm -rf

run: rom
	gngb --fps -a build/main.gb

