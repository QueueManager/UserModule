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
	BANKSEL	INTCON
	BTFSC	INTCON, RBIF	   
	call	buttonInterrupt	    ;PORTB interrupt flag bit set
	BCF	INTCON, RBIF
	BANKSEL	PIR1
	BTFSC	PIR1, TXIF
	call	transmitInterrupt
	RETFIE			    ;Return from interrupt treatment 	    

	    cblock  0x20
	    mCount, pmCount, mlast,
	    pmlast, mnext, pmnext, msize, pmsize
	    endc
	    
	    cblock  0xA0
	    cCount, pcCount, clast, pclast, cnext,
	    pcnext, csize, pcsize
	    endc

getNextM:
	call	getFirstPM  ;TODO delete and implement next line
	;TODO implement logic: when to call priority and when to call regular?
	RETURN
	
getNextC:
	call	getFirstPC  ;TODO delete and implement next line
	;TODO implement logic: when to call priority and when to call regular?
	RETURN
	
getFirstM:
	MOVF	mnext, W
	MOVWF	TXREG		     ; Raises interrupt flag - calls transmit interrupt routine
				     ; TODO change format to comply with project API
	
	MOVF	mnext, W
	MOVWF	FSR
	MOVLW	0x00
	MOVWF	INDF
	
	INCF	mnext
	DECF	msize
	
	RETURN
	
getFirstPM:
	MOVF	pmnext, W
	MOVWF	TXREG		    ; Raises interrupt flag - calls transmit interrupt routine
				    ; TODO change format to comply with project API
	MOVF	pmnext, W
	MOVWF	FSR
	MOVLW	0x00
	MOVWF	INDF
	
	INCF	pmnext
	DECF	pmsize
	
	RETURN
	
getFirstC:
	MOVF	cnext, W
	MOVWF	TXREG		     ; Raises interrupt flag - calls transmit interrupt routine
				     ; TODO change format to comply with project API
	MOVF	cnext, W
	MOVWF	FSR
	MOVLW	0x00
	MOVWF	INDF
	
	INCF	cnext
	DECF	csize
	
	RETURN

getFirstPC:
	MOVF	pcnext, W
	MOVWF	TXREG		    ; Raises interrupt flag - calls transmit interrupt routine
				    ; TODO change format to comply with project API
	MOVF	pcnext, W
	MOVWF	FSR
	MOVLW	0x00
	MOVWF	INDF
	
	INCF	pcnext
	DECF	pcsize
	
	RETURN
	
resetMcount:
	MOVLW   0x00
	MOVWF	mCount
	RETURN
	
resetPMcount:
	MOVLW   0x3E8
	MOVWF	pmCount
	RETURN
	
resetCcount:
	MOVLW   0x7D0
	MOVWF	cCount
	RETURN
	
resetPCcount:
	MOVLW   0xBB8
	MOVWF	pcCount
	RETURN
	
clearMqueue:
	MOVLW	0x29
	MOVWF	mlast
	RETURN	
	
clearPMqueue:
	MOVLW	0x55
	MOVWF	pmlast
	RETURN
clearCqueue:
	MOVLW	0xA9
	MOVWF	clast
	RETURN
	
clearPCqueue:
	MOVLW	0xCC
	MOVWF	pclast
	RETURN

transmitInterrupt:
	BANKSEL	RCREG
	MOVLW	b'00000001'	
	SUBWF	RCREG,0		; TODO check if incoming data is in this register 
	BTFSC	STATUS, Z	; if subtraction equals zero, guiche '1' wants a client 
	call	getNextC
	MOVLW	b'00000010'
	SUBWF	RCREG,0		; TODO check if incoming data is in this register 
	BTFSC	STATUS, Z	; if subtraction equals zero, now guiche '2' wants a client 
	call	getNextM	
	RETURN
	
