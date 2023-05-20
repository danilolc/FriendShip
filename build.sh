#cp gfx/penguin.png build/penguin.png 
#cp gfx/sd.png build/sd.png 

#cp gfx/logo.png build/logo.png
#cp gfx/stars.png build/stars.png
#cp gfx/text.png build/text.png

#./bin/png2asset gfx/penguin.png -map -bin -keep_palette_order -noflip
#./bin/png2asset gfx/penguin.png -map -bin -keep_palette_order -noflip

#rgbasm main.asm -o main.asm.o -l -H
#rgblink -o output.gb --map output.map main.asm.o
#rgbfix -v output.gb -p 0xff

OUTPUT = output.gb
ASM_FILE = main.asm

all: $(OUTPUT)

$(OUTPUT): $(ASM_FILE)
    rgblink -o $@ --map output.map main.asm.o
    rgbfix -v $@ -p 0xff

$(ASM_FILE): $(PNG_FILES)
    rgbasm $@ -o main.asm.o -l -H

$(PNG_FILES):
    cp gfx/$@ build/$@
    ./bin/png2asset build/$@ -map -bin -keep_palette_order -noflip