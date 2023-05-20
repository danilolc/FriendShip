# Add OAMS
# Add sound (music, sfx)
# Game logic


PNG_FILES = $(wildcard gfx/*.png)

PNG_NAMES = $(addprefix build/, $(subst gfx/, ,$(basename $(PNG_FILES))))
PNG_FILES_MAP = $(addsuffix _map.bin, $(PNG_NAMES))
PNG_FILES_TILES = $(addsuffix _tiles.bin, $(PNG_NAMES))

all: output.gb

output.gb: main.asm.o
	@rgblink -o $@ --map output.map main.asm.o
	@rgbfix -v $@ -p 0xff
	@echo DONE!

main.asm.o: main.asm
	@echo ASSEMBLING
	@rgbasm $^ -o $@ -l -H

main.asm: $(PNG_FILES_TILES) 
	@echo a

build/%_tiles.bin: gfx/%.png
	@echo PNG file $*.png changed!
	@mkdir -p build
	@cp -f $^ build/$*.png
	@./bin/png2asset build/$*.png -map -bin -keep_palette_order -noflip

clean:
	@rm -r build
	@rm output.gb
	@rm main.asm.o
	@rm output.map

.PHONY: all clean