;TODO list
; 1. check if config header is correct
; 2. change buttons to pins RA
    
; PIC16F628A Configuration Bit Settings
; ASM source line config statements
#include "P16F688.inc"
; CONFIG
; __config 0xFF19
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF
 
	ORG	0x0000
iCount	EQU	d'241'
goSleep	EQU	0x0
	
	GOTO	setup				    
	ORG	0x0004		    ;TRATAMENTO DAS ROTINAS DE INTERRUPÇÃO (em todos os PICs, localiza-se no endereço 0x0004)
	
	BTFSC	INTCON, RBIF
	call	buttonInterrupt
	BTFSC	INTCON, T0IF
	call	timerOut

	
	RETFIE			    ;Retorna da rotina de interrupção	    

timerOut:
	INCF	PORTB	
	BCF	INTCON, T0IF	    ;Zerando o flag de overflow do timer 
	BCF	INTCON, T0IE	    ;Desabilitando overflow interrupt do timer (por que??)
	BSF	goSleep,0	    ;Setar bit dormir para entrar no sleep do loop principal
	RETURN
	
buttonInterrupt:
				    ;CHECAR QUAL BOTÃO FOI APERTADO
	BTFSS	PORTB, RB6	    ; Quando for o RB6
	call	buttonrb6
	BTFSS	PORTB, RB7	    ; Quando for o RB7
	call	buttonrb7
	BCF	goSleep,0	    ;Limpar bit dormir para não dormir no loop central

buttonrb6:
	BTFSC	INTCON, T0IE	    ;Se interrupt timer tiver desativada, continuar nesta funcao
	RETURN
	MOVLW	iCount		    ;Move iCount para W
	MOVWF	TMR0		    ;Pega o iCount do W para setar como tempo inicial do timer
	BSF	INTCON, T0IE
	RETURN
	
buttonrb7:
	MOVLW	0x00
	MOVWF	PORTB		    ;resetar portb
	RETURN
	
setup:
	BANKSEL	TRISA		    ;Inicializando PortA
	MOVLW	0x00		    
	MOVWF	TRISA		    ;Seta todos os pins para saída
	
	BANKSEL PORTA
	CLRF	PORTA		    ; RA6 e RA7 podem operar como saída, caso o oscilador esteja no modo _FOSC_INTOSCIO

	MOVLW	0x07
	MOVWF	CMCON		    ; Desabilitando Comparadores para não conflitar com pins RB
	
	BANKSEL	PORTB	
	MOVLW	b'11000000'	    ; RA7 e RA6 como entrada, demais como saída
	MOVWF	TRISB
		
	BANKSEL	OPTION_REG	    ;CONFIGURACOES OPTION REG
	MOVLW	b'00010011'	    ;Configurando pull-up, rising edge, clock interno, high-to-low, pre-escalar 1:16
	MOVWF	OPTION_REG	    ;Seta
	
	BANKSEL	PCON
	BCF	PCON, OSCF	    ;Configura oscilador para 48KHz
	
	BANKSEL	PORTA		   ;CONFIGURAR INTERRUPCOES
	MOVLW	b'10001000'	    ;habilitar interrupcoes globais, timer e de botão; desabilita todo o resto
	MOVWF	INTCON		    ;Seta
	
loop:	
	BTFSC	goSleep, 0
	SLEEP
	
	GOTO	loop	
	

	END