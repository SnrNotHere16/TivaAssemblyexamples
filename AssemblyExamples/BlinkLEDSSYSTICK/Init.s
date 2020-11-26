

GPIO_PORTF_DIR_R   EQU 0x40025400
GPIO_PORTF_AFSEL_R EQU 0x40025420
GPIO_PORTF_PUR_R   EQU 0x40025510
GPIO_PORTF_DEN_R   EQU 0x4002551C
GPIO_PORTF_LOCK_R  EQU 0x40025520
GPIO_PORTF_CR_R    EQU 0x40025524
GPIO_PORTF_AMSEL_R EQU 0x40025528
GPIO_PORTF_PCTL_R  EQU 0x4002552C
GPIO_LOCK_KEY      EQU 0x4C4F434B  ; Unlocks the GPIO_CR register
PF0       EQU 0x40025004
PF4       EQU 0x40025040
SWITCHES  EQU 0x40025044
SW1       EQU 0x10                 ; on the left side of the Launchpad board
SW2       EQU 0x01                 ; on the right side of the Launchpad board
;LED Colors 
RED 	  EQU 0x02
BLUE 	  EQU 0x04
GREEN 	  EQU 0x08
LEDS      EQU 0x40025038
;Systick timer 
NVIC_ST_CTRL_R        EQU 0xE000E010
NVIC_ST_RELOAD_R      EQU 0xE000E014
NVIC_ST_CURRENT_R     EQU 0xE000E018
NVIC_ST_CTRL_COUNT    EQU 0x00010000  ; Count flag
NVIC_ST_CTRL_CLK_SRC  EQU 0x00000004  ; Clock Source
NVIC_ST_CTRL_INTEN    EQU 0x00000002  ; Interrupt enable
NVIC_ST_CTRL_ENABLE   EQU 0x00000001  ; Counter mode
NVIC_ST_RELOAD_M      EQU 0x00FFFFFF  ; Counter load value
SYSCTL_RCGCGPIO_R  EQU 0x400FE608
SYSCTL_RCGC2_GPIOF EQU 0x00000020  ; port F Clock Gating Control

        AREA    |.text|, CODE, READONLY, ALIGN=2
        THUMB
        EXPORT  Board_Init
		EXPORT  LED_Init
        EXPORT  Board_Input
		EXPORT   SysTick_Init
        EXPORT   SysTick_Wait
        EXPORT   SysTick_Wait10ms

;------------Board_Init------------
; Initialize GPIO Port F for negative logic switches on PF0 and
; PF4 as the Launchpad is wired.  Weak internal pull-up
; resistors are enabled, and the NMI functionality on PF0 is
; disabled.
; Input: none
; Output: none
; Modifies: R0, R1
Board_Init
    ; activate clock for Port F
    LDR R1, =SYSCTL_RCGCGPIO_R      ; R1 = &SYSCTL_RCGCGPIO_R
    LDR R0, [R1]                    ; R0 = [R1]
    ORR R0, R0, #SYSCTL_RCGC2_GPIOF ; R0 = R0|SYSCTL_RCGC2_GPIOF
    STR R0, [R1]                    ; [R1] = R0
    NOP
    NOP                             ; allow time to finish activating
    ; unlock the lock register
    LDR R1, =GPIO_PORTF_LOCK_R      ; R1 = &GPIO_PORTF_LOCK_R
    LDR R0, =GPIO_LOCK_KEY          ; R0 = GPIO_LOCK_KEY (unlock GPIO Port F Commit Register)
    STR R0, [R1]                    ; [R1] = R0 = 0x4C4F434B
    ; set commit register
    LDR R1, =GPIO_PORTF_CR_R        ; R1 = &GPIO_PORTF_CR_R
    MOV R0, #0xFF                   ; R0 = 0x01 (enable commit for PF0)
    STR R0, [R1]                    ; [R1] = R0 = 0x1
    ; set direction register
    LDR R1, =GPIO_PORTF_DIR_R       ; R1 = &GPIO_PORTF_DIR_R
    LDR R0, [R1]                    ; R0 = [R1]
    BIC R0, R0, #(SW1+SW2)          ; R0 = R0&~(SW1|SW2) (make PF0 and PF4 input; PF0 and PF4 built-in buttons)
    STR R0, [R1]                    ; [R1] = R0
    ; regular port function
    LDR R1, =GPIO_PORTF_AFSEL_R     ; R1 = &GPIO_PORTF_AFSEL_R
    LDR R0, [R1]                    ; R0 = [R1]
    BIC R0, R0, #(SW1+SW2)          ; R0 = R0&~(SW1|SW2) (disable alt funct on PF0 and PF4)
    STR R0, [R1]                    ; [R1] = R0
    ; put a delay here if you are seeing erroneous NMI
    ; enable pull-up resistors
    LDR R1, =GPIO_PORTF_PUR_R       ; R1 = &GPIO_PORTF_PUR_R
    LDR R0, [R1]                    ; R0 = [R1]
    ORR R0, R0, #(SW1+SW2)          ; R0 = R0|(SW1|SW2) (enable weak pull-up on PF0 and PF4)
    STR R0, [R1]                    ; [R1] = R0
    ; enable digital port
    LDR R1, =GPIO_PORTF_DEN_R       ; R1 = &GPIO_PORTF_DEN_R
    LDR R0, [R1]                    ; R0 = [R1]
    ORR R0, R0, #(SW1+SW2)          ; R0 = R0|(SW1|SW2) (enable digital I/O on PF0 and PF4)
    STR R0, [R1]                    ; [R1] = R0
    ; configure as GPIO
    LDR R1, =GPIO_PORTF_PCTL_R      ; R1 = &GPIO_PORTF_PCTL_R
    LDR R0, [R1]                    ; R0 = [R1]
    BIC R0, R0, #0x000F000F         ; R0 = R0&~0x000F000F (clear port control field for PF0 and PF4)
    ADD R0, R0, #0x00000000         ; R0 = R0+0x00000000 (configure PF0 and PF4 as GPIO)
    STR R0, [R1]                    ; [R1] = R0
    ; disable analog functionality
    LDR R1, =GPIO_PORTF_AMSEL_R     ; R1 = &GPIO_PORTF_AMSEL_R
    MOV R0, #0                      ; R0 = 0 (disable analog functionality on PF)
    STR R0, [R1]                    ; [R1] = R0
    BX  LR                          ; return
