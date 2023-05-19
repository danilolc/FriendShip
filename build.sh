rgbasm main.asm -o main.asm.o -l -H
rgblink -o output.gb --map output.map main.asm.o
rgbfix -v output.gb -p 0xff