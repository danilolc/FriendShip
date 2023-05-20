INCLUDE "definitions/hardware.inc"
INCLUDE "definitions/memory.inc"

SECTION "vblank",ROM0[$40]
VBLANKI:
;  jp VBLANK_dec_e
  jp VBLANKF_wram

VBLANKF_rom:
  jp VBLANK_Nothing ; It'll be copyed to wram

VBLANK_Nothing:
  reti

SECTION "lcdc",ROM0[$48]
LCDI:
  jr _LCDI
  
SECTION "timer",ROM0[$50]
Timer:
	reti

_LCDI:
  push af
  push hl
  
  ; a = rLY + transition
  ld a, [rLogoTransition]
  ld l, a
  ld a, [rLY]
  add l
  
  ; hl = HVector + a
  ld h, HIGH(HVector)
  ld l, a
  
  ; Compare a and hl
  cp [hl]
  jr nc, .00

  .ff: ; a < hl
  ld hl, Screen2X
  jr .setvalues

  .00: ; a > hl
  ld hl, Screen1X
  
  .setvalues:
  ld a, [hli]
  ld [rSCX], a
  ld a, [hli]
  ld [rSCY], a
  ld a, [hli]
  ld [rLCDC], a

  ; Return LCDI
  pop hl
  pop af
  reti
;

SECTION "entry", ROM0[$100]
  di
  jr start

SECTION "main", ROM0[$150]
SetSmallMem:
  .loop:
  ld [hli], a
  dec b
  jp nz, .loop
  ret
;

ResetMem: ; hl: start, bc: size
  .loop
  xor a
  ld [hli], a
  dec bc
  ld a, b
  or c
  jr nz, .loop
  ret

start:
  call WaitAndShutdownScreen

  ; Copy DMA function to HRAM
  ld de, OAMF_rom
  ld hl, OAMF_hram
  ld b, 5
  call CopySmallMem

  ; Copy VBlank jump to WRAM
  ld de, VBLANKF_rom
  ld hl, VBLANKF_wram
  ld b, 3
  call CopySmallMem

  jr InitLogo

WaitAndShutdownScreen:
  .waitvblank:
  ld a, [rLY]
  cp 144
  jr c, .waitvblank

  xor	a
  ld [rLCDC], a ; Turn off screen
  ret
;

InitLogo:
  
  ; Set white screen
  xor a
  ld [rBGP], a

  ; Copy sd tiles
  ld de, SD_tiles
  ld hl, $8000
  ld bc, SD_tiles_end - SD_tiles
  call CopyMem
  
  ; Copy map
  ld de, SD_map
  ld hl, $9800
  ld bc, SD_map_end - SD_map
  call CopyMem

  ; Copy penguin tiles
  ld de, Penguin_tiles
  ld hl, $9000 - $400
  ld bc, Penguin_tiles_end - Penguin_tiles
  call CopyMem

  ; Copy penguin map
  ld de, Penguin_map
  ld hl, $9C00
  ld bc, Penguin_map_end - Penguin_map
  call CopyMemSub64 ; TODO - subtract 64 on the rom

  ; Change jump on VBLANK WRAM
  ld hl, VBLANKF_wram + 1
  ld a, LOW(VBLANK_dec_e)
  ld [hli], a
  ld a, HIGH(VBLANK_dec_e)
  ld [hli], a

  ; Start screen
  ld a, LCDCF_BGON | LCDCF_ON | LCDCF_BG8800 | LCDCF_BG9C00
  ld [rLCDC], a
  
  ; Clear interrupt flags (needed?)
  xor a; (-) a is already 0
  ld [rIF], a 

  ; Turn on VBlank interrupt
  ld a, IEF_VBLANK; (-) or waitvblank;
  ld [rIE], a
  ei

  ; Intro events
  call FadeIn

  ld e, 60
  call WaitFrames

  call FadeOut

  ;ld e, 30
  ;call WaitFrames
  ; Change screen
  ld a, LCDCF_BGON | LCDCF_ON | LCDCF_BG8000 | LCDCF_BG9800
  ld [rLCDC], a

  call FadeIn

  ld e, 60
  call WaitFrames

  call FadeOut
  
  ld e, 10
  call WaitFrames

  di
  call WaitAndShutdownScreen

  jr Init_Title
;

FadeOut: ; VBlank must be "dec e"
  ld e, 4
  call WaitFrames
  ld a, %10010000
  ld [rBGP], a

  ld e, 4
  call WaitFrames
  ld a, %01000000
  ld [rBGP], a

  ld e, 4
  call WaitFrames
  ld a, %00000000
  ld [rBGP], a

  ret
