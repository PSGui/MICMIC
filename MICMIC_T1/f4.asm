.include<m128def.inc>

.def tmp = r16            ; Define o registo temporário como r16
.def val = r17            ; Define o registo para armazenar o valor como r17
.def timer = r18          ; Define o registo para o temporizador como r18
.def timerpisca = r19     ; Define o registo para o temporizador do piscar como r19
.def timer5s = r20        ; Define o registo para o temporizador de 5 segundos como r20

.cseg
.org 0x00               ; Início da memória de programa (vetor de reset)
jmp main            ; Salta para a rotina main

.org 0x1E           ; Vetor de interrupção TC0
jmp inttc0          ; Salta para a rotina inttc0 sempre que houver uma interrupção TC0
.org 0x46           ; Começa a escrever no primeiro espaço de memória livre após os vetores de interrupção
setseg: .db 0xc0,0xf9,0xa4,0xb0,0x99,0x92,0x82,0xf8,0x80,0x90
                   
		
		; Configuração dos periféricos
cnfgio:
	ser tmp
	out ddrc,tmp            ; Configura o porto C como saída,display de 7 segmentos
	ldi tmp,0b11000000
	out ddrd,tmp            ; Configura os pinos D7:6 como saídas, seleciona o display
	out porta,tmp           ; Desativa as resistências pull-up internas do porto D para os pinos D5:0
	ldi tmp,0b00001101      ; Configuração do TC0, modo 2 CTC para 2ms de tempo, prescaler 128, sem PWM
	out tccr0,tmp
	ldi tmp,249             ; Valor 249 para o registo de comparação
	out ocr0,tmp
	in tmp,timsk
	ori tmp,0b00000010      ; Ativa a interrupção TC0 quando TCNT0=OCR0 (bit 1)
	out timsk,tmp
	sei                     ; Ativa as interrupções a nível global
	ret

			; Programa principal
main:
	ldi	tmp,low(ramend) ;Configuracao da Stack para ser iniciada no ultimo espaco de memoria de dados
	out	spl,tmp
	ldi tmp,high(ramend)
	out sph,tmp
	ldi zh,high(setseg<<1)
	ldi zl,low(setseg<<1)
	clr tmp
	lpm tmp,z
	call cnfgio
	ser tmp
	out portc,tmp           ; Garante que o display fica desligado no início
	
ciclo:
	ldi val,1               ; Inicializa val com 1
	in tmp,pind
	sbrc tmp,0
	rjmp ciclo              ; Espera até que o botão SW1 seja pressionado
	call settime
	rjmp lancamento


		;Rotina para fazer rodar o dado

rodar:
	brtc rodar
	clt
lancamento:
	call print
	inc val
	cpi val,7
	brne fimlancamento
	ldi val,1
fimlancamento:
	in tmp,pind
	sbrc tmp,3
	rjmp rodar              ; Espera até que o botão SW4 seja pressionado
	ldi timer5s,5
	call settime
	call piscar
	rjmp ciclo
		

		;Rotina para fazwr piscar
piscar:
	ldi timerpisca,25
apaga:
	brtc apaga
	clt
	ser tmp
	out portc,tmp           ; Apaga o display
	dec timerpisca
	brne apaga              ; Verifica se o temporizador de 500ms chegou a zero
	ldi timerpisca,25
acende:
	brtc acende
	clt
	call print             ; Envia o valor fixado para o display
	dec timerpisca
	brne acende            ; Verifica se o temporizador de 500ms chegou a zero
	dec timer5s
	brne piscar
fimpisca: 
	ret


		;Rotina de interrupcao do TC0

inttc0:
	dec timer
	brne fiminttc0
	ldi timer,10
	set
fiminttc0: reti

		;Rotina de escrever no display
print:
	add zl,val
	lpm tmp,z
	out portc,tmp           ; Envia o valor desejado para o display de 7 segmentos
	ldi zl,low(setseg<<1)   ; Reaponta Z para o equivalente ao algarismo zero
	ret


;Rotina de reset ao temporizador TC0
settime:
	cli                     ; Desabilita interrupções a nível global
	clr tmp
	clr	timer
	out	tcnt0,tmp           ; Reinicia o contador do TC0
	clt                     ; Limpa a flag T do registo SREG
	reti                    ; Retorna para o local onde a rotina foi chamada e habilita as interrupções
