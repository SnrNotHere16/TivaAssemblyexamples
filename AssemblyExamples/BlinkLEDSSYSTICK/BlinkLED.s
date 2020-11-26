;Makes an LED toggle with a 1 second delay. 
;switches make the LED color change from R->B->G
;Mode 1 RED LED 
;Mode 2 BLUE LED 
;Mode 3 GREEN LED 
;MODE 4 R->B->G
;SW1 switches the LED
	IMPORT  Board_Init
	IMPORT LED_Init
	IMPORT  Board_Input
	IMPORT   SysTick_Init
    IMPORT   SysTick_Wait10ms
	IMPORT   PLL_Init
GPIO_PORTF_DIR_R   EQU 0x40025400
GPIO_PORTF_AFSEL_R EQU 0x40025420
GPIO_PORTF_DEN_R   EQU 0x4002551C
GPIO_PORTF_AMSEL_R EQU 0x40025528
GPIO_PORTF_PCTL_R  EQU 0x4002552C
PF0       EQU 0x40025004
PF1       EQU 0x40025008
PF2       EQU 0x40025010
PF3       EQU 0x40025020
PF4       EQU 0x40025040
LEDS      EQU 0x40025038
RED		  EQU 0x02 
BLUE 	  EQU 0x04
GREEN 	  EQU 0x08
DARK      EQU 0x00
SWITCHES  EQU 0x40025044
SW1       EQU 0x10                 ; on the left side of the Launchpad board

        AREA    |.text|, CODE, READONLY, ALIGN=2
        THUMB
        EXPORT  Start
Start


;----------------------------------------------------------------
    BL  Board_Init                  ; initialize PF0 and PF4 and make them inputs
	BL  LED_Init					; initialize PF1-PF3 and make them outputs 
	BL  SysTick_Init   ; enable SysTick
    MOV R5, #RED                    ; R5 = RED (red LED on) the color of the LED register
	MOV R6, #0 						; R7 = 0, R7 is the in charge of monitoring the mode
	STR R5,  [R4]
;Define array
loop
    BL  Board_Input
    CMP R0, #0x01                   ; R0 == 0x01?
    BEQ sw1pressed1                  ; if so, switch 1 pressed
    CMP R0, #0x11                   ; R0 == 0x11?
    BEQ nopressed                   ; if so, neither switch pressed
                                    ; if none of the above, unexpected return value
    STR R9, [R4]                    ; [R4] = R9 = (RED|GREEN|BLUE) (all LEDs on)
    B   loop
sw1pressed1
    ADD R6, R6, #0x01				;R2 = R2+1
	AND R6, R6, #0x03				;R2 = R2&&3 = R2%4
	CMP R6, #0x00
	BEQ mode1 
	CMP R6, #0x01
	BEQ mode2
	CMP R6, #0x02
	BEQ mode3
	CMP R6, #0x03
	BEQ mode4
sw1pressed2
	BL delayMS
    B   loop
nopressed 
	BL  SysTick_Wait10ms
	STR R5, [R4]
	B loop
mode1 ;mode 1 LED color red 
	MOV R7,#0x00	 ;Reset counter of RBG mode 4
	MOV R5, #RED     ;R5 = RED (0x02)
	STR R5, [R4]	;[R4] = R5 = RED (RED LED on)
	B sw1pressed2
mode2 ;mode 2 LED color blue
	LSL R5, R5,#1   ;Shift left R5 by one (assume to be 0x02 before)
	STR R5, [R4]
	B sw1pressed2
mode3 ;mode 3 LED color green 
	LSL R5, R5,#1   ;Shift left R5 by one (assume to be 0x04 before)
	STR R5, [R4]
	B sw1pressed2
mode4 ;mode 4 LED color cycle 
 	MOV R5, #RED  ;Shift R5 right by two (assume to be 0x08 before)
	STR R5, [R4]    ;[R4] = R5 = RED (RED LED on)
	MOV R7,#0x00          ;the counter for the cycle, RBG,
	B sw1pressed2

;performs a delay of n ms. 
;n is the value of R3
; n = 240
;from TI TIVA ARM PROGRAMMING FOR EMBEDDED SYSTEMS
delayMS
	MOV R3, #0xF0				;R3 = 0xF0
	CMP R3, #0x00
	BNE L1							;if n = 0, return 
	BX LR
L1  LDR 	R10, =5336
	; do inner loop 5336 times (for 16 MHz CPU clock)
L2	SUBS R10, R10, #1				;inner loop
	BNE L2
	SUBS R3, R3, #1 				;do outer loop
	BNE L1
	BX LR							;return
	
    ALIGN                           ; make sure the end of this section is aligned
    END                             ; end of file