;

FadeIn:
  ld e, 4
  call WaitFrames
  ld a, %01000000
  ld [rBGP], a

  ld e, 4
  call WaitFrames
  ld a, %10010000
  ld [rBGP], a

  ld e, 4
  call WaitFrames
  ld a, %11100100
  ld [rBGP], a

  ret
;

WaitFrames:
  .stillwaiting
  halt
  xor a
  cp e
  jr nz, .stillwaiting
  ret
;

VBLANK_dec_e:
  dec e
  reti
;

Init_Title: ; Call it on VBLANK

  ; Clear OAM
  ld hl, _OAMRAM
  ld b, 160
  call SetSmallMem

  ; Clear OAM at WRAM
  ld hl, OAM_Data_wram
  ld b, 160
  call SetSmallMem
  
  ; Copy stars tiles
  ld de, Stars_tiles
  ld hl, $9000
  ld bc, Stars_tiles_end - Stars_tiles
  call CopyMem

  ; Copy logo tiles
  ld de, Logo_tiles
  ld hl, $8000
  ld bc, Logo_tiles_end - Logo_tiles
  call CopyMem

  ; Copy logo map
  ld de, Logo_map
  ld hl, $9800
  ld bc, Logo_map_end - Logo_map
  call CopyMem

  ld bc, $9c00 - ($9800 + Logo_map_end - Logo_map)
  call ResetMem
  
  ; Copy tiles for Screen 1
  ld de, Stars_map
  ld hl, $9c00
  ld bc, Stars_map_end - Stars_map
  call CopyMem

  xor a
  ld [Screen1X], a
  ld [Screen1Y], a
  ld [Screen2X], a
  ld [Screen2Y], a
  ld [Frame_Counter], a
  ld [InGame], a
  ld [rButtons], a

  ld a, $90
  ld [rLogoTransition], a

  ; Clear OAM
  ld hl, _OAMRAM
  ld b, 160
  call SetSmallMem

  ; Screen1C <- BG at $9800
  ld a, LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_ON | LCDCF_BG8000
  ld [Screen1C], a

  ; Screen2C <- BG at $9C00
  ld a, LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_ON | LCDCF_BG9C00
  ld [Screen2C], a 
  ;ld [rLCDC], a ; Turn on creen
  
  ; Set palette
  ld a, %11100100
  ld [rBGP], a
  ld [rOBP0], a
  ld [rOBP1], a

  ; Change vblank to title
  setvblanki VBLANK_title_in

  ; Set MODE0 (hblank) as STAT interrupt
  ld a, STATF_MODE00
  ld [rSTAT], a

  ; Turn on LCDC (STAT) and VBLANK interupts
  ld a, IEF_LCDC | IEF_VBLANK
  ld [rIE], a
  xor a
  ld [rIF], a ; Clear interrupt flags (needed?)

  call VBLANK_title_in ; Turn on screen and interupts

  .haltLoop: ; Keep here while not in game
  halt
  ld a, [InGame]
  bit 0, a
  jr z, .haltLoop

  .loop
  halt
  jr .loop
;

CopyMem: ; de: src, hl: dst, bc: size
  ld a, [de]
  ld [hli], a
  inc de
  dec bc
  ld a, b
  or a, c
  jp nz, CopyMem
  ret
;

CopyMemSub64: ; Copy memery subtracting 64 from it (it should never exist, change on ROM)
  ld a, [de]
  sub 64
  ld [hli], a
  inc de
  dec bc
  ld a, b
  or a, c
  jp nz, CopyMemSub64
  ret

CopySmallMem: ; de: src, hl: dst, b: size
  ld a, [de]
  ld [hli], a
  inc de
  dec b
  jp nz, CopySmallMem
  ret
;

dmaCopy:
  ld a, HIGH(OAM_Data_wram)
  ld bc, $2846  ; B: wait time; C: LOW($FF46)
  jp OAMF_hram
;

OAMF_rom:
  ld [$ff00 + c], a
  .wait
  dec b
  jr nz, .wait
  ret
;

SetScreen2XY: ; x = sin, y = -frame_counter
  ; Increment frame counter
  push bc

  ld hl, Frame_Counter
  ld c, [hl]
  inc [hl]

  ; a = SinVec + counter <- TODO: align SinVec
  ld hl, SinVec
  ld b, $00
  add hl, bc
  ld a, [hl]
  
  ; Screen2X = sin
  ld [Screen2X], a

  ; Screen2Y = - frame counter
  xor a
  sub c
  ld [Screen2Y], a

  pop bc
  ret

