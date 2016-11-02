;;;;;;;;;;; TODO list ;;;;;;;;;;;
; 1. check if config header is correct
; 2. DONE
; 3. add goSleep functionality (to save energy) and wakeUp when button is pressed
; 4. do we need a reset button?
; 5. external communications:
;   5.1 configure output when button is pressed (printer, etc)
;   5.2 create function to receive request for next in queue from other modules
; 6. Testar o finalzinho de todas as filas verificando se nao estar invadindo as outras
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
mQueue	EQU	h'40'		    ;manager queue register
cQueue	EQU	h'50'		    ;cashier queue register
	
	GOTO	setup				    
	ORG	0x0004		    ;Interruption treatment 	
	BTFSC	INTCON, RBIF	   
	call	buttonInterrupt	    ;PORTA interrupt flag bit set
	BCF	INTCON, RBIF
	RETFIE			    ;Return from interrupt treatment 	    

	    cblock  0x20
	    mCount, cCount, mCountPri, cCountPri, mBegin, cBegin,
	    mBeginPri, cBeginPri
	    endc
clearMqueue:
	MOVLW	0x00
	MOVWF	mCount
	MOVLW	0x2A
	MOVWF	mBegin
	RETURN	
	
clearMPqueue:
	MOVLW	0x00
	MOVWF	mCountPri
	MOVLW	0x5A
	MOVWF	mBeginPri
	RETURN
clearCqueue:
	MOVLW	0x00
	MOVWF	cCount
	MOVLW	0x66
	MOVWF	cBegin
	RETURN
	
clearCPqueue:
	MOVLW	0x00
	MOVWF	cCountPri
	MOVLW	0x84
	MOVWF	cBeginPri
	RETURN
	
buttonInterrupt:
				    ;Checks which button was pressed 
	BTFSC	PORTB, RB0	     
	call	managerNormalButton	    ;RB0 pressed
	BTFSC	PORTB, RB1	    
	call	managerPriorityButton	    ;RB1 pressed
	BTFSC	PORTB, RB2	    
    	call	cashierNormalButton	    ;RB2 pressed
	BTFSC	PORTB, RB3	
	call	cashierPriorityButton	    ;RB3 pressed
	
	RETURN

;(Next 4 functions) Buttons pressed. Functions called locally
managerNormalButton:
	
	MOVLW	0x1E
	SUBWF	mCount, W
	BTFSC	STATUS, Z
	CALL	clearMqueue
	
	INCF	mCount
	MOVF	mBegin, W
	MOVWF	FSR
	MOVF	mCount, W
	MOVWF	INDF
	RETURN	

managerPriorityButton:
	MOVLW	0xC
	SUBWF	mCountPri, W
	BTFSC	STATUS, Z
	CALL	clearMPqueue
	
	INCF	mCountPri
	MOVF	mBeginPri, W
	MOVWF	FSR
	MOVF	mCountPri, W
	MOVWF	INDF
	RETURN
	
cashierNormalButton:
	MOVLW	0x1E
	SUBWF	cCount, W
	BTFSC	STATUS, Z
	CALL	clearCqueue
	
	INCF	cCount
	MOVF	cBegin, W
	MOVWF	FSR
	MOVF	cCount, W
	MOVWF	INDF
	RETURN
cashierPriorityButton:
	MOVLW	0xC
	SUBWF	cCountPri, W
	BTFSC	STATUS, Z
	CALL	clearCPqueue
	
	INCF	cCountPri
	MOVF	cBeginPri, W
	MOVWF	FSR
	MOVF	cCountPri, W
	MOVWF	INDF
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
	CLRF	PORTB
	BANKSEL	TRISB
	MOVLW	b'00001111'	    ;Set RB<3:0> as inputs, RB<7:4> as outputs 
	MOVWF	TRISB ;
	
	
	
	;MOVLW	d'0'
	;MOVWF	iCount
	
	
	BANKSEL	PORTA		    ;Interruption setup
	MOVLW	b'11001000'	    ;enable global interruptions, pheriperals and PORTA
	MOVWF	INTCON
	BANKSEL	IOCB
	MOVLW	b'00001111'	    ;enable global interruptions, pheriperals and PORTA
	MOVWF	IOCB
	
	
	BANKSEL	PORTA		    ;Interruption setup
	
	MOVLW	0x2A
	MOVWF	mBegin
	
	MOVLW	0x5A
	MOVWF	cBegin
	
	MOVLW	0x66
	MOVWF	mBeginPri
	
	MOVLW	0x84
	MOVWF	cBeginPri
	
	
loop:	
	NOP
	;CALL	managerNormalButton
	
	GOTO	loop	
	END