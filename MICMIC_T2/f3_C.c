#include <avr/interrupt.h>
#include <util/delay.h>
#include <stdio.h>
#include <stdint.h>
#define F_CPU 16000000UL

const uint8_t digitos[]={0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x90, 0xFF};
const uint8_t minus[]={0xFF, 0b10111111};
const uint8_t mode[]={0b10100001, 0b10010010, 0b10001000};

volatile uint8_t flag5ms=0, flagStop=0, flagInv=0;
volatile uint8_t dt=50;
volatile uint8_t flagMode=0; //modo digital(0) e switches(1)
volatile uint8_t x, i = 1;
uint8_t inPut;
uint8_t disp0 = 0, disp1 = 5;
uint8_t sinal = 0;  //0 = positivo(+) ; 1 = negativo(-)
volatile uint8_t valA, valB;
volatile uint16_t valADC = 0;

extern void lerADC(void);

typedef struct USARTRX{
	char receiver_buffer;
	uint8_t status;
	uint8_t receive: 1;
	uint8_t error:	1;
	}USARTRX_st;
	
volatile USARTRX_st rxUSART = {0, 0, 0, 0};
char transmit_buffer[10];

void inic(void){
	DDRA = 0b11000000;      // Porto A (switches e define display)
	PORTA = 0b11000000;    // Escolher display 0
	DDRC = 0b11111111;    // Porto C (display 7 segmentos)
	PORTC = 0b11111111;	 // Apagar display
	DDRB = 0b11100000;
	PORTB = 0b01000000;	//Defenir direção de rotação do motor
	
	/*********************************
		USART1 config
	*********************************/
	UBRR1H = 0;   //Ativa USART1
	UBRR1L = 103;         // 19200 bps depende do U2X1
	UCSR1A = (1<<U2X1);   // dobro da velocidade
	UCSR1B = (1<<RXCIE1)|(1<<RXEN1)|(1<<TXEN1);
	UCSR1C = (1<<UCSZ11)|(1<<UCSZ10);
	
	/*********************************
		TC0 e TC2 config
	*********************************/
	
	OCR0 = 77;				//5ms
	TCCR0 = 0b00001111;	   //
	OCR2 = 128;
	TCCR2 = 0b01100011;		// Modo Phase Correct, prescaler 64 (490Hz)
	TIMSK |= 0b00000010;  //
	
	/*********************************
		ADC config
	*********************************/
	
	ADMUX = 0b00100000; // AREF, direita, canal 0
	ADCSRA = 0b10000100; // ADEN, 1/16 (1mHz)
	
	sei();// SREG |= 0x80
}

/*
uint8_t lerADC(void){
	ADCSRA |= (1<<ADSC);
	while ((ADCSRA & (1<<ADSC)) != 0);
	//valADC = ADCH;
	return ADCH;
}*/

void send_message(char *buffer){ 
	uint8_t i=0;
	while(buffer[i]!='\0'){
		while((UCSR1A & 1<<UDRE1)==0);
		UDR1=buffer[i];
		i++;
	}
}	

//USART1 Receive Interrupt

ISR(USART1_RX_vect){
	rxUSART.status = UCSR1A;
	if(rxUSART.status & ((1<<FE1)|(1<<DOR1)|(1<<UPE1))){
		rxUSART.error = 1;
	}
	rxUSART.receiver_buffer = UDR1;
	rxUSART.receive = 1;
	if(rxUSART.receiver_buffer=='d' || rxUSART.receiver_buffer=='D'){ // MODO DIGITAL (USART)
		flagMode=0;
		rxUSART.receive = 0;
	}
	if(rxUSART.receiver_buffer=='s' || rxUSART.receiver_buffer=='S'){ // MODO SWITCHES
		flagMode=1;
		rxUSART.receive = 0;
	}
	if(rxUSART.receiver_buffer=='a' || rxUSART.receiver_buffer=='A'){ // MODO ANALÓGICO (POTENCIÓMETRO)
		flagMode=2;
		rxUSART.receive = 0;
	}
	if(rxUSART.receiver_buffer=='b' || rxUSART.receiver_buffer=='B'){
		if(sinal==1){
			sprintf(transmit_buffer,"DT: -%d\r\n",dt);
		}
		else{
			sprintf(transmit_buffer,"DT: %d\r\n",dt);
		}
		send_message(transmit_buffer);
		rxUSART.receive = 0;
	}
}
ISR(TIMER0_COMP_vect){
	if(flagInv!=0){
		flagInv--;
		PORTC = digitos[10];
	}
	else{
		disp0 = dt%10;
		disp1 = dt/10;
		if(disp1==10){
			disp1=9;
			disp0=9;
		}
		switch(i){
			case 0:
			PORTA = 0b11000000;
			PORTC = digitos[disp0];
			break;
			case 1:
			PORTA = 0b10000000;
			PORTC = digitos[disp1];
			break;
			case 2:
			PORTA = 0b01000000;
			PORTC = minus[sinal];
			break;
			case 3:
			PORTA = 0b00000000;
			PORTC = mode[flagMode];
			break;
		}
		i++;
		if(i==4)i=0;
	}
}

void Inv(void)
{
	while(flagInv!=0);
	if(sinal == 0){
		sinal = 1;	
		PORTB = 0b00100000;
	}
	else{ 
		sinal=0;
		PORTB = 0b01000000;
		}
	x = (dt*255)/100;
	OCR2 = x;	
}

int main(void){
	uint8_t flag = 0;
	inic();
    while (1) {
		switch(flagMode){
			case 0:
				if(rxUSART.receive==1){
					inPut = rxUSART.receiver_buffer;
					rxUSART.receive=0;
				}
			break;
			case 1:
				inPut = PINA & 0b00110011;
			break;
			case 2:
				inPut = PINA & 0b00110000;
			break;
		}
		switch(inPut){
			case 0b00110010:	//SW1	Incrementa 5%
			case '+':
				_delay_ms(5);
				if(flag == 0){
					flag = 1;
					if(flagStop==1){
						flagStop=0;
						x = (dt*255)/100;
						OCR2 = x;
					}
					else{
						if(dt<100){
							dt=dt+5;
							if(dt>100)dt=100;
							x = (dt*255)/100;
							OCR2 = x;
						}
					}
				}
			break;
			case 0b00110001:	//SW2	Decrementa 5%
			case '-':
				_delay_ms(5);
				if(flag == 0){
					flag = 1;
					if(flagStop==1){
						flagStop=0;
						x = (dt*255)/100;
						OCR2 = x;
					}
					else{
						if(dt>0){
							dt=dt-5;
							if(dt>100)dt=0;
							x = (dt*255)/100;
							OCR2 = x;
						}
					}
				}
			break;
			case 0b00100011:	//SW5	Inverte rotação
			case 0b00100000:	
			case 'i':
			case 'I':
				_delay_ms(5);
				if(flag == 0 && flagStop == 0){
					flag=1;
					flagInv=100;
					OCR2=0;
					Inv();	
				}
			break;
			case 0b00010011:	//SW6	Stop
			case 'p':
			case 'P': 
				_delay_ms(5);
				if(flag==0){
					flag=1;
					flagStop=1;
					OCR2=0;
				}
			break;
			default:
				flag = 0;
			break;
		}
		inPut=0b00000000;
		if(flagMode == 2){
			x=2;
			while(x!=0){
				lerADC();
				valADC=valADC+valA;
				x--;
			}
			valADC = valADC/2;
			dt = (valADC*100)/255;
			if(dt>100)dt=100;
			OCR2= (dt*255)/100;
		}
    }
}
