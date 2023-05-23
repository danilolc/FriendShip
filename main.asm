INCLUDE "definitions/hardware.inc"
INCLUDE "definitions/memory.inc"

; TODO - organize function positions
; de may be changed by interruptions

SECTION "begin",ROM0[$0]
VBLANKF_rom:
  jp VBLANK_Nothing ; It'll be copyed to wram

VBLANK_Nothing:
  reti

SECTION "vblank",ROM0[$40]
VBLANKI:
  jp VBLANKF_wram

SECTION "lcdc",ROM0[$48]
LCDI: ; TODO - at line L, enable this interrupt and read a vector directely
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
  ld b, a ; X
  ld a, [hli]
  ld c, a ; Y
  ld a, [hli]
  ld d, a ; S
  ld hl, rSCY
  
  .waitmode3:
  ld a, [rSTAT]
  cpl
  and %11
  jr z, .waitmode3

  ld a, c
  ld [hli], a
  ld a, b
  ld [hl], a
  ld a, d
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

_LCDI_Test:
  push af
  push hl

  ; a = rLY - rLYC
  ld hl, rLY
  ld a, [hli]
  sub [hl]

  ;; Do something

  reti




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

  ; Copy sd tiles ; TODO - create a matro for that (copyasset $8000, SD_tiles)
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

  ; Change jump on VBLANK WRAM - TODO - make a macro (setvblank VBLANK_dec_e)
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

  ; Clear OAM ; TODO - make a macro?
  ; TODO - xor a ?
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

  ; Clear the rest of the tiles
  ld bc, $9c00 - ($9800 + Logo_map_end - Logo_map)
  call ResetMem
  
  ; Copy tiles for Screen 1
  ld de, Stars_map
  ld hl, $9c00
  ld bc, Stars_map_end - Stars_map
  call CopyMem


  ; Copy text tiles
  ld de, Text_tiles
  ld hl, $8800
  ld bc, Text_tiles_end - Text_tiles
  call CopyMem

  ; Copy object tiles
  ld de, Objects_tiles
  ld hl, $8b00
  ld bc, Objects_tiles_end - Objects_tiles
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
  ld a, STATF_MODE10 ;STATF_MODE00
  ld [rSTAT], a

  ; Turn on LCDC (STAT) and VBLANK interupts
  ld a, IEF_LCDC | IEF_VBLANK
  ld [rIE], a
  xor a
  ld [rIF], a ; Clear interrupt flags (needed?)

  call VBLANK_title_in ; Turn on screen and interupts

  .haltLoop: ; Keep here while not in game
  nop;halt - TODO - halt
  ;call DS_Play
  ld a, [InGame]
  bit 0, a
  jr z, .haltLoop

  ;;;;;;;; IN GAME
  .loop
  halt

  ld a, [TickCount_old]
  ld b, a
  ld a, [TickCount]
  ld [TickCount_old], a
  cp b
  jr z, .done  
  add 4
  and %111
  call z, ReadGasVector

  .done:

  ;    <>ba
  ld a, [rButtons_High]
  bit 0, a ; A
  call nz, MoveShip2_Right
  bit 1, a ; B
  call nz, MoveShip2_Left
  bit 2, a ; >
  call nz, MoveShip1_Right
  bit 3, a ; <
  call nz, MoveShip1_Left

  call UpdateShips

  .return:

  call DS_Play
  call UpdateGas

  jr .loop
;

TIME = 20
;%10000000

MoveShip2_Right:
  push af
  ld a, [Ship2_PosXTimer]
  cp a, $0
  jr nz, .return

  ld a, TIME
  ld [Ship2_PosXTimer], a

  ld a, 0
  ld [Ship2_Direction], a

  ld a, [TickCount]
  ld [Ship2_PosXTicks], a

  .return:
  pop af
  ret

MoveShip1_Right:
  push af
  ld a, [Ship1_PosXTimer]
  cp a, $0
  jr nz, .return

  ld a, TIME
  ld [Ship1_PosXTimer], a

  ld a, 0
  ld [Ship1_Direction], a
  
  ld a, [TickCount]
  ld [Ship1_PosXTicks], a

  .return:
  pop af
  ret

