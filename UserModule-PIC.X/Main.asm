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

	
	GOTO	setup				    
	ORG	0x0004		    ;Interruption treatment 	
	BTFSC	INTCON, RBIF	   
	call	buttonInterrupt	    ;PORTB interrupt flag bit set
	BCF	INTCON, RBIF
	RETFIE			    ;Return from interrupt treatment 	    

	    cblock  0x20
	    mCount, pmCount, mlast,
	    pmlast, mnext, pmnext, msize, pmsize
	    endc
	    
	    cblock  0xA0
	    cCount, pcCount, clast, pclast, cnext,
	    pcnext, csize, pcsize
	    endc
getFirstM:
	BANKSEL	PORTA		    
	RETURN

getFirstC:
	BANKSEL	ADCON1
	RETURN

getFirstPM:
	BANKSEL	PORTA
	RETURN

getFirstPC:
	BANKSEL	ADCON1
	RETURN

clearMqueue:
	BANKSEL	PORTA
	MOVLW	0x00
	MOVWF	mCount
	MOVLW	0x29
	MOVWF	mlast
	RETURN	
	
clearPMqueue:
	BANKSEL	PORTA
	MOVLW	0x00
	MOVWF	pmCount
	MOVLW	0x55
	MOVWF	pmlast
	RETURN
clearCqueue:
	BANKSEL	ADCON1
	MOVLW	0x00
	MOVWF	cCount
	MOVLW	0xA9
	MOVWF	clast
	RETURN
	
clearPCqueue:
	BANKSEL	ADCON1
	MOVLW	0x00
	MOVWF	pcCount
	MOVLW	0xCC
	MOVWF	pclast
	RETURN
	
buttonInterrupt:
	BANKSEL	PORTB			    ;Checks which button was pressed 
	BTFSC	PORTB, RB4	     
	call	managerNormalButton	    ;RB4 pressed
	BTFSC	PORTB, RB5	    
	call	managerPriorityButton	    ;RB5 pressed
	BTFSC	PORTB, RB6	    
    	call	cashierNormalButton	    ;RB6 pressed
	BTFSC	PORTB, RB7	
	call	cashierPriorityButton	    ;RB7 pressed
    	BANKSEL	PORTA
	RETURN

;(Next 4 functions) Buttons pressed. Functions called locally
managerNormalButton:
	;se a fila esta cheia, entao nao adicione mais ninguem
	MOVLW	0x2B
	SUBWF	msize, W
	BTFSC	STATUS, Z
	RETURN
	
	;testando se esta no final da memoria
	MOVLW	0x2B
	SUBWF	mCount, W
	BTFSC	STATUS, Z
	CALL	clearMqueue
	
	INCF	msize
	INCF	mCount
	
	MOVF	mlast, W
	MOVWF	FSR
	MOVF	mCount, W
	MOVWF	INDF
	INCF	mlast
	RETURN	

managerPriorityButton:
	;se a fila esta cheia, entao nao adicione mais ninguem
	MOVLW	0x2B
	SUBWF	pmsize, W
	BTFSC	STATUS, Z
	RETURN
	
	;testando se esta no final da memoria
	MOVLW	0x2B
	SUBWF	pmCount, W
	BTFSC	STATUS, Z
	CALL	clearPMqueue
	
	INCF	pmsize
	INCF	pmCount
	
	MOVF	pmlast, W
	MOVWF	FSR
	MOVF	pmCount, W
	MOVWF	INDF
	INCF	pmlast
	RETURN	
	
cashierNormalButton:
	BANKSEL	ADCON1
	;se a fila esta cheia, entao nao adicione mais ninguem
	MOVLW	0x23
	SUBWF	csize, W
	BTFSC	STATUS, Z
	RETURN
	
	;testando se esta no final da memoria
	MOVLW	0x23
	SUBWF	cCount, W
	BTFSC	STATUS, Z
	CALL	clearCqueue
	
	INCF	csize
	INCF	cCount
	
	MOVF	clast, W
	MOVWF	FSR
	MOVF	cCount, W
	MOVWF	INDF
	INCF	clast
	RETURN	
	
cashierPriorityButton:
	BANKSEL	ADCON1
	;se a fila esta cheia, entao nao adicione mais ninguem
	MOVLW	0x23
	SUBWF	pcsize, W
	BTFSC	STATUS, Z
	RETURN
	
	;testando se esta no final da memoria
	MOVLW	0x23
	SUBWF	pcCount, W
	BTFSC	STATUS, Z
	CALL	clearPCqueue
	
	INCF	pcsize
	INCF	pcCount
	
	MOVF	pclast, W
	MOVWF	FSR
	MOVF	pcCount, W
	MOVWF	INDF
	INCF	pclast
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
	MOVLW	b'11110000'	    ;Set RB<7:4> as inputs, RB<3:0> as outputs 
	MOVWF	TRISB ;
	
	
	
	;MOVLW	d'0'
	;MOVWF	iCount
	
	
	BANKSEL	PORTA		    ;Interruption setup
	MOVLW	b'11011000'	    ;enable global, pheriperals, INT and PORTB interrupts
	MOVWF	INTCON
	BANKSEL	IOCB		    
	MOVLW	b'11110000'	    ;enable interrupt-on-change for pins 4-7	    
	MOVWF	IOCB
	
	BANKSEL	PIE1
	MOVLW	b'01110000'	    ;setup peripheral interrupt: EUSART transmit and receive
	MOVWF	PIE1
	BANKSEL	RCSTA		    ;enabling EUSART transmitter and receiver
	MOVLW	b'10010000'	    
	MOVWF	RCSTA
	BANKSEL	TXSTA
	MOVLW	b'00100000'	    ;bug: currently firing interrupts for no apparent reason
	MOVWF	TXSTA		    
	
	
	BANKSEL	PORTA		    
	MOVLW	0x29
	MOVWF	mlast
	MOVLW	0x55
	MOVWF	pmlast
	
	BANKSEL	ADCON1
	MOVLW	0xA9
	MOVWF	clast
	
	MOVLW	0xCC
	MOVWF	pclast

txTest:
	;TO BE REMOVED
	BANKSEL	TXREG
	MOVLW	b'00000001'
	MOVWF	TXREG
	
loop:	
	GOTO	loop	
	END