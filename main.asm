INCLUDE "definitions/hardware.inc"
INCLUDE "definitions/memory.inc"

SECTION "vblank",ROM0[$40]
VBLANKI:
  jp VBLANKF_wram

VBLANKF_rom:
  jp $0000

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
  ld a, [hTransition]
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
  jr start

SECTION "main", ROM0[$150]
SetSmallMem:
  .loop:
  ld [hli], a
  dec b
  jp nz, .loop
;

start:
  di 

  .waitvblank:
  ld a, [rLY]
  cp 144
  jr c, .waitvblank

  xor	a
  ld [rLCDC], a ; Turn off screen

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
  
InitLogo:
  
  ; Set white screen
  xor a
  ld [rBGP], a

  ; Copy tiles
  ; Copy map

  ; Show screen

  ; Change jump from VBLANK WRAM
  ld hl, VBLANKF_wram + 1
  ld a, LOW(VBLANK_dec_e)
  ld [hli], a
  ld a, HIGH(VBLANK_dec_e)
  ld [hli], a


  ; Clear interrupt flags (needed?)
  xor a; (-) a is already 0
  ld [rIF], a 

  ; Turn on VBlank interrupt
  ld a, IEF_VBLANK; (-) or waitvblank;
  ld [rIE], a
  ei

  ld a, LCDCF_ON | LCDCF_BGON
  ld [rLCDC], a

  call FadeIn

  ld e, 60
  call WaitFrames

  call FadeOut

  .haltloop:
  halt 
  jr .haltloop
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
  jr nz, .stillwaiting
  ret


VBLANK_dec_e:
  dec e
  reti

Init_Title: ; Call it on VBLANK
  di
  
  .waitvblank:
  ld a, [rLY]
  cp 144
  jr c, .waitvblank

  ; Turn off screen and clear transition
	xor	a
  ld [rLCDC], a
  ld [hTransition], a

  ; Clear OAM
  ld hl, _OAMRAM
  ld b, 160
  call SetSmallMem

  ; Copy Duck
  ld de, Duck
  ld hl, $8800
  ld bc, DuckEnd - Duck
  call CopyMem

  ; Copy Tail
  ld de, Tail
  ld hl, $8900
  ld bc, TailEnd - Tail
  call CopyMem

  ; Copy tiles for Screen 2
  ld de, Tiles1
  ld hl, $9c00
  ld bc, Tiles1End - Tiles1
  call CopyMem    
  
  ; Copy tiles for Screen 1
  ld de, Tiles2
  ld hl, $9800
  ld bc, Tiles2End - Tiles2
  call CopyMem
  
  ; Screen1C <- BG at $9800
  ld a, LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_ON
  ld [Screen1C], a

  ; Screen2C <- BG at $9C00
  or LCDCF_BG9C00
  ld [Screen2C], a 
  ld [rLCDC], a ; Turn on creen
  
  ; Set palette
  ld a, %11100100
  ld [rBGP], a
  ld [rOBP0], a
  ld [rOBP1], a

  ; Set MODE0 (hblank) as STAT interrupt
  ld a, STATF_MODE00
  ld [rSTAT], a

  ; Turn on LCDC (STAT) and  VBLANK interupts
  ld a, IEF_LCDC | IEF_VBLANK
  ld [rIE], a
  xor a
  ld [rIF], a ; Clear interrupt flags (needed?)
  ei

  haltLoop:
  halt
  jr haltLoop
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

CopySmallMem: ; de: src, hl: dst, b: size
  ld a, [de]
  ld [hli], a
  inc de
  dec b
  jp nz, CopySmallMem
  ret
;

dmaCopy:
  ld a, $03;HIGH(start address)
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

VBLANK_title:
  call dmaCopy

  push af
  push bc
  push hl

  ; a = SinVec + (position++) <- TODO: align SinVec
  ld hl, Position
  ld c, [hl]
  inc [hl]
  ld hl, SinVec
  ld b, $00
  add hl, bc
  ld a, [hl]
  
  ; Screen2X = a
  ld [Screen2X], a
  
  ; Screen2Y--
  ld hl, Screen2Y
  dec [hl]

  ; Screen1X = 0; Screen1X = 0
  xor a
  ld [Screen1X], a
  ld [Screen1Y], a
  
  ; Increment the transition and reset if = $ff-$90
  ld a, [hTransition]
  inc a
  cp a, $ff - $90
  jr nz, .nreset_a
  xor a
  .nreset_a:
  ld [hTransition], a

  ; Set the screen for the first line
  dec a
  ld h, HIGH(HVector)
  ld l, a
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

  ; Return VBLANKI
  pop hl
  pop bc
  pop af
  reti
;

VBlank_Intro:
  reti 
;

SECTION "Data", ROM0[$300] ; TODO - align
HVector:
  db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff ;   8
  db $ff, $ff, $00, $ff, $ff, $ff, $ff, $ff ;  16
  db $ff, $ff, $00, $ff, $ff, $ff, $ff, $ff ;  24
  db $00, $00, $00, $00, $00, $00, $00, $00 ;  32
  db $00, $00, $00, $00, $00, $00, $00, $00 ;  40
  db $00, $00, $00, $00, $00, $00, $00, $00 ;  48
  db $00, $00, $00, $00, $00, $00, $00, $00 ;  56
  db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff ;  64
  db $ff, $ff, $00, $00, $00, $ff, $00, $ff ;  72
  db $ff, $ff, $00, $ff, $ff, $ff, $00, $ff ;  80
  ;db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff ;  88
  ;db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff ;  96
  ;db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff ; 104
  ;db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff ; 112
  ;db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff ; 120
  ;db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff ; 128
  ;db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff ; 136
  ;db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff ; 144

REPT 26
  db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
ENDR
  
INCLUDE "gfx/duck.inc"
INCLUDE "gfx/tail.inc"
INCLUDE "gfx/tiles.inc"

SinVec:
AMP = 20.0
  FOR N, 256        
      db (MUL(AMP, SIN(N * 256)) + AMP) >> 16
  ENDR