MoveShip2_Left:
  push af
  ld a, [Ship2_PosXTimer]
  cp a, $0
  jr nz, .return

  ld a, TIME
  ld [Ship2_PosXTimer], a

  ld a, 1
  ld [Ship2_Direction], a
  
  ld a, [TickCount]
  ld [Ship2_PosXTicks], a
.return:
  pop af
  ret
MoveShip1_Left:
  push af
  ld a, [Ship1_PosXTimer]
  cp a, $0
  jr nz, .return

  ld a, TIME
  ld [Ship1_PosXTimer], a

  ld a, 1
  ld [Ship1_Direction], a
  
  ld a, [TickCount]
  ld [Ship1_PosXTicks], a

  .return:
  pop af
  ret

UpdateShip1:
  ld a, [Ship1_PosXTimer]
  cp 0
  ret z
  sub 2
  ld [Ship1_PosXTimer], a

  ld a, [Ship1_PosXTimer]
  ret

UpdateShip2:
  ld a, [Ship2_PosXTimer]
  cp 0
  ret z
  sub 2
  ld [Ship2_PosXTimer], a

  ld a, [Ship2_PosXTimer]
  ret

UpdateShips:
  call UpdateShip1
  call UpdateShip2

  call MoveShip1
  call MoveShip2
  ret

MoveShip1:

  ld a, [Ship1_PosXTimer]
  ld c, a

  ld a, [Ship1_Direction]
  ld d, a

  ld a, SHIP1X

  dec d
  jr z, .one
  
  add c
  jr .done

  .one:
  
  sub c
  
  .done

  ld hl, OAM_Data_wram + 1 ;SHIP1X
  ld bc, 4

  ld [hl], a
  add hl, bc
  add 8
  ld [hl], a
  add 8
  add hl, bc
  ld [hl], a

  ret







MoveShip2:

  ld a, [Ship2_PosXTimer]
  ld c, a

  ld a, [Ship2_Direction]
  ld d, a

  ld a, SHIP2X

  dec d
  jr z, .one
  
  add c
  jr .done

  .one:
  
  sub c
  
  .done

  ld hl, OAM_Data_wram + $0C + 1 ;SHIP2X
  ld bc, 4

  ld [hl], a
  add hl, bc
  add 8
  ld [hl], a
  add 8
  add hl, bc
  ld [hl], a

  ret




ReadGasVector:

  ; Increment gas vector position
  ld a, [GasVectorPosition]
  ld hl, GasPositions

  inc a
  cp a, GasPositions_end - GasPositions
  jr nz, .dont_reset
  xor a
  .dont_reset
  ld [GasVectorPosition], a

  ld c, a
  ld b, 0
  add hl, bc

  ld hl, GasPositions
  ld c, a
  ld b, 0
  add hl, bc
  ld a, [hl]
  ld e, a

  bit 0, e
  call nz, Spawn_Gas1
  bit 1, e
  call nz, Spawn_Gas2
  bit 2, e
  call nz, Spawn_Gas3
  bit 3, e
  call nz, Spawn_Gas4
  ret

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

LoadPressStart_OAMS:
  ld de, Text_OAMS
  ld b, Text_OAMS_end - Text_OAMS
  jr CopySmallMem ; de: src, hl: dst, b: size

LoadDirection_OAMS:
  ld de, DIRECTION_OAMS
  ld b, DIRECTION_OAMS_end - DIRECTION_OAMS
  jr CopySmallMem ; de: src, hl: dst, b: size

LoadShip1_OAMS:
  ld de, SHIP1_OAMS
  ld b, SHIP1_OAMS_end - SHIP1_OAMS  
  jr CopySmallMem ; de: src, hl: dst, b: size

LoadShip2_OAMS:
  ld de, SHIP2_OAMS
  ld b, SHIP2_OAMS_end - SHIP2_OAMS  
  jr CopySmallMem ; de: src, hl: dst, b: size

LoadGas_OAMS:
  ld de, GAS_OAMS
  ld b, GAS_OAMS_end - GAS_OAMS
  jr CopySmallMem ; de: src, hl: dst, b: size


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
SetScreen1:
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
  ld hl, OAM_Data_wram
  call LoadPressStart_OAMS
  call LoadDirection_OAMS
  call LoadShip1_OAMS
  call LoadShip2_OAMS

  ld a, %00011011
  ld [rOBP0], a
  ld a, %00011011;%11100100
  ld [rOBP1], a
  
  jr .return

  .not_zero:
  inc [hl]
  add a
  ld [Screen1Y], a

  .return

  call SetScreen2XY
  call SetScreen1


  ; Return VBLANK_title
  pop hl
  pop af
  reti
