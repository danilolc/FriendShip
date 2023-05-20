#cp gfx/penguin.png build/penguin.png 
#cp gfx/sd.png build/sd.png 

#cp gfx/logo.png build/logo.png
#cp gfx/stars.png build/stars.png
#cp gfx/text.png build/text.png

#./bin/png2asset gfx/penguin.png -map -bin -keep_palette_order -noflip
#./bin/png2asset gfx/penguin.png -map -bin -keep_palette_order -noflip

rgbasm main.asm -o main.asm.o -l -H
rgblink -o output.gb --map output.map main.asm.o 
rgbfix -v output.gb -p 0xff