SetScreen2:
  ld hl, Screen2X
  ld a, [hli]
  ld [rSCX], a
  ld a, [hli]
  ld [rSCY], a
  ld a, [hli]
  ld [rLCDC], a
  ret

VBLANK_title_in:
  call dmaCopy

  push af
  push hl
  
  ; Increment the transition until it reacher $00
  ld hl, rLogoTransition
  ld a, [hl]
  cp $00
  jr nz, .not_zero
  
  setvblanki VBLANK_title_wait
  jr .return

  .not_zero:
  inc [hl]
  add a
  ld [Screen1Y], a

  .return

  call SetScreen2XY
  call SetScreen2

  ; Return VBLANK_title
  pop hl
  pop af
  reti
;

VBLANK_title_wait:
  push af
  push hl 
  
  call SetScreen2XY
  call SetScreen2

  call ReadStartButton
  jr nz, .no_start

  setvblanki VBLANK_title_out

  .no_start

  pop hl
  pop af
  reti

VBLANK_title_out:
  call dmaCopy

  push af
  push hl
  
  ; Increment the transition until it reacher $00
  ld hl, rLogoTransition
  ld a, [hl]
  cp $50
  jr nz, .not_zero
  
  setvblanki VBLANK_in_game
  call Init_in_game
  
  jr .return

  .not_zero:
  inc [hl]
  inc [hl]
  srl a
  ld [Screen1Y], a

  .return:
  call SetScreen2XY
  call SetScreen2

  ; Return VBLANK_title
  pop hl
  pop af
  reti
;

Init_in_game:
  
  ld a, $01
  ld [InGame], a

  ld a, IEF_VBLANK
  ld [rIE], a

  ret


VBLANK_in_game:
  call ReadShipMoveButton
  call SetScreen2XY
  call SetScreen2
  
  reti









ReadStartButton:
  ld hl, rP1

  ld [hl], P1F_GET_BTN
  ld a, [hl]
  ld a, [hl]
  ld a, [hl]
  ld a, [hl]
  ld a, [hl]

  ld [hl], P1F_GET_NONE

  bit PADB_START, a
  ret

;    <>ba
;00000000
ReadShipMoveButton:
  ld hl, rP1

  ld [hl], P1F_GET_BTN
  ld a, [hl]
  ld a, [hl]
  ld a, [hl]
  ld a, [hl]
  ld a, [hl]

  cpl
  and %11
  ld b, a

  ld [hl], P1F_GET_DPAD
  ld a, [hl]
  ld a, [hl]
  ld a, [hl]
  ld a, [hl]
  ld a, [hl]

  ld [hl], P1F_GET_NONE

  cpl
  and %11
  rla
  rla
  add b

  ld [rButtons], a

  ret












VBlank_Intro:
  reti 
;

SECTION "Data", ROM0[$400] ; TODO - align
HVector:
  db $ff, $ff, $00, $ff, $00, $00, $00, $00 ;   8
  db $00, $00, $00, $00, $00, $00, $00, $00 ;  16
  db $00, $00, $00, $00, $00, $00, $00, $00 ;  24
  db $00, $00, $00, $00, $00, $00, $00, $00 ;  32
  db $00, $00, $00, $00, $00, $00, $00, $00 ;  40
  db $00, $00, $00, $00, $00, $00, $00, $00 ;  48
  db $00, $00, $00, $00, $00, $00, $00, $00 ;  56
  db $00, $00, $00, $00, $00, $00, $00, $00 ;  64
  db $00, $00, $ff, $00, $ff, $00, $ff, $ff ;  72
  db $00, $00, $ff, $ff, $00, $ff, $00, $ff ;  80

REPT 24
  db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
ENDR

SinVec:
AMP = 15.0
  FOR N, 256        
      db (MUL(AMP, SIN(N * 256)) + AMP) >> 16
  ENDR

SD_tiles: 
  INCBIN "build/sd_tiles.bin"
SD_tiles_end: 

SD_map:   
  INCBIN "build/sd_map.bin"   
SD_map_end:

Penguin_map:   
  INCBIN "build/penguin_map.bin"   
Penguin_map_end:

Penguin_tiles: 
  INCBIN "build/penguin_tiles.bin"
Penguin_tiles_end:


Stars_tiles: 
  INCBIN "build/stars_tiles.bin"
Stars_tiles_end:
Stars_map: 
  INCBIN "build/stars_map.bin"
Stars_map_end:

Logo_tiles: 
  INCBIN "build/logo_tiles.bin"
Logo_tiles_end:
Logo_map: 
  INCBIN "build/logo_map.bin"
Logo_map_end:
