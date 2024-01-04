.cseg              
.org 0             

    jmp inic       
.cseg              
.org 0x46          

inic:              
    ldi r16, 0xff   ; Carrega o valor 0xFF em r16
    out spl, r16    ; Escreve o valor de r16 no registo SPL
    ldi r16, 0x10   ; Carrega o valor 0x10 em r16
    out sph, r16    ; Escreve o valor de r16 no registo SPH

    ser r16         ; Coloca todos os bits de r16 para 1
    out DDRC, r16   ; Configura todos os pinos de PORT C como saída
    out DDRA, r16   ; Configura todos os pinos de PORT A como saída
    out PORTC, r16  ; Define o estado inicial de todos os pinos de PORT C como HIGH
    out PORTA, r16  ; Define o estado inicial de todos os pinos de PORT A como HIGH

    ldi r16, 0b11000000 ; Carrega o valor binário 11000000 em r16
    out DDRD, r16   ; Configura os pinos 7 e 6 de PORTD como saída
    out PORTD, r16  ; Define o estado inicial dos pinos 7 e 6 de PORT D como HIGH

    ldi r16, 0x90   ; Carrega o valor 144 em r16
    out PORTC, r16  ; Define o estado inicial do pino 6 de PORT C como HIGH

    ldi r16, 9      ; Carrega o valor 9 em r16
    ;sbi PORTA, 6   ; Define o pino 6 de PORTA como HIGH 
    jmp pessoa_empty ; Salto para o rótulo 'pessoa_empty'

delay:             ; Sub-rotina para criar um atraso
    push r18       ; Salva o registo r18 na stack
    push r19       ; Salva o registo r19 na stack
    push r20       ; Salva o registo r20 na stack

ciclo0:           
    ldi r19, 255   ; Carrega 255 em r19 

ciclo1:            
    ldi r18, 20    ; Carrega 20 em r18 

ciclo2:           
    dec r18        ; Decrementa r18
    brne ciclo2    ; Se r18 não for zero, repete o loop
    dec r19        ; Decrementa r19
    brne ciclo1    ; Se r19 não for zero, repete o  loop 
    dec r20        ; Decrementa r20
    brne ciclo0    ; Se r20 não for zero, repete o loop 
    pop r20        ; Retira o registo r20 da stack
    pop r19        ; Retira o registo r19 da stack
    pop r18        ; Retira o registo r18 da stack
    ret          

dis_count:         ; Sub-rotina para exibir o número no display de sete segmentos
	cpi r16, 0     ; Compara r16 com 0
	breq dis_0     ; Se r16 for 0, salta para o rótulo 'dis_0'
	cpi r16, 1     ; Compara r16 com 1
	breq dis_1     ; Se r16 for 1, salta para o rótulo 'dis_1'
	cpi r16, 2				
	breq dis_2				
	cpi r16, 3			
	breq dis_3			
	cpi r16, 4			
	breq dis_4			
	cpi r16, 5			
	breq dis_5			
	cpi r16, 6			
	breq dis_6			
	cpi r16, 7			
	breq dis_7			
	cpi r16, 8		
	breq dis_8			
	cpi r16, 9			
	breq dis_9	


dis_0:             
	ldi r17, 0xC0  ; Carrega 0xC0 em r17 (exibe 0)
	out PORTC, r17 ; Escreve o valor de r17 no registo PORTC
	rjmp exit_dis  ; Salto para o rótulo 'exit_dis'

dis_1:					
	ldi r17,0xF9		
	out PORTC,r17		
	rjmp exit_dis		
dis_2:					
	ldi r17,0xA4		
	out PORTC,r17		
	rjmp exit_dis		
dis_3:					
	ldi r17,0xB0
	out PORTC,r17
	rjmp exit_dis
dis_4:
	ldi r17,0x99
	out PORTC,r17
	rjmp exit_dis
dis_5:
	ldi r17,0x92
	out PORTC,r17
	rjmp exit_dis
dis_6:
	ldi r17,0x82
	out PORTC,r17
	rjmp exit_dis
dis_7:
	ldi r17,0xF8
	out PORTC,r17
	rjmp exit_dis
dis_8:
	ldi r17,0x80
	out PORTC,r17
	rjmp exit_dis
dis_9:
	ldi r17,0x90
	out PORTC,r17


exit_dis:          
    ret          

ciclo_start:       
    sbis PIND, 0   ; Testa o pino 0 se está no estado 1
    rjmp ciclo_in   ; Se sim, salta para a sub-rotina 
    sbis PIND, 5   ; Testa se o pino PD5 está no estado 1
    rjmp ciclo_out  ; Se sim, salta para a sub-rotina 
    rjmp ciclo_start; Se não, reinicia o ciclo

ciclo_in:         
    call delay     ; chama a rotina delay 
    sbic PIND, 0   ; Testa se o pino 0 está no estado 0
    rjmp ciclo_start

ciclo_in2:         
    sbic PIND, 5   
    rjmp ciclo_in2  
    call delay     
    sbic PIND, 5   
    rjmp ciclo_start

ciclo_in0:        
    sbis PIND, 0   
    rjmp ciclo_in0 
    sbis PIND, 5   
    rjmp ciclo_in0 

pessoa_in:         
    dec r16        ; Decrementa o contador de pessoas
    call dis_count ; Chama a sub-rotina  para exibir o número no display 
    cpi r16, 0     ; Compara r16 com 0
    breq pessoa_full; Se r16 for 0, vai para pessoa_full
    rjmp ciclo_start; Se não, reinicia o ciclo

ciclo_out:        
    call delay     
    sbic PIND, 5   
    rjmp ciclo_start

ciclo_out2:        
    sbic PIND, 0   
    rjmp ciclo_out2
    call delay     
    sbic PIND, 0   
    rjmp ciclo_start

ciclo_out0:        
    sbis PIND, 0   
    rjmp ciclo_out0
    sbis PIND, 5   
    rjmp ciclo_out0

pessoa_out:        
    inc r16        ; Incrementa o contador de pessoas
    call dis_count ; Chama a sub-rotina para exibir o número no display 
    cpi r16, 9     ; Compara r16 com 9
    breq pessoa_empty; Se r16 for 9, vai para pessoa_empty
    rjmp ciclo_start; Se não, reinicia o ciclo

pessoa_full:       
    cbi PORTA, 7   ; Limpa o pino 7 de PORTA para indicar cheio
    sbic PIND, 5   
    rjmp pessoa_full 
    call delay     
    sbic PIND, 5   
    rjmp pessoa_full

pessoa_full2:      
    sbic PIND, 0 
    rjmp pessoa_full2
    call delay     
    sbic PIND, 0   
    rjmp pessoa_full

pessoa_full0:     
    sbis PIND, 5   
    rjmp pessoa_full0
    sbis PIND, 0   
    rjmp pessoa_full0
    sbi PORTA, 7   ; Define o pino 7 de PORTA como alto para indicar  cheio
    rjmp pessoa_out

pessoa_empty:      
    sbi PORTA, 6   ; Define o pino 6 de PORTA como alto para indicar vazio
    sbic PIND, 0  
    rjmp pessoa_empty
    call delay     
    sbic PIND, 0   
    rjmp pessoa_empty

pessoa_empty2:     
    sbic PIND, 5   
    rjmp pessoa_empty2
    call delay     
    sbic PIND, 5   
    rjmp pessoa_empty

pessoa_empty0:     
    sbis PIND, 0  
    rjmp pessoa_empty0
    sbis PIND, 5  
    rjmp pessoa_empty0
    cbi PORTA, 6   ; Define o pino 6 de PORTA como baixo para indicar vazio
    rjmp pessoa_in  
