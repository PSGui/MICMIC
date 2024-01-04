.cseg
.org 0
	jmp inic             

.cseg
.org 0x46
inic:
	ldi r16, 0xff        ; Inicialização do ponteiro da stack (0x10FF)
	out spl, r16
	ldi r16, 0x10
	out sph, r16

	clr r16               ; Limpa r16
	out DDRA, r16         ; Configura o PORT A como entrada para botões
	ser r16               ; Configura todos os bits de r16 para 1
	out DDRC, r16         ; Configura o PORT C como saída para LEDs
	out PORTC, r16        ; Desliga todos os LEDs no início

	ser r21               ; Seta r21 para 255
	ser r22               ; Seta r22 para 255
	ldi r24, 24           ; Carrega 24 para r24
	ldi r18, 0            ; Inicializa r18 como 0
	jmp wait_sw1          ; Salta para a etiqueta wait_sw1

delay:
	push r18              ; Passa para a stack r18
	push r19              ; Passa para a stack r19
	push r20              ; Passa para a stack r20

	mov r20, r17          ; Copia r17 para r20
ciclo0:
	mov r19, r21          ; Copia r21 para r19
ciclo1:
	mov r18, r22          ; Copia r22 para r18
ciclo2:
	dec r18               ; Decrementa r18 e atualiza a flag Z
	brne ciclo2           ; Salta para ciclo2 se Z não estiver configurado

	sbis PINA, 5           ; Pula se o bit 5 de PINA estiver definido
	rjmp stop_delay       ; Salta para stop_delay se o botão estiver pressionado

	dec r19               ; Decrementa r19
	brne ciclo1           ; Salta para ciclo1 se r19 não for zero

	dec r20               ; Decrementa r20
	brne ciclo0           ; Salta para ciclo0 se r20 não for zero

	pop r20               ; Tira da stack r20
	pop r19               ; Tira da stack r19
	pop r18               ; Tira da stack r18
	ret                   

stop_delay:
	ldi r17, 0            ; coloca r17 a 0
	pop r20               ; Tira da stack r20
	pop r19               ; Tira da stack r19
	pop r18               ; Tira da stack r18
	ret                   

wait_sw1:
	ser r16               ; Configura r16 com 255
	out PORTC, r16        ; Desliga todos os LED no PORT C
	sbic PINA, 0           ; Salta se o bit 0 do PIN A estiver definido
	rjmp wait_sw1          ; Salta para wait_sw1 se o botão não estiver pressionado

ciclo_lig_start:
	ldi r17, 164          ; Carrega 164 para r17

ciclo_lig:
	lsl r16               ; Desloca bits de r16 para a esquerda
	brcc ciclo_deslig_start ; Salta para ciclo_deslig_start se o bit de carry estiver vazio

	out PORTC, r16        ; Atualiza os leds com o valor de r16
	call delay            ; Chama a função delay
	cp r17, r18           ; Compara r17 e r18
	breq wait_sw1         ; Salta para wait_sw1 se r17 for igual a r18

	sub r17, r24          ; Subtrai r24 de r17
	rjmp ciclo_lig        ; Salta para ciclo_lig

ciclo_deslig_start:
	ldi r17, 246          ; Carrega 246 para r17
	call delay            ; Chama a função delay
	cp r17, r18           ; Compara r17 e r18
	breq wait_sw1         ; Salta para wait_sw1 se r17 for igual a r18

	ldi r17, 82           ; Carrega 82 para r17
	ldi r16, 0b10000000   ; Configura r16 para 10000000 em binário

ciclo_deslig:
	out PORTC, r16        ; Atualiza os LEDs com o valor de r16
	asr r16               ; Desloca bits de r16 para a direita 
	call delay            ; Chama a função delay
	brcs ciclo_lig_start  ; Salta para ciclo_lig_start se o bit de carry estiver configurado
	cp r17, r18           ; Compara r17 e r18
	breq wait_sw1         ; Salta para wait_sw1 se r17 for igual a r18
	rjmp ciclo_deslig     ; Salta para ciclo_deslig