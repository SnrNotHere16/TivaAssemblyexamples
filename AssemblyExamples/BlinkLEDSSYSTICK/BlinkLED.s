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
    MOV R5, #RED                    ; R5 = RED (red LED on)
    MOV R6, #BLUE                   ; R6 = BLUE (blue LED on)
    MOV R7, #GREEN                 	; R7 = 0, intialize counter
	MOV R9, #DARK
	STR R5,  [R4]
;Define array
loop
    BL  Board_Input
    CMP R0, #0x01                   ; R0 == 0x01?
    BEQ sw1pressed                  ; if so, switch 1 pressed
    CMP R0, #0x11                   ; R0 == 0x11?
    BEQ nopressed                   ; if so, neither switch pressed
                                    ; if none of the above, unexpected return value
    STR R9, [R4]                    ; [R4] = R9 = (RED|GREEN|BLUE) (all LEDs on)
    B   loop
sw1pressed
    STR R6, [R4]                    ; [R4] = R6 = BLUE (blue LED on)
    B   loop
nopressed 
	
	B loop


;performs a delay of n ms. 
;n is the value of R3
; n = 48
;from TI TIVA ARM PROGRAMMING FOR EMBEDDED SYSTEMS
delayMS
	MOV R3, #0x30				;R3 = 0x05
	CMP R3, #0x00
	BNE L1							;if n = 0, return 
;	B bothpressedfin
L1  LDR 	R10, =5336
	; do inner loop 5336 times (for 16 MHz CPU clock)
L2	SUBS R10, R10, #1				;inner loop
	BNE L2
	SUBS R3, R3, #1 				;do outer loop
	BNE L1
;	B bothpressedfin							;return
	
    ALIGN                           ; make sure the end of this section is aligned
    END                             ; end of file
