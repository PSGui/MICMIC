start:
      ldi r16,0b11111111    ; Carrega o registo R16 com o valor binário 11111111
      out DDRC,r16         ; Configura todos os pinos do PORTC como saídas
      out PORTC,r16        ; Define o estado inicial de todos os pinos do PORTC como HIGH (1)

      ldi r16,0b00000000    ; Carrega o registo R16 com o valor binário 00000000
      out DDRA,r16         ; Configura todos os pinos do PORT A como entradas
      ldi r16,0b11111110    ; Carrega o registo R16 com o valor binário 11111110
      out PORTA,r16        ; Define o estado inicial dos pinos do PORT A, exceto o pino 0, como HIGH (1)

ciclo:                        
      in r16,PINA            ; Lê o estado dos pinos de entrada do PORT A e armazena em R16
      cpi r16,0b11111110    ; Compara R16
      breq acende1          ; Se forem iguais, salta para acende1
      cpi r16,0b11111101    ; Compara R16
      breq acende2          ; Se forem iguais, salta para acende2
      cpi r16,0b11111011    ; Compara R16 
      breq acende3          ; Se forem iguais, salta para acende3
      cpi r16,0b11110111    ; Compara R16 
      breq acende4          ; Se forem iguais, salta para acende4
      cpi r16,0b11011111    ; Compara R16 
      breq apaga            ; Se forem iguais, salta para apaga

      rjmp ciclo             ; Se nenhum dos casos acima for verdadeiro, volta para o início do loop

acende1:                      
      ldi r17,0b01111110    ; Carrega o registo R17 
      rjmp outt              ; Salta para outt

acende2:                      
      ldi r17,0b10111101    ; Carrega o registo R17 
      rjmp outt              ; salta para outt

acende3:                      
      ldi r17,0b11011011    ; Carrega o registo R17 
      rjmp outt              ; Salta para outt

acende4:                      
      ldi r17,0b11100111    ; Carrega o registo R17 
      rjmp outt              ; salta para outt

apaga:                        
      ldi r17,0b11111111    ; Carrega o registo R17 

outt:                         
      out PORTC,r17         ; Define o estado dos pinos do PORTC com base no valor de R17
      rjmp ciclo             ; volta ao loop