;

ClearOAMEntries: ; b - entries, hl - position
  xor a
  sla b
  sla b
  call SetSmallMem
  ret

VBLANK_title_wait:
  push af
  push hl 
  
  call dmaCopy
  call SetScreen2XY
  call SetScreen2

  ld a, [Frame_Counter]
  bit 4, a
  jr z, .pal2

  ld a, %00011111
  ld [rOBP0], a

  jr .endpal

  .pal2:

  ld a, %00001010
  ld [rOBP0], a

  .endpal:

  call ReadStartButton
  jr nz, .no_start

  setvblanki VBLANK_title_out

  ld hl, OAM_Data_wram
  call LoadShip1_OAMS
  call LoadShip2_OAMS

  ;;ld b, 12
  ;;call ClearOAMEntries
  ld c, 16
  .loop:
  call LoadGas_OAMS
  dec c
  jr nz, .loop

  .no_start

  pop hl
  pop af
  reti
;

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

  xor a
  ld [GasCount], a
  ld [TickCount_old], a
  ld [GasVectorPosition], a

  ld [Ship1_Direction], a
  ld [Ship1_PosXTimer], a
  ld [Ship2_Direction], a
  ld [Ship2_PosXTimer], a


  ld a, IEF_VBLANK
  ld [rIE], a

  ld a, 3  ; replace SongID with the ID of the song you want to load
  call DS_Init

  ret
;

VBLANK_in_game:

  call dmaCopy

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
;00000000 <- a
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
  ld b, a
  ; b <- current buttons

  ld a, [rButtons]
  ld [rButtons_Old], a

  cpl
  and b
  ld [rButtons_High], a

  ld a, b
  ld [rButtons], a

  ret



UpdateGas:
  ld a, [GasCount]

  ld hl, OAM_Data_wram + $18
  ld bc, 4
  
  .loop
  ld a, [hl] ; Y position
  cp 0
  jr z, .next

  ;; update gas
  inc a
  inc a
  cp 161
  jr c, .not_finished  

  ;; GO BACK TO TITLE
  ;di
  ;call WaitAndShutdownScreen
  ;call DS_Stop
  ;call Init_Title

  ld a, [GasCount]
  dec a
  ld [GasCount], a
  xor a

  .not_finished

  call CompareDistanceFromShips

  ld [hl], a
  add hl, bc
  ld [hl], a
  add hl, bc

  jr .checkend

  .next
  add hl, bc
  add hl, bc
  
  .checkend
  ; if l == end, return
  ld a, $18 + (16 * 8)
  cp l
  ret z

  jr .loop


; hl gas
CompareDistanceFromShips:
  ret

DIST = 26
POS1 = 40 + 4
POS2 = 110 + 4

Spawn_Gas1:
  call Spawn_Gas
  
  ld a, $01
  ld [hli], a ; Y
  ld a, POS1 - DIST
  ld [hli], a ; X

  inc l
  inc l
  ld a, $01
  ld [hli], a ; Y
  ld a, POS1 - DIST + 8
  ld [hli], a ; X
  ret
  
Spawn_Gas2:
  call Spawn_Gas
  
  ld a, $01
  ld [hli], a ; Y
  ld a, POS1 + DIST
  ld [hli], a ; X

  inc l
  inc l
  ld a, $01
  ld [hli], a ; Y
  ld a, POS1 + DIST + 8
  ld [hli], a ; X
  ret

Spawn_Gas3:
  call Spawn_Gas
  
  ld a, $01
  ld [hli], a ; Y
  ld a, POS2 - DIST
  ld [hli], a ; X

  inc l
  inc l
  ld a, $01
  ld [hli], a ; Y
  ld a, POS2 - DIST + 8
  ld [hli], a ; X
  ret