LED_Init
 ; set direction register
    LDR R1, =GPIO_PORTF_DIR_R       ; R1 = &GPIO_PORTF_DIR_R
    LDR R0, [R1]                    ; R0 = [R1]
    ORR R0, R0, #(RED+BLUE+GREEN)   ; R0 = R0|(RED|BLUE|GREEN) (make PF3-1 output; PF3-1 built-in LEDs)
    STR R0, [R1]                    ; [R1] = R0
    ; regular port function
    LDR R1, =GPIO_PORTF_AFSEL_R     ; R1 = &GPIO_PORTF_AFSEL_R
    LDR R0, [R1]                    ; R0 = [R1]
    BIC R0, R0, #(RED+BLUE+GREEN)   ; R0 = R0&~(RED|BLUE|GREEN) (disable alt funct on PF3-1)
    STR R0, [R1]                    ; [R1] = R0
    ; enable digital port
    LDR R1, =GPIO_PORTF_DEN_R       ; R1 = &GPIO_PORTF_DEN_R
    LDR R0, [R1]                    ; R0 = [R1]
    ORR R0, R0, #(RED+BLUE+GREEN)   ; R0 = R0|(RED|BLUE|GREEN) (enable digital I/O on PF3-1)
    STR R0, [R1]                    ; [R1] = R0
    ; configure as GPIO
    LDR R1, =GPIO_PORTF_PCTL_R      ; R1 = &GPIO_PORTF_PCTL_R
    LDR R0, [R1]                    ; R0 = [R1]
    BIC R0, R0, #0x0000FF00         ; R0 = R0&~0x0000FF00 (clear port control field for PF3-2)
    BIC R0, R0, #0x000000F0         ; R0 = R0&~0x000000F0 (clear port control field for PF1)
    STR R0, [R1]                    ; [R1] = R0
    ; disable analog functionality
    LDR R1, =GPIO_PORTF_AMSEL_R     ; R1 = &GPIO_PORTF_AMSEL_R
    MOV R0, #0                      ; R0 = 0 (disable analog functionality on PF)
    STR R0, [R1]                    ; [R1] = R0
    LDR R4, =LEDS                   ; R4 = &LEDS
	BX  LR                          ; return
;------------Board_Input------------
; Read and return the status of the switches.
; Input: none
; Output: R0  0x01 if only Switch 1 is pressed
;         R0  0x10 if only Switch 2 is pressed
;         R0  0x00 if both switches are pressed
;         R0  0x11 if no switches are pressed
; Modifies: R1
Board_Input
    LDR R1, =SWITCHES               ; R1 = &SWITCHES (pointer to location of PF0 and PF4)
    LDR R0, [R1]                    ; R0 = [R1] (read PF0 and PF4)
    BX  LR                          ; return


