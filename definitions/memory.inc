SECTION "hram0", HRAM
rLogoTransition:
  db

;    <>ba
;00000000 <- a
rButtons:
  db
rButtons_Old:
  db
rButtons_High:
  db

OAMF_hram:
  ds 5
  
SECTION "wram0", WRAM0
OAM_Data_wram:
  ds 160

MACRO setvblanki
  ld hl, VBLANKF_wram + 1
  ld a, LOW(\1)
  ld [hli], a
  ld a, HIGH(\1)
  ld [hli], a
ENDM

;;;;;;;;;;;;;;; LOGO Screens
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
;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;; Spaceship
Ship1_Direction:
  db
Ship1_PosXTimer:  ; Timer: bit 7 direction, bit 6-0 timer
  db
Ship1_PosXTicks:
  db

Ship2_Direction:
  db
Ship2_PosXTimer:
  db
Ship2_PosXTicks:
  db

Frame_Counter: ; Used to repeating actions, like "press start" blinking
  db
;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;
InGame:
  db

GasCount:
  db

TickCount_old:
  db

GasVectorPosition:
  db

VBLANKF_wram:
  ds 3