Spawn_Gas4:
  call Spawn_Gas
  
  ld a, $01
  ld [hli], a ; Y
  ld a, POS2 + DIST
  ld [hli], a ; X

  inc l
  inc l
  ld a, $01
  ld [hli], a ; Y
  ld a, POS2 + DIST + 8
  ld [hli], a ; X
  ret

Spawn_Gas:
  ld a, [GasCount]
  cp 16
  ret z

  inc a
  ld [GasCount], a

  ld bc, 8
  ld hl, OAM_Data_wram + $18
  ld d, 0 ; free gas index

  .loop
    ld a, [hl]
    cp $00
    jr z, .found_free_gas
    add hl, bc ; hl += 8
    inc d

    ; if d == 16 return No free gas
    ld a, 16
    cp d
    ret z

  jr .loop

  .found_free_gas: ; at d
  ret


VBlank_Intro:
  reti 
;

SECTION "Data", ROM0[$700] ; TODO - remove this thing
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

SinVec: ; TODO - align at the end of ROM
AMP = 15.0
  FOR N, 256        
      db (MUL(AMP, SIN(N * 256)) + AMP) >> 16
  ENDR


GasPositions:

  db  %1000, %0001, %1000, %0001
  db  %0001, %1000, %0001, %0001

  db  %1000, %0001, %1000, %0001
  db  %0001, %1000, %0001, %0001

  db  %1001, %0100, %1001, %0010
  db  %0010, %1001, %0100, %1001

  db  %0101, %1010, %0101, %1010
  db  %1010, %0101, %1010, %0101

GasPositions_end:

;; SPLASH
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


;; INTRO
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



;; OAM
Text_tiles: ; $8800 (first index $80)
  INCBIN "oam/text.2bpp"
Text_tiles_end:

Objects_tiles:
  INCBIN "oam/objects.2bpp"
Objects_tiles_end:



Text_OAMS:
POSX = 55
POSY = 85
INDEX1 = $A0
ATT = %00000000 ; att 7 - bellow bg, 6 - Y flip, 5 - X flip, 4 - palette
    FOR N, 8
      db POSY 
      db POSX + N*8 
      db INDEX1 + N*2 
      db ATT
    ENDR
Text_OAMS_end:


SHIP1X = 40
SHIP2X = 110
SHIPY = 120

DIRECTION_OAMS:
DIST = 22
ATT = 0
A_OAM:
    db SHIPY + 5
    db SHIP2X + DIST + 8
    db $C8
    db ATT   
  A_OAM_end:
  B_OAM:
    db SHIPY + 5
    db SHIP2X - DIST + 8
    db $CA 
    db ATT   
  B_OAM_end:
  L_OAM:
    db SHIPY + 5
    db SHIP1X - DIST + 8
    db $CC 
    db ATT   
  L_OAM_end:
  R_OAM:
    db SHIPY + 5
    db SHIP1X + DIST + 8
    db $CE 
    db ATT   
  R_OAM_end:
DIRECTION_OAMS_end:

SHIP1_OAMS:
POSY = 120
INDEX1 = $B0
ATT = %00010000 ; att 7 - bellow bg, 6 - Y flip, 5 - X flip, 4 - palette
  FOR N, 3
    db POSY 
    db SHIP1X + N*8 
    db INDEX1 + N*2 
    db ATT  
  ENDR
SHIP1_OAMS_end:

SHIP2_OAMS:
POSX = 110
POSY = 120
INDEX1 = $B6
ATT = %00010000 ; att 7 - bellow bg, 6 - Y flip, 5 - X flip, 4 - palette
  FOR N, 3
    db POSY 
    db SHIP2X + N*8 
    db INDEX1 + N*2 
    db ATT   
  ENDR
SHIP2_OAMS_end:

GAS_OAMS:
ATT = %00010000 ; att 7 - bellow bg, 6 - Y flip, 5 - X flip, 4 - palette
  FOR N, 2
    db 0 
    db 0 
    db $C4 + N*2 
    db ATT   
  ENDR
GAS_OAMS_end:

HEARH_OAMS:
ATT = %00010000 ; att 7 - bellow bg, 6 - Y flip, 5 - X flip, 4 - palette
  FOR N, 2
    db 0 
    db 0 
    db $BE + N*2 
    db ATT   
  ENDR
HEARH_OAMS_end:

include "DevSound/DevSound.asm"