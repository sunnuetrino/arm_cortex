;/*****************************************************************************/
; OSasm.s: low-level OS commands, written in assembly                       */
; Runs on LM4F120/TM4C123/MSP432
; Lab 2 starter file
; February 10, 2016
;


        AREA |.text|, CODE, READONLY, ALIGN=2
        THUMB
        REQUIRE8
        PRESERVE8

        EXTERN  RunPt            ; currently running thread
        EXPORT  StartOS
        EXPORT  SysTick_Handler
        IMPORT  Scheduler


SysTick_Handler                ; 1) Saves R0-R3,R12,LR,PC,PSR
    CPSID   I                  ; 2) Prevent interrupt during switch
	PUSH   {R4-R11}            ; 3) Stack pointer is on pointing to R0
    LDR    R1,=RunPt           ; 4) R1 has RunPt, RunPt -> tcbX
    LDR    R0, [R1]            ; 5) Now Ro has the sp of the current tcb, first member of tcbX
    STR    SP,[R0]   	       ; 6) Store the current stack pointer to tcb->sp
	; Assembly way of switching from one task to next ( round robin)
	;LDR    R0,[R0,#4]          ; 7) R0 has tcb->next
	; Change RunPt in the C routine
	; While brancing R0-R3 and R12 are modifiable so push to the stacl
	; we will push R1 and LR. Since current LR will be overwritten
	PUSH   {R1,LR}
	BL     Scheduler
	POP    {R1,LR}
	; R1 still has the address of RunPt. so get the value of RunPt to R0
	LDR    R0,[R1]             ; 8) run Pt = tcb->next from the previous step
	;Load Stack pointer
	LDR    SP,[R0]             ; 9) Now load tcb-> next[1] to SP
    POP    {R4-R11} 	       ; 10) Pop the stack and return from the interrupt which will pop the other registers
    CPSIE   I                  ; 9) tasks run with interrupts enabled
    BX      LR                 ; 10) restore R0-R3,R12,LR,PC,PSR

StartOS

    CPSID   I                  ; Disable the interrupts for now
    LDR R1,=RunPt              ; Get the runptr Address
	LDR R0,[R1]                ; Value of RunPt to Ro
    LDR SP,[R0]                ; SP becomes tcb[0]->sp
    POP {R4-R11}               ; Pop the registers
    POP {R0-R3}                ; Poping.. 
    POP {R12}                  ; Poping
    ADD SP,SP,#4               ; Skip the LR for now, we will have to write LR to PC later
    POP {LR}                   ; LR is set to the function pointer of Task0, so when task exits it jumps to task0 
 	ADD     SP, SP, #4         ; discard PSR
    CPSIE   I                  ; Enable interrupts at processor level
    BX      LR                 ; start first thread

    ALIGN
    END
