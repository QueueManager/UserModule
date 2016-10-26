;;;;;;;;;;; TODO list ;;;;;;;;;;;
; 1. check if config header is correct
; 2. which registers will we use to save the queue?
; 3. add goSleep functionality (to save energy) and wakeUp when button is pressed
; 4. do we need a reset button?
; 5. external communications:
;   5.1 configure output when button is pressed (printer, etc)
;   5.2 create function to receive request for next in queue from other modules
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
; PIC16F883 Configuration Bit Settings
; ASM source line config statements
#include "p16F883.inc"
; CONFIG1
; __config 0xFFFC
__CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_ON & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_ON
; CONFIG2
; __config 0xFFFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
 
	ORG	0x0000
iCount	EQU	d'241'
mQueue	EQU	h'30'		    ;manager queue register
cQueue	EQU	h'50'		    ;cashier queue register
	
	GOTO	setup				    
	ORG	0x0004		    ;Interruption treatment 	
	BTFSC	INTCON, RBIF	   
	call	buttonInterrupt	    ;PORTA interrupt flag bit set
	RETFIE			    ;Return from interrupt treatment 	    

	
buttonInterrupt:
				    ;Checks which button was pressed 
	BTFSS	PORTB, RB0	     
	call	managerNormalButton	    ;RB0 pressed
	BTFSS	PORTB, RB1	    
	call	managerPriorityButton	    ;RB1 pressed
	BTFSS	PORTB, RB2	    
    	call	cashierNormalButton	    ;RB2 pressed
	BTFSS	PORTB, RB3	
	call	cashierPriorityButton	    ;RB3 pressed

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
	BANKSEL	ANSEL		
	CLRF	ANSEL		    ;digital i/o
	
	BANKSEL PORTB
	CLRF PORTB
	BANKSEL TRISB
	MOVLW b'00001111'	    ;Set RB<3:0> as inputs, RB<7:4> as outputs 
	MOVWF TRISB ;
	
	
	BANKSEL	PORTA		    ;Interruption setup
	MOVLW	b'11001000'	    ;enable global interruptions, pheriperals and PORTA
	MOVWF	INTCON		    
	
loop:	
	NOP
	GOTO	loop	
	END