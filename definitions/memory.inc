SECTION "hram0", HRAM
hTransition:
  db

OAMF_hram:
  ds 5
OAMF_hram_end:
  
SECTION "wram0", WRAM0
Screen1X:
  db
Screen1Y:
  db
Screen1C:
  db

Screen2X:
  db
Screen2Y:
  db
Screen2C:
  db
  
Position:
  db


VBLANKF_wram:
  ds 3