buttonInterrupt:
	BANKSEL	PORTB			    ;Checks which button was pressed 
	BTFSC	PORTB, RB1	     
	call	managerNormalButton	    ;RB1 pressed
	BTFSC	PORTB, RB2	    
	call	managerPriorityButton	    ;RB2 pressed
	BTFSC	PORTB, RB3	    
    	call	cashierNormalButton	    ;RB3 pressed
	BTFSC	PORTB, RB4	
	call	cashierPriorityButton	    ;RB4 pressed
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
	MOVLW	0x54
	SUBWF	mlast, W
	BTFSC	STATUS, Z
	CALL	clearMqueue
	
	
	;reset if counter is equals to 999
	MOVLW	0x3E7
	SUBWF	mCount, W
	BTFSC	STATUS, Z
	CALL	resetMcount
	
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
	MOVLW	0x7F
	SUBWF	pmlast, W
	BTFSC	STATUS, Z
	CALL	clearPMqueue
	
	;reset if counter is equals to 1999
	MOVLW	0x7CF
	SUBWF	pmCount, W
	BTFSC	STATUS, Z
	CALL	resetPMcount
	
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
	MOVLW	0xCB
	SUBWF	clast, W
	BTFSC	STATUS, Z
	CALL	clearCqueue
	
	;reset if counter is equals to 1999
	MOVLW	0xBB7
	SUBWF	cCount, W
	BTFSC	STATUS, Z
	CALL	resetMcount
	
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
	MOVLW	0xEF
	SUBWF	pclast, W
	BTFSC	STATUS, Z
	CALL	clearPCqueue
	
	;reset if counter is equals to 1999
	MOVLW	0x79F
	SUBWF	pcCount, W
	BTFSC	STATUS, Z
	CALL	resetMcount
	
	INCF	pcsize
	INCF	pcCount
	
	MOVF	pclast, W
	MOVWF	FSR
	MOVF	pcCount, W
	MOVWF	INDF
	INCF	pclast
	RETURN
	
transmitData:
	;TODO fetch data from Wreg, save to reg X
	BANKSEL	TXSTA
	MOVLW	b'00100100'	    ;enable EUSART transmitter circuitry, set EUSART for async op
	MOVWF	TXSTA	
	BANKSEL	RCSTA		    ;set TX/CK pin as output
	MOVLW	b'10000000'	    
	MOVWF	RCSTA
	BANKSEL	PIE1
	BSF	PIE1, TXIE	    ;EUSART transmit interrupt enable
	RETURN

receiveData:
	
	RETURN
	
setup:
	;configure ports
	BANKSEL	PORTA
	CLRF	PORTA
	BANKSEL	ANSEL		
	CLRF	ANSEL		    ;digital i/o
	BANKSEL	ANSELH
	CLRF	ANSELH
	
	BANKSEL PORTB
	CLRF	PORTB
	BANKSEL	TRISB
	MOVLW	b'00011111'	    ;Set RB<4:1> as inputs, RB<7:5> as outputs 
	MOVWF	TRISB ;
	
		
	
	;MOVLW	d'0'
	;MOVWF	iCount
	
	
	BANKSEL	PORTA		    ;Interruption setup
	MOVLW	b'11001000'	    ;enable global interruptions, pheriperals
	MOVWF	INTCON
	BANKSEL	IOCB		    ;setup
	MOVLW	b'11111111'	    ;enable interrupt-on-change for all RB pins	    
	MOVWF	IOCB
	BANKSEL	PIE1
	MOVLW	b'01100000'	    ;setup peripheral interrupt: 
	MOVWF	PIE1
	
	BANKSEL	TXSTA
	BCF	TXSTA, SYNC	    ;async op
	BSF	TXSTA, BRGH	    ;baud rate
	BANKSEL	RCSTA		    ;Setup receiver
	MOVLW	b'10010000'
	MOVWF	RCSTA
	BANKSEL	BAUDCTL
	BSF	BAUDCTL, BRG16
	MOVWF	BAUDCTL
	;TODO setup SPBRGH, SPBRG
	;HOW TO?!
	;TODO read RCSTA to get error flags
	
	BANKSEL	PORTA		    
	
	MOVLW	0x29
	MOVWF	mlast
	
	MOVLW	0x55
	MOVWF	pmlast
	
	MOVLW	0x00
	MOVWF	msize
	
	MOVLW	0x00
	MOVWF	pmsize
	
	MOVLW	0x29
	MOVWF	mnext
	
	MOVLW	0x29
	MOVWF	pmnext
	
	MOVLW	0x00
	MOVWF	mCount
	
	MOVLW	0x3E8
	MOVWF	pmCount
	
	BANKSEL	ADCON1
	
	MOVLW	0xA9
	MOVWF	clast
	
	MOVLW	0xCC
	MOVWF	pclast
	
	MOVLW	0x00
	MOVWF	csize
	
	MOVLW	0x00
	MOVWF	pcsize
	
	MOVLW	0x29
	MOVWF	cnext
	
	MOVLW	0x29
	MOVWF	pcnext
	
	MOVLW	0x7D0
	MOVWF	cCount
	
	MOVLW	0xBB8
	MOVWF	pcCount
	
	
loop:	
	NOP
	;call	transmitData
	MOVLW	b'01010100' ;test data for receiver testing
	MOVWF	RCREG
	;TODO error - not generating interrption
	;Maybe it has to come from the RSR reg
	;How to test it?
    	GOTO	loop	
	END