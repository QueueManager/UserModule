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
	call	buttonInterrupt	    ;PORTA interrupt flag bit set
	BCF	INTCON, RBIF
	RETFIE			    ;Return from interrupt treatment 	    

	    cblock  0x20
	    mCount, pmCount, mlast,
	    pmlast, mnext, pmnext, msize, pmsize
	    endc
	    
	    cblock  0x120
	    cCount, pcCount, clast, pclast, cnext,
	    pcnext, csize, pcsize
	    endc
getFirstM:
	BANKSEL	PORTA		    
	RETURN

getFirstC:
	BANKSEL	WDTCON
	RETURN

getFirstPM:
	BANKSEL	PORTA
	RETURN

getFirstPC:
	BANKSEL	WDTCON
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
	BANKSEL	WDTCON
	MOVLW	0x00
	MOVWF	cCount
	MOVLW	0x129
	MOVWF	clast
	RETURN
	
clearPCqueue:
	BANKSEL	WDTCON
	MOVLW	0x00
	MOVWF	pcCount
	MOVLW	0x14D
	MOVWF	pclast
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
	BANKSEL	PORTA
	RETURN

;(Next 4 functions) Buttons pressed. Functions called locally
managerNormalButton:
	BANKSEL	PORTA
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
	BANKSEL	PORTA
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
	BANKSEL	WDTCON
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
	BANKSEL	WDTCON
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
	MOVLW	b'00001111'	    ;Set RB<3:0> as inputs, RB<7:4> as outputs 
	MOVWF	TRISB ;
	
	
	
	;MOVLW	d'0'
	;MOVWF	iCount
	
	
	BANKSEL	PORTA		    ;Interruption setup
	MOVLW	b'11001000'	    ;enable global interruptions, pheriperals and PORTA
	MOVWF	INTCON
	BANKSEL	IOCB		    ;Interruption setup
	MOVLW	b'00001111'	    ;enable global interruptions, pheriperals and PORTA
	MOVWF	IOCB
	
	
	BANKSEL	PORTA		    
	
	MOVLW	0x29
	MOVWF	mlast
	
	MOVLW	0x55
	MOVWF	pmlast
	
	BANKSEL	WDTCON
	MOVLW	0x129
	MOVWF	clast
	
	MOVLW	0x14D
	MOVWF	pclast
	
	
loop:	
	NOP
	GOTO	loop	
	END