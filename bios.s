.setcpu "65C02"
.debuginfo
.segment "BIOS"

PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
T1CL = $6004
T1CH = $6005
ACR = $600b
PCR = $600c
IFR = $600d
IER = $600e
ACIA_DATA	= $5000
ACIA_STATUS	= $5001
ACIA_CMD	= $5002
ACIA_CTRL	= $5003


E  = %10000000
RW = %01000000
RES = %00100000


LOAD:
                rts

SAVE:
                rts


; Input a character from the serial interface.
; On return, carry flag indicates whether a key was pressed
; If a key was pressed, the key value will be in the A register
;
; Modifies: flags, A
MONRDKEY:
CHRIN:
                lda     ACIA_STATUS
                and     #$08
                beq     @no_keypressed
                lda     ACIA_DATA
                jsr     CHROUT			; echo
                sec
                rts
@no_keypressed:
                clc
                rts


; Output a character (from the A register) to the serial interface.
;
; Modifies: flags

MONCOUT:
CHROUT:
                pha
                sta     ACIA_DATA
                lda     #$FF
@txdelay:       dec
                bne     @txdelay
                pla
                rts

; Output character to the LCD display
PRNTCHR:
                jsr LCDWAIT
                sta PORTB
                lda #RES         ; Set RS; Clear RW/E bits
                sta PORTA
                lda #(RES | E)   ; Set E bit to send instruction
                sta PORTA
                lda #RES         ; Clear E bits
                sta PORTA
                rts
;delay loop to prevent writing to LCD when busy
LCDWAIT:
                pha
                lda #%00000000  ; Port B is input
                sta DDRB
lcdbusy:
                lda #RW
                sta PORTA
                lda #(RW | E)
                sta PORTA
                lda PORTB
                and #%10000000
                bne lcdbusy

                lda #RW
                sta PORTA
                lda #%11111111  ; Port B is output
                sta DDRB
                pla
                rts
; Send instruction to LCD controller
LCDINSTR:
                jsr LCDWAIT
                sta PORTB
                lda #0         ; Clear RS/RW/E bits
                sta PORTA
                lda #E         ; Set E bit to send instruction
                sta PORTA
                lda #0         ; Clear RS/RW/E bits
                sta PORTA
                rts

;change position of cursor on LCD display, uses X and Y registers as input
POSCUR:
                pha ;preserve A register
                txa
                cpy #1 ;check if 1 is in y register
                bne shift ;jump to shift if previous statement is false
                adc #$3F
shift:
                ora #%10000000 ;setup instruction
                jsr LCDINSTR
                pla
                rts
;test harnesses for wozmon
                LDA $3800
                jsr PRNTCHR
                JMP RESET
                LDA $3800
                jsr LCDINSTR
                JMP RESET
                LDX $3800
                LDY $3801
                JSR POSCUR
                JMP RESET

.include "wozmon.s"

.segment "RESETVEC"
                .word   $0F00           ; NMI vector
                .word   RESET           ; RESET vector
                .word   $0000           ; IRQ vector

