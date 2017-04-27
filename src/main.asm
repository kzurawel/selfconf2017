.include "constants.asm"
.include "header.asm"

.segment "ZEROPAGE"
ball_x:     .res 1
ball_y:     .res 1
ball_left:  .res 1
ball_right: .res 1
ball_up:    .res 1
ball_down:  .res 1
ship_x:     .res 1
ship_y:     .res 1
up_pressed: .res 1
down_pressed: .res 1
left_pressed: .res 1
right_pressed: .res 1

.segment "BSS"

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.proc reset_handler
  SEI
  CLD
  LDX #$00
  STX PPUCTRL
  STX PPUMASK
  STX $4010
  DEX
  TXS

  BIT PPUSTATUS

  BIT $4015
  LDA #$40
  STA $4017
  LDA #$0f
  STA $4015

vblankwait:
  BIT PPUSTATUS
  BPL vblankwait

  LDX #$00
  LDA #$ff
clear_oam:
  STA $0200,x
  INX
  INX
  INX
  INX
  BNE clear_oam

  LDA #$00
clear_zeropage:
  STA $00,x
  INX
  BNE clear_zeropage

  LDA #$5f
  STA ball_y
  LDA #$08
  STA ball_x
  LDA #$01
  STA ball_right
  STA ball_down
  LDA #$00
  STA ball_up
  STA ball_left
  LDA #$80
  STA ship_y
  LDA #$80
  STA ship_x

vblankwait2:
  BIT PPUSTATUS
  BPL vblankwait2

  JMP main
.endproc

.proc nmi_handler
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA

  JSR read_controller
  JSR update_ball
  JSR update_ship
  RTI
.endproc

.proc main
  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$00
  STX PPUADDR

copy_palettes:
  LDA palettes,x
  STA PPUDATA
  INX
  CPX #$20
  BNE copy_palettes

vblankwait:
  BIT PPUSTATUS
  BPL vblankwait

  lda PPUSTATUS
  lda #$20
  sta PPUADDR
  lda #$00
  sta PPUADDR
  ldx #$00

load_nametables:
  lda nametable,x
  sta PPUDATA
  inx
  cpx #$e0
  bne load_nametables

  lda PPUSTATUS
  lda #$23
  sta PPUADDR
  lda #$c0
  sta PPUADDR
  ldx #$00

load_attributes:
  lda attributes,x
  sta PPUDATA
  inx
  cpx #$0e
  bne load_attributes

  LDA #%10010000
  STA PPUCTRL
  LDA #%00011110
  STA PPUMASK

forever:
  JSR read_controller
  JSR draw_ball
  JSR draw_ship
  JMP forever
.endproc

draw_ball:
  lda ball_y
  sta $0204
  lda #$04
  sta $0205
  lda #%00000010
  sta $0206
  lda ball_x
  sta $0207
  lda ball_y
  sta $0208
  lda #$04
  sta $0209
  lda #%01000010
  sta $020a
  lda ball_x
  clc
  adc #$08
  sta $020b
  lda ball_y
  clc
  adc #$08
  sta $020c
  lda #$04
  sta $020d
  lda #%10000010
  sta $020e
  lda ball_x
  sta $020f
  lda ball_y
  clc
  adc #$08
  sta $0210
  lda #$04
  sta $0211
  lda #%11000010
  sta $0212
  lda ball_x
  clc
  adc #$08
  sta $0213
  rts

draw_ship:
  lda ship_y ; all y-movement
  sta $0214
  sta $0218
  clc
  adc #$08
  sta $021c
  sta $0220

  ; all tiles
  lda #$05
  sta $0215
  lda #$06
  sta $0219
  lda #$07
  sta $021d
  lda #$08
  sta $0221

  lda #$00 ; all flags
  sta $0216
  sta $021a
  sta $021e
  sta $0222

  lda ship_x ; all x-movement
  sta $0217
  sta $021f
  clc
  adc #$08
  sta $021b
  sta $0223
  rts

update_ball:
  lda ball_right
  beq ball_right_done
  lda ball_x
  clc
  adc #$01
  sta ball_x
  cmp #$ef
  bcc ball_right_done
  lda #$00
  sta ball_right
  lda #$01
  sta ball_left
ball_right_done:
  
  lda ball_left
  beq ball_left_done
  lda ball_x
  sec
  sbc #$01
  sta ball_x
  cmp #$04
  bcs ball_left_done
  lda #$00
  sta ball_left
  lda #$01
  sta ball_right
ball_left_done:

  lda ball_up
  beq ball_up_done
  lda ball_y
  sec
  sbc #$01
  sta ball_y
  cmp #$08
  bcs ball_up_done
  lda #$00
  sta ball_up
  lda #$01
  sta ball_down
ball_up_done:

  lda ball_down
  beq ball_down_done
  lda ball_y
  clc
  adc #$01
  sta ball_y
  cmp #$d8
  bcc ball_down_done
  lda #$00
  sta ball_down
  lda #$01
  sta ball_up
ball_down_done:
  rts

update_ship:
  lda up_pressed
  cmp #$01
  bne done_up
  lda ship_y
  sec
  sbc #$01
  sta ship_y
done_up:
  lda down_pressed
  cmp #$01
  bne done_down
  lda ship_y
  clc
  adc #$01
  sta ship_y
done_down:
  lda right_pressed
  cmp #$01
  bne done_right
  lda ship_x
  clc
  adc #$01
  sta ship_x
done_right:
  lda left_pressed
  cmp #$01
  bne done_left
  lda ship_x
  sec
  sbc #$01
  sta ship_x
done_left:
  rts

read_controller:
  lda #$01
  sta PAD1
  lsr a
  sta PAD1

  lda PAD1
  lda PAD1
  lda PAD1
  lda PAD1
  lda PAD1
  and #$01
  sta up_pressed
  lda PAD1
  and #$01
  sta down_pressed
  lda PAD1
  and #$01
  sta left_pressed
  lda PAD1
  and #$01
  sta right_pressed
  rts


.segment "RODATA"
palettes:
.byte $21, $00, $10, $30
.byte $21, $01, $0f, $31
.byte $21, $06, $16, $26
.byte $21, $09, $19, $29

.byte $21, $00, $10, $30
.byte $21, $01, $0f, $31
.byte $21, $06, $16, $26
.byte $21, $09, $19, $29

nametable:
.byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
.byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff

.byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
.byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff

.byte $ff, $0b, $08, $0f, $0f, $12, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
.byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff

.byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
.byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff

.byte $ff, $16, $08, $0f, $09, $ff, $06, $12, $11, $09, $08, $15, $08, $11, $06, $08
.byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff

.byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
.byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff

.byte $ff, $20, $1e, $1f, $25, $28, $28, $28, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
.byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff

attributes:
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CHR"
.incbin "font.chr"
