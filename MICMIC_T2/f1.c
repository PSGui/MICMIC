/* 

 *TC0 CTC 5ms 

 * TC2 PWM, sa�da em OC2 (PB7), freq 500hz

 * sentido de rota��o em Dir0 (PB5) e Dir1 (PB6)

 * SW1 incrementa, SW2 decrementa, ambos em 5 unidades

 * SW5 inverte o sentido (motor parado por 500ms), SW6 p�ra motor

 */

#include <avr/interrupt.h>

#include <util/delay.h>

#define F_CPU 16000000UL

const unsigned char digitos[]={0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x90, 0xFF};

const unsigned char minus[]={0xFF, 0b10111111};

unsigned char i = 1;



volatile unsigned char flag5ms=0;

volatile unsigned char flagStop=0;

volatile unsigned char flagInv=0;

volatile unsigned char dt=50;

unsigned char x;

unsigned char switches;

unsigned char disp0 = 0;

unsigned char disp1 = 5;

unsigned char sinal = 0;



void inic(void){

	DDRA = 0b11000000;      // Porto A (switches e define display)

	PORTA = 0b11000000;    // Escolher display 0

	DDRC = 0b11111111;    // Porto C (display 7 segmentos)

	PORTC = 0b11111111;	 // Apagar display

	DDRB = 0b11100000;

	PORTB = 0b01000000;	//Defenir dire��o de rota��o do motor

	

	OCR0 = 77;				//5ms

	TCCR0 = 0b00001111;	   //

	

	OCR2 = 128;

	TCCR2 = 0b01100011;		// Modo Phase Correct, prescaler 64 (490Hz)

	

	TIMSK |= 0b00000010;  //

	sei();// SREG |= 0x80

}



ISR(TIMER0_COMP_vect){

	//flag5ms=1;

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

		}

		i++;

		if(i==3)i=0;

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



int main(void)

{

	unsigned char flag = 0;

	inic();

    while (1) {

		switches = PINA & 0b00110011;

		switch(switches){

			case 0b00110010:	//SW1	Incrementa 5%

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

							x = (dt*255)/100;

							OCR2 = x;

						}

					}

				}

				

			break;

			case 0b00110001:	//SW2	Decrementa 5%

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

							x = (dt*255)/100;

							OCR2 = x;

						}

					}

				}

				

			break;

			case 0b00100011:	//SW5	Inverte rota��o

				_delay_ms(5);

				if(flag == 0 && flagStop == 0){

					flag=1;

					flagInv=100;

					OCR2=0;

					Inv();	

				}

			break;

			case 0b00010011:	//SW6	Stop

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

		/*if (flag5ms==1){

			flag5ms=0;

			Display();

			}*/

    }

}