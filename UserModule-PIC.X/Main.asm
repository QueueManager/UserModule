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
mQueue	EQU	h'40'		    ;manager queue register
cQueue	EQU	h'50'		    ;cashier queue register
	
	GOTO	setup				    
	ORG	0x0004		    ;Interruption treatment 	
	BTFSC	INTCON, RBIF	   
	call	buttonInterrupt	    ;PORTA interrupt flag bit set
	RETFIE			    ;Return from interrupt treatment 	    

	    cblock  0x20
	    size, count, index, test, largest, parent, child, aux, largestValue, exit, swap1, swap2, countheap,
	    ss, mIndex
	    endc
	    
;IND2POS: Converte o indice para a o endereco de memoria
;Essa macro serve para facilitar o gerenciamento da heap
IND2POS	    macro	i	
	    MOVF	i, W
	    MOVWF	FSR
	    MOVLW	0x50 ; A Heap comeca no endereco 0x50
	    ADDWF	FSR 	    
	    endm
	    
;LEFT: Confere se existe filho a esquerda do no
;Input: indice do no pai
;Output: indice do filho da esquerda ou uma flag exit indicando a ausencia de
; filhos
LEFT	    macro	LIndex
	    BCF		STATUS, C
	    RLF		LIndex
	    MOVF	LIndex, W	
	    SUBWF	size, W
	    BTFSC	STATUS, C 
	    MOVF	LIndex, W
	    BTFSS	STATUS, C 
	    COMF	exit,1
	    endm
	  
;RIGHT: Confere se existe filho a direita do no
;Input: indice do no pai
;Output: indice do filho da direita ou uma flag exit indicando a ausencia de
; filhos	
RIGHT	    macro	RIndex
	    BCF		STATUS, C
	    RLF		RIndex 
	    INCF	RIndex
	    MOVF	RIndex, W	
	    SUBWF	size, W
	    BTFSC	STATUS, C 
	    MOVF	RIndex, W 
	    BTFSS	STATUS, C 
	    COMF	exit,1
	    endm
;Troca dois valores	 
swap:	       
	    IND2POS	countheap
	    MOVF        INDF, W	
	    MOVWF       swap1
	   
	    IND2POS	largest
	    MOVF	INDF, W
	    MOVWF	swap2
	   
	    IND2POS	countheap
	    MOVF        swap2, W		
	    MOVWF	INDF
	   
	    IND2POS	largest
	    MOVF	swap1, W		
	    MOVWF	INDF
	    
	    RETURN
;Executa a Max Heapify sem recurcao, a recurcao é feita no loopHeapify
heapify:    
	    
	    MOVF	countheap, W
	    MOVWF	aux ;recebe o indice atual
    
	    
	    LEFT	aux ; aux recebe o indice do filho da esquerda
	    ;verificar se exit (29) == 1 se for não tem left,  ir para o fim
	    BTFSC	exit,0	   ;se for 0 pula linha
	    GOTO	endheapfy   ;vai para o RETURN da funcao
	    CLRF	exit
	    IND2POS	aux
	    MOVF	INDF, W	
	    MOVWF	child	;child recebe o conteudo do filho da esquerda
	    
	    
	    IND2POS	countheap	;coloca o endereço do pai em FSR
	    MOVF	INDF, W		;parent recebe o conteudo do pai
	    MOVWF	parent
	    
	    ;Comparamos se o filho da esquerda é maior que o pai
	    SUBWF	child, W
	    BTFSS	STATUS, C 
	    GOTO	$ + 3 
	    CALL	largestLeft ;se o filho da esquerda for maior,
	    GOTO	$ + 9	    ;entao largestValue recebe o conteudo de child
	    MOVF	countheap, W
	    MOVWF	largest
	    IND2POS	largest	
	    MOVF	INDF, W		
	    MOVWF	largestValue

	    CLRF	aux	    ;aux é redefinido
	    MOVF	countheap, W
	    MOVWF	aux
	    
	    RIGHT	aux	    ;aux recebe o indice do filho da direita
	    ;verificar se exit (29) == 1 se for não tem left,  ir para o fim
	    BTFSC	exit,0
	    GOTO	endright    ;se nao existir filho da direita, entao
	    CLRF	exit	    ;entao nao compara com o largest quem e o maior
	    IND2POS	aux
	    MOVF	INDF, W	
	    MOVWF	child	    ;child recebe o conteudo do Filho da direita
	    
	    
	    IND2POS	largest	
	    MOVF	INDF, W		
	    MOVWF	largestValue
	    MOVF	largestValue, W
	    SUBWF	child, W
	    BTFSC	STATUS, C
	    CALL	largestRight
endright:	    
	    ;compara se largest e diferente do pai (se houve algum swap)
	    MOVF	largest, W
	    SUBWF	countheap, W
	    BTFSS	STATUS, Z	;se nao houve swap SAIR
	    GOTO	$ + 4
	    MOVLW	0XFF
	    MOVWF	exit
	    GOTO	$ + 2
	    CALL	swap
	  
endheapfy:	    
	    RETURN
	  
largestLeft:
	   MOVF	    aux, W
	   MOVWF    largest
	   
	   IND2POS  largest	
	   MOVF	    INDF, W		
	   MOVWF    largestValue
	   
	   RETURN
	   
largestRight:
	   MOVF	    aux, W
	   MOVWF    largest
	   
	   IND2POS  largest	
	   MOVF	    INDF, W		
	   MOVWF    largestValue
	   
	   RETURN
	   
;Build Max Heap	   
buildMax:	
	    DECF	index
	    MOVF	index, W
	    MOVWF	countheap
	    CALL	heapifyloop
	    CLRF	exit
	    MOVLW	0x01
	    SUBWF	index, W
	    BTFSS	STATUS, Z
	    GOTO	buildMax
	    RETURN
	    
	    
;executa a funcao	    
heapifyloop:    
	    
	    
	    CALL	heapify
	    BTFSC	exit,0	   ;se for 0 pula linha
	    RETURN
	    MOVF	largest, W
	    MOVWF	countheap
	    GOTO	heapifyloop	
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
	INCF	size
	MOVF    size, W
	MOVWF   index

	INCF	iCount
	INCF	mIndex
	
	IND2POS	mIndex
	MOVF	iCount, W		
	MOVWF	INDF
		
	BCF     STATUS, C
	RRF     index
	INCF    index	;incrementa pq o loop do build Max Heap ja
	CALL    buildMax
	;TODO: ajeitar o índice onde comeca a fila
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
	CLRF	PORTB
	BANKSEL	TRISB
	MOVLW	b'00001111'	    ;Set RB<3:0> as inputs, RB<7:4> as outputs 
	MOVWF	TRISB ;
	
	MOVLW	d'0'
	MOVWF	iCount
	
	
	BANKSEL	PORTA		    ;Interruption setup
	MOVLW	b'11001000'	    ;enable global interruptions, pheriperals and PORTA
	MOVWF	INTCON		    
	
loop:	
	NOP
	GOTO	loop	
	END