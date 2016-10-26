;;;;;;;;;;; TODO list ;;;;;;;;;;;
; 1. check if config header is correct
; 2. which registers will we use to save the queue?
; 3. add goSleep functionality (to save energy) and wakeUp when button is pressed
; 4. do we need a reset button?
; 5. external communications:
;   5.1 configure output when button is pressed (printer, etc)
;   5.2 create function to receive request for next in queue from other modules
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
; PIC16F628A Configuration Bit Settings
; ASM source line config statements
#include "P16F688.inc"
; CONFIG
; __config 0xFF19
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF
 
	ORG	0x0000
iCount	EQU	d'241'
mQueue	EQU	h'30'		    ;manager queue register
cQueue	EQU	h'50'		    ;cashier queue register
	
	GOTO	setup				    
	ORG	0x0004		    ;Interruption treatment 	
	BTFSC	INTCON, RAIF	   
	call	buttonInterrupt	    ;PORTA interrupt flag bit set
	RETFIE			    ;Return from interrupt treatment 	    

	
buttonInterrupt:
				    ;Checks which button was pressed 
	BTFSS	PORTA, RA0	     
	call	managerNormalButton	    ;RA0 pressed
	BTFSS	PORTA, RA1	    
	call	managerPriorityButton	    ;RA1 pressed
	BTFSS	PORTA, RA2	    
    	call	cashierNormalButton	    ;RA2 pressed
	BTFSS	PORTA, RB3	
	call	cashierPriorityButton	    ;RA3 pressed

;(Next 4 functions) Buttons pressed. Functions called locally
managerNormalButton:
	;TODO
	RETURN	
managerPriorityButton:
	;TODO
	RETURN
cashierNormalButton:
	;TODO
	RETURN
cashierPriorityButton:
	;TODO
	RETURN

; Called externally (read I/O pin). 
getNextInLine:
	;TODO 
	RETURN

setup:
	;configure ports
	BANKSEL	PORTA
	CLRF	PORTA
	MOVLW	'00000000'	    ;all pins set to digital I/O...
	MOVWF	CMCON0		    ;so there will be no conflict
	BANKSEL	ANSEL		
	CLRF	ANSEL		    
	MOVLW	'00111111'	    ;RA<5:0> as inputs
	
	BANKSEL	PORTA		    ;Interruption setup
	MOVLW	b'11001000'	    ;enable global interruptions, pheriperals and PORTA
	MOVWF	INTCON		    
	
loop:	
	NOP
	GOTO	loop	
	END