;------------SysTick_Init------------
; Initialize SysTick with busy wait running at bus clock.
; Input: none
; Output: none
; Modifies: R0, R1
SysTick_Init
    ; disable SysTick during setup
    LDR R1, =NVIC_ST_CTRL_R         ; R1 = &NVIC_ST_CTRL_R
    MOV R0, #0                      ; R0 = 0
    STR R0, [R1]                    ; [R1] = R0 = 0
    ; maximum reload value
    LDR R1, =NVIC_ST_RELOAD_R       ; R1 = &NVIC_ST_RELOAD_R
    LDR R0, =NVIC_ST_RELOAD_M;      ; R0 = NVIC_ST_RELOAD_M
    STR R0, [R1]                    ; [R1] = R0 = NVIC_ST_RELOAD_M
    ; any write to current clears it
    LDR R1, =NVIC_ST_CURRENT_R      ; R1 = &NVIC_ST_CURRENT_R
    MOV R0, #0                      ; R0 = 0
    STR R0, [R1]                    ; [R1] = R0 = 0
    ; enable SysTick with core clock
    LDR R1, =NVIC_ST_CTRL_R         ; R1 = &NVIC_ST_CTRL_R
                                    ; R0 = ENABLE and CLK_SRC bits set
    MOV R0, #(NVIC_ST_CTRL_ENABLE+NVIC_ST_CTRL_CLK_SRC)
    STR R0, [R1]                    ; [R1] = R0 = (NVIC_ST_CTRL_ENABLE|NVIC_ST_CTRL_CLK_SRC)
    BX  LR                          ; return

;------------SysTick_Wait------------
; Time delay using busy wait.
; Input: R0  delay parameter in units of the core clock (units of 8.333 nsec for 120 MHz clock)
; Output: none
; Modifies: R1, R2, R3
SysTick_Wait
    ; get the starting time (R2)
    LDR R1, =NVIC_ST_CURRENT_R      ; R1 = &NVIC_ST_CURRENT_R
    LDR R2, [R1]                    ; R2 = [R1] = startTime
SysTick_Wait_loop
    ; determine the elapsed time (R3)
    LDR R3, [R1]                    ; R3 = [R1] = currentTime
    SUB R3, R2, R3                  ; R3 = R2 - R3 = startTime - currentTime
    ; handle possible counter roll over by converting to 24-bit subtraction
    AND R3, R3, #0x00FFFFFF
    ; is elapsed time (R3) <= delay (R0)?
    CMP R3, R0
    BLS SysTick_Wait_loop
    BX  LR                          ; return

;------------SysTick_Wait10ms------------
; Time delay using busy wait.  This assumes 120 MHz clock
; Input: R0  number of times to wait 10 ms before returning
; Output: none
; Modifies: R0
DELAY10MS             EQU 1200000   ; clock cycles in 10 ms (assumes 120 MHz clock)
SysTick_Wait10ms
    PUSH {R4, LR}                   ; save current value of R4 and LR
    MOVS R4, R0                     ; R4 = R0 = remainingWaits
    BEQ SysTick_Wait10ms_done       ; R4 == 0, done
SysTick_Wait10ms_loop
    LDR R0, =DELAY10MS              ; R0 = DELAY10MS
    BL  SysTick_Wait                ; wait 10 ms
    SUBS R4, R4, #1                 ; R4 = R4 - 1; remainingWaits--
    BHI SysTick_Wait10ms_loop       ; if(R4 > 0), wait another 10 ms
SysTick_Wait10ms_done
	CMP R6, #0x00
	BEQ toggle1
	CMP R6, #0x01
	BEQ toggle2
	CMP R6, #0x02
	BEQ toggle3
	CMP R6, #0x03
	BEQ toggle4
SysTick_Wait10msdone2
    POP {R4, LR}                    ; restore previous value of R4 and LR
    BX  LR                          ; return
toggle1
	EOR R5, R5, #RED
	B SysTick_Wait10msdone2
toggle2
	EOR R5, R5, #BLUE
	B SysTick_Wait10msdone2
toggle3
	EOR R5, R5, #GREEN
	B SysTick_Wait10msdone2
toggle4 
	EOR R5, R5, R5
    ALIGN                           ; make sure the end of this section is aligned
    END                             ; end of file

